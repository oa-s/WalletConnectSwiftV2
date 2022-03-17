import Foundation


// web client
// message delivery guarantee must happen inside dispatcher
protocol Dispatcher {
    var onMessage: ((String) -> ())? {get set}
    func send(_ message: String, completion: @escaping (Error?)->()) // send error
}

// specialized service
class Relayer {
    
    var onMessage: ((String) -> Void)?
    
    var dispatcher: Dispatcher!
    
//    var `protocol` = "waku"
    
    init() {
        // setup here
        let dsp = MessageDispatcher()
        dispatcher = dsp
        dispatcher.onMessage = { [weak self] in self?.handleMessage($0) }
        dsp.socket.connect()
    }
    
    func subscribe(topic: String) {
        let request = Subscribe(parameters: .init(topic: topic))
        sendRequest(request)
    }
    
    func unsubscribe(topic: String) {
        let id = "SUBSCRIPT_ID"
        let request = Unsubscribe(parameters: .init(topic: topic, id: id))
        sendRequest(request)
    }
    
    func publish(topic: String, payload: String, prompt: Bool = false) {
        let request = Publish(parameters: .init(topic: topic, message: payload, ttl: 600, prompt: prompt))
        sendRequest(request)
    }
    
    // subscription
    
    // *****
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
                handleResponse(response)
            } catch {
                // malformed response
            }
        }
        
        
        onMessage?(message)
    }
    
    func handleRequest(_ request: Request) {
        if request.method == "waku_subscription" {
//            let params = try? JSONDecoder().decode(Subscription.Params.self, from: request.)
            let params = try? request.params.get(Subscription.Params.self)
            print("params: \(params)")
            // respond
        } else if request.method == "waku_publish" {
            let params = try? request.params.get(Publish.Params.self)
            // respond
        } else {
            print("not valid request")
        }
    }
    
    func handleResponse(_ response: Response) {
        
    }
}




