import XCTest
@testable import JSONRPC

final class RelayTests: XCTestCase {
    
    // integration tests
    
    let defaultTimeout: TimeInterval = 15.0
    
    func testSubscribe() {
        let expectation = expectation(description: "subscribe expect")
        let relay = Relayer()
        let topic = Data.randomBytes(count: 32).toHexString()
        var count = 0
        relay.onMessage = {
            print("Received message \(count + 1): \($0)")
            if count > 0 {
                expectation.fulfill()
            } else {
                print("Subscribing again, same topic...")
                relay.subscribe(topic: topic)
            }
            count += 1
        }
        relay.subscribe(topic: topic)
        waitForExpectations(timeout: defaultTimeout, handler: nil)
    }
    
    func testUnsubscribe() {
        let expectation = expectation(description: "unsubscribe expect")
        let relay = Relayer()
        relay.onMessage = {
            print("Received message: \($0)")
            expectation.fulfill()
        }
        let topic = Data.randomBytes(count: 32).toHexString()
        relay.unsubscribe(topic: topic)
        waitForExpectations(timeout: defaultTimeout, handler: nil)
    }
    
    func testPublish() {
        let expectation = expectation(description: "publish expect")
        let relay = Relayer()
        relay.onMessage = {
            print("Received message: \($0)")
            expectation.fulfill()
        }
        let topic = Data.randomBytes(count: 32).toHexString()
        relay.publish(topic: topic, payload: "hello")
        waitForExpectations(timeout: defaultTimeout, handler: nil)
    }
    
    func testADecode() {
        print("")
        let req = Subscription(parameters: .init(id: "id", data: .init(topic: "topic", message: "0x00deadbeef")))
        let rpc = req.asRPCRequest()
        let rpcMsg = String(data: try! JSONEncoder().encode(rpc), encoding: .utf8)!
        
        let relay = Relayer()
        relay.handleMessage(rpcMsg)
        print("")
    }
    
    func testRandomData() {
        print("")
        let expectation = expectation(description: "response expect")
        let relay = Relayer()
        relay.onMessage = {
            print("Received message: \($0)")
            expectation.fulfill()
        }
        let message = String(data: try! JSONEncoder().encode(Incomplete()), encoding: .utf8)!
        relay.dispatcher.send(message) { error in
            print("Error send: \(error)")
        }
        waitForExpectations(timeout: defaultTimeout, handler: nil)
    }
    
    //
    
    func testLeakOnWCRelay() {
//        var wcRelay: WCRelayer? = WCRelayer()
//        weak var weakRef = wcRelay
//        weak var boxRef = wcRelay!.methods["wc_sessionPropose"]!
//        wcRelay = nil
//        XCTAssertNil(weakRef)
//        XCTAssertNil(boxRef)
    }
}

struct Incomplete: Codable {
    let jsonrpc: String
    let id: Int
    
    init() {
        jsonrpc = "2.0"
        id = 9999
    }
}

extension Data {
    
    public static func randomBytes(count: Int) -> Data {
        var buffer = [UInt8](repeating: 0, count: count)
        let status = SecRandomCopyBytes(kSecRandomDefault, count, &buffer)
        guard status == errSecSuccess else {
            fatalError("Failed to generate secure random data of size \(count).")
        }
        return Data(buffer)
    }
    
    public func toHexString() -> String {
        return map { String(format: "%02x", $0) }.joined()
    }
}
