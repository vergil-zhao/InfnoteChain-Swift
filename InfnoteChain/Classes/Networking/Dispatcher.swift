//
//  Dispatcher.swift
//  InfnoteChain
//
//  Created by Vergil Choi on 2018/10/8.
//

import Foundation
import Starscream

class Dispatcher {
    // TODO: add a time mark, remove callbacks no response for long time
    var callbacks: [String: (Message) -> Void] = [:]
    var globalHandler: ((Message) -> Void)? = nil
    
    var onConnected: (() -> Void)? {
        get {
            return socket.onConnect
        }
        set {
            socket.onConnect = newValue
        }
    }
    
    var onDisconnected: ((Error?) -> Void)? {
        get {
            return socket.onDisconnect
        }
        set {
            socket.onDisconnect = newValue
        }
    }
    
    let socket: WebSocket
    
    init(with socket: WebSocket) {
        self.socket = socket
        self.socket.onData = { [unowned self] data in
            guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
                let json = jsonObject as? [String: Any],
                let message = Message(json) else {
                    return
            }
            
            self.dispatch(message)
        }
        self.socket.onText = { [unowned self] text in
            guard let data = text.data(using: .utf8),
                let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
                let json = jsonObject as? [String: Any],
                let message = Message(json) else {
                    return
            }
            
            self.dispatch(message)
        }
    }
    
    func send(message: Message) {
        socket.write(string: message.json)
    }
    
    func register(_ handler: @escaping (Message) -> Void, for message: Message) {
        callbacks[message.identifier] = handler
    }
    
    @discardableResult
    func dispatch(_ message: Message) -> Bool {
        if let callback = callbacks[message.identifier] {
            callback(message)
            callbacks[message.identifier] = nil
            return true
        }
        if let global = globalHandler {
            global(message)
            return true
        }
        return false
    }
}
