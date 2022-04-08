
import Foundation
import WalletConnectUtils
import WalletConnectKMS
import Combine

final class ControllerSessionStateMachine: SessionStateMachineValidating {
    
    var onMethodsUpdate: ((String, Set<String>)->())?
    var onEventsUpdate: ((String, Set<String>)->())?

    private let sequencesStore: SessionSequenceStorage
    private let relayer: WalletConnectRelaying
    private let kms: KeyManagementServiceProtocol
    private var publishers = [AnyCancellable]()
    private let logger: ConsoleLogging

    init(relay: WalletConnectRelaying,
         kms: KeyManagementServiceProtocol,
         sequencesStore: SessionSequenceStorage,
         logger: ConsoleLogging) {
        self.relayer = relay
        self.kms = kms
        self.sequencesStore = sequencesStore
        self.logger = logger
        relayer.responsePublisher.sink { [unowned self] response in
            handleResponse(response)
        }.store(in: &publishers)
    }
    
    func updateMethods(topic: String, methods: Set<String>) throws {
        var session = try getSession(for: topic)
        try validateControlledAcknowledged(session)
        try validateMethods(methods)
        logger.debug("Controller will update methods")
        session.updateMethods(methods)
        sequencesStore.setSequence(session)
        relayer.request(.wcSessionUpdateMethods(SessionType.UpdateMethodsParams(methods: methods)), onTopic: topic)
    }
    
    func updateEvents(topic: String, events: Set<String>) throws {
        var session = try getSession(for: topic)
        try validateControlledAcknowledged(session)
        try validateEvents(events)
        logger.debug("Controller will update events")
        session.updateEvents(events)
        sequencesStore.setSequence(session)
        relayer.request(.wcSessionUpdateEvents(SessionType.UpdateEventsParams(events: events)), onTopic: topic)
    }
    
    // MARK: - Handle Response
    
    private func handleResponse(_ response: WCResponse) {
        switch response.requestParams {
        case .sessionUpdateMethods:
            handleUpdateMethodsResponse(topic: response.topic, result: response.result)
        case .sessionUpdateEvents:
            handleUpdateEventsResponse(topic: response.topic, result: response.result)
        default:
            break
        }
    }
    
    private func handleUpdateMethodsResponse(topic: String, result: JsonRpcResult) {
        guard let session = sequencesStore.getSequence(forTopic: topic) else {
            return
        }
        switch result {
        case .response:
            //TODO - state sync
            onMethodsUpdate?(session.topic, session.methods)
        case .error:
            //TODO - state sync
            logger.error("Peer failed to update methods.")
        }
    }
    
    private func handleUpdateEventsResponse(topic: String, result: JsonRpcResult) {
        guard let session = sequencesStore.getSequence(forTopic: topic) else {
            return
        }
        switch result {
        case .response:
            //TODO - state sync
            onEventsUpdate?(session.topic, session.events)
        case .error:
            //TODO - state sync
            logger.error("Peer failed to update events.")
        }
    }
    
    // MARK: - Private
    private func getSession(for topic: String) throws -> SessionSequence {
        if let session = sequencesStore.getSequence(forTopic: topic) {
            return session
        } else {
            throw WalletConnectError.noSessionMatchingTopic(topic)
        }
    }
    
    private func validateControlledAcknowledged(_ session: SessionSequence) throws {
        guard session.acknowledged else {
            throw WalletConnectError.sessionNotAcknowledged(session.topic)
        }
        guard session.selfIsController else {
            throw WalletConnectError.unauthorizedNonControllerCall
        }
    }
}