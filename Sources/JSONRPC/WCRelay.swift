import Foundation

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



class WCRelayer {
    
    // engine methods
    
    init() {
        registerMethods()
    }
    
    // callers
    
    func propose() {
        let method = Propose(parameters: .init(proposerKey: "key", blockchain: ["eip"], permissions: ["sign"]))
        sendRequest(method)
    }
    
    func settle() {
        
    }
    
    func request() {
        
    }
    
    func sendRequest<T: RPCMethod>(_ method: T) {
        let data = try! JSONEncoder().encode(method.asRPCRequest())
        let message = String(data: data, encoding: .utf8)!
//        dispatcher.send(message) { Error in
//            // Handle error?
//        }
    }
    
    // handlers
    
    var methodInvokers: [String: Invoker<WCRelayer>] = [:]
    
    func registerMethods() {
        methodInvokers["wc_sessionPropose"] = Invoker(self, executer: WCRelayer.wcPropose)
        methodInvokers["wc_sessionSettle"] = Invoker(self, executer: WCRelayer.wcSettle)
    }
    
    func wcPropose(proposeParams: Propose.Params) -> Result<Bool, Response.Error> {
        fatalError()
    }
    
    func wcSettle(settleParams: Settle.Params) -> Result<Bool, Response.Error> {
        fatalError()
    }
    
    
    func handleRequest2(_ request: Request) {
        let response = methodInvokers[request.method]?.execute(request)
    }
    
    func handleMessage(_ message: String) {
        // step 1: know if its a request or response
        let messageData = message.data(using: .utf8)!
        if let request = try? JSONDecoder().decode(Request.self, from: messageData) {
            // handle request
            handleRequest(request)
        } else {
            do {
                let response = try JSONDecoder().decode(Response.self, from: messageData)
//                handleResponse(response)
            } catch {
                // malformed response
            }
        }
//        onMessage?(message)
    }
    
    func handleRequest(_ request: Request) {
        if request.method == "wc_sessionPropose" {
            let params = try? request.params.get(Propose.Params.self)
            
            // respond
        } else if request.method == "wc_sessionSettle" {
            let params = try? request.params.get(Settle.Params.self)
            // respond
        } else if request.method == "wc_sessionRequest" {
            let params = try? request.params.get(SessionRequest.Params.self)
            // respond
        } else {
            print("not valid request")
        }
    }
}

class Invoker<Target: AnyObject> {
    
    weak var target: Target?
    
    private let invoke: (Target) -> (Request) -> Response

    // TODO: Use decoupled error type
    init<Input, Output>(_ target: Target, executer: @escaping (Target) -> (Input) -> Result<Output, Response.Error>) where Input: Codable, Output: Codable {
        self.target = target
        self.invoke = { target in
            return { request in
                let params = try! request.params.get(Input.self)
                let result = executer(target)(params) // maybe needs to be async
                let response = Response(fromResult: result, id: request.id)
                return response
            }
        }
    }
    
    func execute(_ request: Request) -> Response? {
        guard let target = target else { return nil }
        return invoke(target)(request)
    }
}
