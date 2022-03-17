import XCTest
@testable import JSONRPC

func makeRelayUrl() -> URL {
    var components = URLComponents()
    components.scheme = "wss"
    components.host = "relay.dev.walletconnect.com"
    components.queryItems = [URLQueryItem(name: "projectId", value: "52af113ee0c1e1a20f4995730196c13e")]
    return components.url!
}

final class SocketTests: XCTestCase {
    
    var session: URLSession!
    var socketDelegate: SocketDelegate!
    let queue = OperationQueue()
    
    func testSocketSubscribe() {
        print("\n")
//        let expectA = expectation(description: "socket expectation")
        let expect = expectation(description: "message expectation")
        
        let url = makeRelayUrl()
        print("Relay URL: \(url)")
        socketDelegate = SocketDelegate()
        socketDelegate.didOpen = {
//            expectA.fulfill()
        }
        session = URLSession(configuration: .default, delegate: socketDelegate, delegateQueue: queue)
        
        // connect socket
        let socket = WebSocketSession(session: session, url: url)
        socket.onMessageReceived = {
            print("Message received: \($0)")
            expect.fulfill()
        }
        socket.onMessageError = {
            print("Error received: \($0) ----- \($0.localizedDescription)")
//            expect.fulfill()
        }
        print("connectineg...")
        socket.connect()
        
//        wait(for: [expectA, expect], timeout: 10.0)
//        return
        
        // do things
        let topic = Data.randomBytes(count: 32).toHexString()
        let request = Subscribe(parameters: .init(topic: topic)).asRPCRequest()
        let msgData = try! JSONEncoder().encode(request)
        let message = String(data: msgData, encoding: .utf8)!

        
        print("Sending subscribe to topic: \(topic)")
        print("Message JSON:\n\n\(message)\n")

        socket.send(message) {
            print("Error sending message: \(String(describing: $0))")
        }
        
        wait(for: [expect], timeout: 15.0)
//        waitForExpectations(timeout: 10.0, handler: nil)
        print("\n")
    }
    
    func testSocketUnsubscribe() {
        let expect = expectation(description: "message expectation")
        
        let url = makeRelayUrl()
        socketDelegate = SocketDelegate()
        socketDelegate.didOpen = {
//            expectA.fulfill()
        }
        session = URLSession(configuration: .default, delegate: socketDelegate, delegateQueue: queue)
        
        print("\n")
        let socket = WebSocketSession(session: session, url: url)
        socket.onMessageReceived = {
            print("Message received: \($0)")
            expect.fulfill()
        }
        socket.onMessageError = {
            print("Error received: \($0)")
            expect.fulfill()
        }
        print("connecting...")
        socket.connect()
        
        let request = Unsubscribe(parameters: .init(topic: "aaa", id: "iddd")).asRPCRequest()
        let msgData = try! JSONEncoder().encode(request)
        let message = String(data: msgData, encoding: .utf8)!
        
        print("Message JSON:\n\n\(message)\n")
        
        socket.send(message) {
            print("Error sending message: \(String(describing: $0))")
        }
        
        wait(for: [expect], timeout: 15.0)
        print("\n")
    }
}

class SocketDelegate: NSObject, URLSessionWebSocketDelegate {
    
    var didOpen: (()->Void)?
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
//        print("web socket did open with protocol: \(`protocol`)")
        print("web socket open")
        didOpen?()
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("web socket closed with code: \(closeCode.rawValue)") // 1002 = protocol error
    }
}
