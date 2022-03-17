import Foundation

public struct AnyCodable {
    
    private let value: Any
    
    private var genericEncoding: ((Encoder) throws -> Void)?
    
    private init(_ value: Any) {
        self.value = value
    }

    public init<C>(_ codable: C) where C: Codable {
        self.value = codable
        genericEncoding = { encoder in
            try codable.encode(to: encoder)
        }
    }
    
    public func get<T: Codable>(_ type: T.Type) throws -> T {
        let valueData = try JSONSerialization.data(withJSONObject: value, options: [.fragmentsAllowed])
        return try JSONDecoder().decode(type, from: valueData)
    }
}

extension AnyCodable: Decodable, Encodable {
    
    struct CodingKeys: CodingKey {
        
        let stringValue: String
        let intValue: Int?
        
        init?(intValue: Int) {
            self.stringValue = String(intValue)
            self.intValue = intValue
        }
        
        init?(stringValue: String) {
            self.stringValue = stringValue
            self.intValue = Int(stringValue)
        }
    }
    
    public init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            var result = [String: Any]()
            try container.allKeys.forEach { (key) throws in
                result[key.stringValue] = try container.decode(AnyCodable.self, forKey: key).value
            }
            value = result
        }
        else if var container = try? decoder.unkeyedContainer() {
            var result = [Any]()
            while !container.isAtEnd {
                result.append(try container.decode(AnyCodable.self).value)
            }
            value = result
        }
        else if let container = try? decoder.singleValueContainer() {
            if let intVal = try? container.decode(Int.self) {
                value = intVal
            } else if let doubleVal = try? container.decode(Double.self) {
                value = doubleVal
            } else if let boolVal = try? container.decode(Bool.self) {
                value = boolVal
            } else if let stringVal = try? container.decode(String.self) {
                value = stringVal
            } else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "the container contains nothing serializable")
            }
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Could not serialize"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        if let encoding = genericEncoding {
            try encoding(encoder)
        } else if let array = value as? [Any] {
            var container = encoder.unkeyedContainer()
            for value in array {
                let decodable = AnyCodable(value)
                try container.encode(decodable)
            }
        } else if let dictionary = value as? [String: Any] {
            var container = encoder.container(keyedBy: CodingKeys.self)
            for (key, value) in dictionary {
                let codingKey = CodingKeys(stringValue: key)!
                let decodable = AnyCodable(value)
                try container.encode(decodable, forKey: codingKey)
            }
        } else {
            var container = encoder.singleValueContainer()
            if let intVal = value as? Int {
                try container.encode(intVal)
            } else if let doubleVal = value as? Double {
                try container.encode(doubleVal)
            } else if let boolVal = value as? Bool {
                try container.encode(boolVal)
            } else if let stringVal = value as? String {
                try container.encode(stringVal)
            } else {
                throw EncodingError.invalidValue(value, EncodingError.Context.init(codingPath: [], debugDescription: "The value is not encodable"))
            }
        }
    }
}

//extension AnyCodable: Equatable {
//    public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
//        if let lString = try? lhs.get(String.self),
//           let rString = try? rhs.get(String.self),
//           lString == rString {
//            return true
//        }
//        fatalError("Not implemented")
//    }
//}






final class MessageDispatcher: NSObject, Dispatcher, URLSessionWebSocketDelegate {
    
    var onMessage: ((String) -> ())?
    
    var socket: WebSocketSession!
    
    override init() {
        super.init()
        let session  = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        socket = WebSocketSession(session: session, url: makeRelayUrl())
        socket.onMessageReceived = { [weak self] in
            self?.onMessage?($0)
        }
    }
    
    func makeRelayUrl() -> URL {
        var components = URLComponents()
        components.scheme = "wss"
        components.host = "relay.dev.walletconnect.com"
//        components.host = "relay.walletconnect.com"
        components.queryItems = [URLQueryItem(name: "projectId", value: "52af113ee0c1e1a20f4995730196c13e")]
        return components.url!
    }
    
    func send(_ message: String, completion: @escaping (Error?) -> ()) {
        print("--> \(message)")
        socket.send(message, completionHandler: completion)
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("socket did open")
    }
}

final class WebSocketSession: NSObject {
    
    var onMessageReceived: ((String) -> ())?
    var onMessageError: ((Error) -> ())?
    
    let url: URL
    
    var isConnected: Bool {
        webSocketTask != nil
    }
    
    private let session: URLSession
    
    private var webSocketTask: URLSessionWebSocketTask?
    
    init(session: URLSession, url: URL) {
        self.session = session
        self.url = url
        super.init()
    }
    
    func connect() {
//        print("connecting...")
        webSocketTask = session.webSocketTask(with: url)
        listen()
        webSocketTask?.resume()
    }
    
    func disconnect(with closeCode: URLSessionWebSocketTask.CloseCode = .normalClosure) {
        webSocketTask?.cancel(with: closeCode, reason: nil)
        webSocketTask = nil
    }
    
    func send(_ message: String, completionHandler: @escaping ((Error?) -> Void)) {
        if let webSocketTask = webSocketTask {
            webSocketTask.send(.string(message)) { error in
                if let error = error {
//                    completionHandler(NetworkError.sendMessageFailed(error))
                    completionHandler(error)
                } else {
                    completionHandler(nil)
                }
            }
        } else {
//            completionHandler(NetworkError.webSocketNotConnected)
            fatalError("ERROR: not connected!")
        }
    }
    
    private func listen() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleMessage(message)
            case .failure(let error):
//                self?.onMessageError?(NetworkError.receiveMessageFailure(error))
                self?.onMessageError?(error)
            }
            self?.listen()
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            onMessageReceived?(text)
        case .data(let data):
            print("Transport: Unexpected type of message received")
//            print("Transport: Unexpected type of message received: \(data.toHexString())")
        @unknown default:
            print("Transport: Unexpected type of message received (UNKNOWN)")
        }
    }
}
