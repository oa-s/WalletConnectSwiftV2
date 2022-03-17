import Foundation



struct Request: Codable {
    let jsonrpc: String
    let method: String
    let params: AnyCodable
    let id: Int // Can be string or null (notification)
    
    internal init<C>(method: String, params: C) where C: Codable {
        self.jsonrpc = "2.0"
        self.method = method
        self.params = AnyCodable(params)
        self.id = Int(Self.generateId())
    }
    
    // TODO: Decouple this
    public static func generateId() -> Int64 {
        return Int64(Date().timeIntervalSince1970 * 1000)*1000 + Int64.random(in: 0..<1000)
    }
}

extension Request {
    
    init<T>(_ method: T) where T: RPCMethod {
        self.init(method: method.method, params: method.parameters)
    }
}

struct Response: Codable {
    let jsonrpc: String = "2.0" // TODO: provide an init
    let id: Int
    // either result or error
    var result: AnyCodable?
    var error: Error?
    
    
    
    struct Error: Swift.Error, Codable {
        let code: Int
        let message: String
//        let data: Any?
    }
    
    init(id: Int, result: AnyCodable?, error: Error?) {
        self.id = id
        self.result = result
        self.error = error
    }
    
    init<T: Codable>(fromResult result: Result<T, Error>, id: Int) {
        self.id = id
        switch result {
        case .success(let t):
            self.result = AnyCodable(t)
        case .failure(let error):
            self.error = error
        }
    }
}



protocol RPCMethod {
    associatedtype Parameters: Codable
    var method: String { get }
    var parameters: Parameters { get }
    func asRPCRequest() -> Request
}

extension RPCMethod {
    func asRPCRequest() -> Request {
        Request(self)
    }
}



struct Publish: RPCMethod {
    
    struct Params: Codable, Equatable {
        let topic: String
        let message: String
        let ttl: Int
        let prompt: Bool?
    }
    
    var method: String {
        "waku_publish"
    }
    
    let parameters: Params
}

struct Subscribe: RPCMethod {
    
    struct Params: Codable, Equatable {
        let topic: String
    }
    
    var method: String {
        "waku_subscribe"
    }
    
    let parameters: Params
}

struct Unsubscribe: RPCMethod {
    
    struct Params: Codable, Equatable {
        let topic: String
        let id: String
    }
    
    var method: String {
        "waku_unsubscribe"
    }
    
    let parameters: Params
}

struct Subscription: RPCMethod {
    
    struct Params: Codable, Equatable {
        let id: String
        let data: Subdata
        
        struct Subdata: Codable, Equatable {
            let topic: String
            let message: String
        }
    }
    
    var method: String {
        "waku_subscription"
    }
    
    let parameters: Params
}
