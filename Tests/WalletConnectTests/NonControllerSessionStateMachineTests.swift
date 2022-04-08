import XCTest
import WalletConnectUtils
@testable import TestingUtils
import WalletConnectKMS
@testable import WalletConnect


class NonControllerSessionStateMachineTests: XCTestCase {
    var sut: NonControllerSessionStateMachine!
    var relayMock: MockedWCRelay!
    var storageMock: SessionSequenceStorageMock!
    var cryptoMock: KeyManagementServiceMock!
    
    override func setUp() {
        relayMock = MockedWCRelay()
        storageMock = SessionSequenceStorageMock()
        cryptoMock = KeyManagementServiceMock()
        sut = NonControllerSessionStateMachine(relay: relayMock, kms: cryptoMock, sequencesStore: storageMock, logger: ConsoleLoggerMock())
    }
    
    override func tearDown() {
        relayMock = nil
        storageMock = nil
        cryptoMock = nil
        sut = nil
    }
    
    // MARK: - Update Methods
    
    func testUpdateMethodsPeerSuccess() {
        var didCallbackUpdatMethods = false
        let session = SessionSequence.stub(isSelfController: false)
        storageMock.setSequence(session)
        sut.onMethodsUpdate = { topic, _ in
            didCallbackUpdatMethods = true
            XCTAssertEqual(topic, session.topic)
        }
        relayMock.wcRequestPublisherSubject.send(WCRequestSubscriptionPayload.stubUpdateMethods(topic: session.topic))
        XCTAssertTrue(didCallbackUpdatMethods)
        XCTAssertTrue(relayMock.didRespondSuccess)
    }
    
    func testUpdateMethodsPeerErrorInvalidType() {
        let invalidMethods: Set<String> = [""]
        let session = SessionSequence.stub(isSelfController: false)
        storageMock.setSequence(session)
        relayMock.wcRequestPublisherSubject.send(WCRequestSubscriptionPayload.stubUpdateMethods(topic: session.topic, methods: invalidMethods))
        XCTAssertEqual(relayMock.lastErrorCode, 1004)
    }

    func testUpdateMethodPeerErrorSessionNotFound() {
        relayMock.wcRequestPublisherSubject.send(WCRequestSubscriptionPayload.stubUpdateMethods(topic: ""))
        XCTAssertFalse(relayMock.didRespondSuccess)
        XCTAssertEqual(relayMock.lastErrorCode, 1301)
    }

    func testUpdateMethodPeerErrorUnauthorized() {
        let session = SessionSequence.stub(isSelfController: true) // Peer is not a controller
        storageMock.setSequence(session)
        relayMock.wcRequestPublisherSubject.send(WCRequestSubscriptionPayload.stubUpdateMethods(topic: session.topic))
        XCTAssertFalse(relayMock.didRespondSuccess)
        XCTAssertEqual(relayMock.lastErrorCode, 3004)
    }
    
    // MARK: - Update Events

    func testUpdateEventsPeerSuccess() {
        var didCallbackUpdateEvents = false
        let session = SessionSequence.stub(isSelfController: false)
        storageMock.setSequence(session)
        sut.onEventsUpdate = { topic, _ in
            didCallbackUpdateEvents = true
            XCTAssertEqual(topic, session.topic)
        }
        relayMock.wcRequestPublisherSubject.send(WCRequestSubscriptionPayload.stubUpdateEvents(topic: session.topic))
        XCTAssertTrue(didCallbackUpdateEvents)
        XCTAssertTrue(relayMock.didRespondSuccess)
    }
    
    
    func testUpdateEventsPeerErrorUnauthorized() {
        let session = SessionSequence.stub(isSelfController: true) // Peer is not a controller
        storageMock.setSequence(session)
        relayMock.wcRequestPublisherSubject.send(WCRequestSubscriptionPayload.stubUpdateEvents(topic: session.topic))
        XCTAssertFalse(relayMock.didRespondSuccess)
        XCTAssertEqual(relayMock.lastErrorCode, 3005)
    }
}