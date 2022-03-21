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
