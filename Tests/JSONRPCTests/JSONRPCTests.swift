import XCTest
@testable import JSONRPC

let testSubscribeRequest = """
{
    "id": 1,
    "jsonrpc": "2.0",
    "method": "waku_subscribe",
    "params": {
        "topic": "<TOPIC_ID>"
    }
}
""".data(using: .utf8)!

let testSubscribeResponse = """
{
    "id": 1,
    "jsonrpc": "2.0",
    "result": "<SUBSCRIPTION_ID>"
}
"""


let testPositionalParametersRequest = """
{
    "jsonrpc": "2.0",
    "method": "subtract",
    "params": [
        42,
        23
    ],
    "id": 1
}
"""

let testNamedParametersRequest = """
{
    "jsonrpc": "2.0",
    "method": "subtract",
    "params": {
        "subtrahend": 23,
        "minuend": 42
    },
    "id": 3
}
"""

let testIntResponseJSON = """
{
    "jsonrpc": "2.0",
    "result": 420,
    "id": 1
}
"""

let testStringResponseJSON = """
{
    "id": 1,
    "jsonrpc": "2.0",
    "result": "<SUBSCRIPTION_ID>"
}
""".data(using: .utf8)!

let testErrorResponseJSON = """
{
    "jsonrpc": "2.0",
    "error": {
        "code": -32600,
        "message": "Invalid Request"
    },
    "id": 0
}
""".data(using: .utf8)!

let testInvalidResponseJSON = """
{
    "id": 1,
    "jsonrpc": "2.0",
    "result": true,
    "error": {
        "code": -32600,
        "message": "Invalid Request"
    }
}
""".data(using: .utf8)!

final class JSONRPCTests: XCTestCase {
    
    func testExampleA() throws {
        let request = try JSONDecoder().decode(Request.self, from: testSubscribeRequest)
        let params = try request.params.get([String: String].self)
        XCTAssertEqual(params["topic"], "<TOPIC_ID>")
    }
    
    func testExB() throws {
        let params = SampleStruct.stub()
        let request = Request(method: "method", params: params)
        let encoded = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(Request.self, from: encoded)
        let decodedParams = try decoded.params.get(SampleStruct.self)
        XCTAssertEqual(decodedParams, params)
    }
    
    func testExample() throws {
        let response = try JSONDecoder().decode(Response.self, from: testStringResponseJSON)
        let result = try response.result?.get(String.self)
        XCTAssertEqual(result, "<SUBSCRIPTION_ID>")
    }
    
    func testExampleC() throws {
        let response = try JSONDecoder().decode(Response.self, from: testErrorResponseJSON)
        XCTAssertEqual(response.error?.code, -32600)
    }
    
//    func testExampleErr() throws {
//        XCTAssertThrowsError(try JSONDecoder().decode(Response.self, from: testInvalidResponseJSON))
//    }
    
    // relay specific
    
    func testPublish() {
//        let request = Publish(topic: "aaa", message: "bbb", ttl: 1, prompt: false).asRPCRequest()
//        let req = Request.publish(topic: "aaa", message: "bbb", ttl: 1, prompt: false)
        let request = Publish(parameters: .init(topic: "aaa", message: "bbb", ttl: 1, prompt: false)).asRPCRequest()
    }
    
    func testSubscribe() {
        let request = Subscribe(parameters: .init(topic: "topic"))
    }
}


fileprivate struct SampleStruct: Codable, Equatable {
    
    let bool: Bool
    let int: Int
    let double: Double
    let string: String
    let array: [String]
    let object: SubObject?
    
    struct SubObject: Codable, Equatable {
        let string: String
    }
    
    static func stub() -> SampleStruct {
        SampleStruct(
            bool: Bool.random(),
            int: Int.random(in: Int.min...Int.max),
            double: Double.random(in: -1337.00...1337.00),
            string: UUID().uuidString,
            array: (1...10).map { _ in UUID().uuidString },
            object: SubObject(string: UUID().uuidString)
        )
    }
}


//// Request (Client -> Server)
//{
//  "id": 2,
//  "jsonrpc": "2.0",
//  "method": "waku_publish",
//  "params": {
//    "topic": "<TOPIC_ID>",
//    "message": "<MESSAGE_PAYLOAD>",
//    "ttl": 86400
//  }
//}
//
//// Response (Server -> Client)
//{
//  "id": 2,
//  "jsonrpc": "2.0",
//  "result": true
//}


//// Request (Server -> Client)
//{
//  "id": 3,
//  "jsonrpc": "2.0",
//  "method": "waku_subscription",
//  "params": {
//    "id": "<SUBSCRIPTION_ID>",
//    "data": {
//      "topic": "<TOPIC_ID>",
//      "message": "<MESSAGE_PAYLOAD>",
//    }
//  }
//}
//
//// Response (Client -> Server)
//{
//  "id": 3,
//  "jsonrpc": "2.0",
//  "result": true
//}
