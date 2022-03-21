import Foundation

class RPCInvoker<Target: AnyObject> {
    
    weak var target: Target?
    
    private let invoke: (Target) -> (Request) throws -> Response

    // TODO: Use decoupled error type
    init<Input, Output>(_ target: Target, executer: @escaping (Target) -> (Input) throws -> Result<Output, Response.Error>) where Input: Codable, Output: Codable {
        self.target = target
        self.invoke = { target in
            return { request in
                let params = try request.params.get(Input.self)
                let result = try executer(target)(params) // maybe needs to be async
                let response = Response(fromResult: result, id: request.id)
                return response
            }
        }
    }
    
    func execute(_ request: Request) throws -> Response? {
        guard let target = target else { return nil }
        return try invoke(target)(request)
    }
}



class WCEngine {
    
//    var rpcClient: RPCClient!
    
    var methodInvokers: [String: RPCInvoker<WCEngine>] = [:]
    
    init() {
        registerRPCMethods()
        setupClient()
    }
    
    func registerRPCMethods() {
        methodInvokers["wc_sessionPropose"] = RPCInvoker(self, executer: WCEngine.wcPropose)
        methodInvokers["wc_sessionSettle"] = RPCInvoker(self, executer: WCEngine.wcSettle)
        methodInvokers["wc_sessionUpgrade"] = RPCInvoker(self, executer: WCEngine.wcUpgrade)
    }
    
    // sender methods
    
    func propose() {
        let method = Propose(parameters: .init(proposerKey: "key", blockchain: ["eip"], permissions: ["sign"]))
        sendRequest(method)
    }
    
    func settle() {
        let method = Settle(parameters: .init(relay: "waku", blockchain: ["eip"], permissions: ["sign"], controller: true))
        sendRequest(method)
    }
    
    func request() {
        
    }
    
    // receiver methods
    
    func wcPropose(proposeParams: Propose.Params) -> Result<Bool, Response.Error> {
        fatalError()
    }
    
    func wcSettle(settleParams: Settle.Params) -> Result<Bool, Response.Error> {
        // settle things
        return .success(true)
    }
    
//    func wcSessionRequest(requestParams: SessionRequest.Params) {
//
//    }
    
    // generic components - should be moved to another object
    
    var dispatcher: Dispatcher!
    
    func setupClient() {
        let dsp = MessageDispatcher()
        dispatcher = dsp
        dispatcher.onMessage = { [weak self] in self?.handleMessage($0) }
        dsp.socket.connect()
    }
    
    func sendRequest<T: RPCMethod>(_ method: T) {
        let data = try! JSONEncoder().encode(method.asRPCRequest())
        let message = String(data: data, encoding: .utf8)!
        dispatcher.send(message) { Error in
            // Handle error?
        }
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
    }
    
    func handleRequest(_ request: Request) {
        if let method = methodInvokers[request.method] {
            let response = try? method.execute(request)
        } else {
            // method not found --- json rpc error -32601
        }
    }
}

//class RPCClient {
//
//    var dispatcher: Dispatcher!
//
//    init() {
//        // setup here
//        let dsp = MessageDispatcher()
//        dispatcher = dsp
//        dispatcher.onMessage = { [weak self] in self?.handleMessage($0) }
//        dsp.socket.connect()
//    }
//
//    func sendRequest<T: RPCMethod>(_ method: T) {
//        let data = try! JSONEncoder().encode(method.asRPCRequest())
//        let message = String(data: data, encoding: .utf8)!
//        dispatcher.send(message) { Error in
//            // Handle error?
//        }
//    }
//
//    func handleMessage(_ message: String) {
//        // step 1: know if its a request or response
//        let messageData = message.data(using: .utf8)!
//        if let request = try? JSONDecoder().decode(Request.self, from: messageData) {
//            // handle request
//            handleRequest(request)
//        } else {
//            do {
//                let response = try JSONDecoder().decode(Response.self, from: messageData)
////                handleResponse(response)
//            } catch {
//                // malformed response
//            }
//        }
//    }
//
//    func handleRequest(_ request: Request) {
//
//    }
//}



//class WCRelayer {
//
//    // engine methods
//
//    init() {
//        registerMethods()
//    }
//
//    // callers
//
//    func propose() {
//        let method = Propose(parameters: .init(proposerKey: "key", blockchain: ["eip"], permissions: ["sign"]))
//        sendRequest(method)
//    }
//
//    func settle() {
//
//    }
//
//    func request() {
//
//    }
//
//    func sendRequest<T: RPCMethod>(_ method: T) {
//        let data = try! JSONEncoder().encode(method.asRPCRequest())
//        let message = String(data: data, encoding: .utf8)!
////        dispatcher.send(message) { Error in
////            // Handle error?
////        }
//    }
//
//    // handlers
//
//    var methodInvokers: [String: RPCInvoker<WCRelayer>] = [:]
//
//    func registerMethods() {
//        methodInvokers["wc_sessionPropose"] = RPCInvoker(self, executer: WCRelayer.wcPropose)
//        methodInvokers["wc_sessionSettle"] = RPCInvoker(self, executer: WCRelayer.wcSettle)
//    }
//
//    func wcPropose(proposeParams: Propose.Params) -> Result<Bool, Response.Error> {
//        fatalError()
//    }
//
//    func wcSettle(settleParams: Settle.Params) -> Result<Bool, Response.Error> {
//        fatalError()
//    }
//
//
//    func handleRequest2(_ request: Request) {
//        let response = methodInvokers[request.method]?.execute(request)
//    }
//
//    func handleMessage(_ message: String) {
//        // step 1: know if its a request or response
//        let messageData = message.data(using: .utf8)!
//        if let request = try? JSONDecoder().decode(Request.self, from: messageData) {
//            // handle request
//            handleRequest(request)
//        } else {
//            do {
//                let response = try JSONDecoder().decode(Response.self, from: messageData)
////                handleResponse(response)
//            } catch {
//                // malformed response
//            }
//        }
////        onMessage?(message)
//    }
//
//    func handleRequest(_ request: Request) {
//        if request.method == "wc_sessionPropose" {
//            let params = try? request.params.get(Propose.Params.self)
//
//            // respond
//        } else if request.method == "wc_sessionSettle" {
//            let params = try? request.params.get(Settle.Params.self)
//            // respond
//        } else if request.method == "wc_sessionRequest" {
//            let params = try? request.params.get(SessionRequest.Params.self)
//            // respond
//        } else {
//            print("not valid request")
//        }
//    }
//}
//
//
