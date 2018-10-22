//
//  Message.swift
//  InfnoteChain
//
//  Created by Vergil Choi on 2018/10/7.
//

import Foundation

public indirect enum CourierObserver {
    case nothing
    case response((Message) -> Bool, CourierObserver)
    case error((Error) -> Void, CourierObserver)
    
    public var response: ((Message) -> Bool)? {
        switch self {
        case .response(let callback, _):
            return callback
        case .error(_, let handler):
            return handler.response
        default:
            return nil
        }
    }
    
    public var error: ((Error) -> Void)? {
        switch self {
        case .error(let callback, _):
            return callback
        default:
            return nil
        }
    }
    
    public init() {
        self = .nothing
    }
    
    public static func onResponse(_ callback: @escaping (Message) -> Bool) -> CourierObserver {
        return .response(callback, .nothing)
    }
    
    public func onError(_ callback: @escaping (Error) -> Void) -> CourierObserver {
        return .error(callback, self)
    }
}

public indirect enum Courier {
    case bring(Message)
    case sending(Connection, Courier)
    case handled(CourierObserver, Courier)
    
    public var message: Message {
        switch self {
        case .bring(let content):
            return content
        case .sending(_, let courier):
            return courier.message
        case .handled(_, let courier):
            return courier.message
        }
    }
    
    public init(_ message: Message) {
        self = .bring(message)
    }
    
    @discardableResult
    public func send(through conn: Connection) -> Courier {
        guard case let .bring(message) = self else {
            return self
        }
        conn.peer.dispatcher!.send(message: message)
        return .sending(conn, self)
    }
    
    @discardableResult
    public func handled(by handler: CourierObserver) -> Courier {
        switch self {
        case let .sending(conn, courier):
            if let response = handler.response {
                conn.peer.dispatcher!.register(response, for: courier.message)
                return .handled(handler, self)
            }
            return self
        case .handled(_, let courier):
            return courier.handled(by: handler)
        case .bring(_):
            return self
        }
    }
}
