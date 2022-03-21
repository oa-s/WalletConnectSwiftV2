
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



//struct MethodDecorator<T: RPCMethod>: RPCMethod {
//
//    let decorated: T
//
//    typealias Parameters = T.Parameters
//
//    var method: String {
//        "wc_\(decorated.method)"
//    }
//
//    var parameters: T.Parameters {
//        decorated.parameters
//    }
//}



// Relayer RPC API

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

// WalletConnect RPC API

struct SessionRequest: RPCMethod {
    
    struct Params: Codable {
        let request: Request
        let chainId: String?
        
        // blockchain request
        struct Request: Codable {
            let method: String
            let params: AnyCodable
        }
    }
    
    var method: String {
        "wc_sessionRequest"
    }
    
    let parameters: Params
}

struct Propose: RPCMethod {
    
    struct Params: Codable {
        let proposerKey: String
        let blockchain: [String]
        let permissions: [String]
    }
    
    var method: String {
        "wc_sessionPropose"
    }
    
    let parameters: Params
}

// ???
struct ProposeResponse: Codable {
    let relay: String
    let responderKey: String
}

struct Settle: RPCMethod {
    
    struct Params: Codable, Equatable {
        let relay: String
        let blockchain: [String]
        let permissions: [String]
        let controller: Bool
    }
    
    var method: String {
        "wc_sessionSettle"
    }
    
    let parameters: Params
}
