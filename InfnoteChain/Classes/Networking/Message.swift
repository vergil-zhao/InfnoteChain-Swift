//
//  Message.swift
//  InfnoteChain
//
//  Created by Vergil Choi on 2018/10/7.
//

import Foundation

public indirect enum MessageHandler {
    case nothing
    case response((String) -> Void, MessageHandler)
    case error((Error) -> Void, MessageHandler)
    
    public var response: ((String) -> Void)? {
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
    
    public static func onResponse(_ callback: @escaping (String) -> Void) -> MessageHandler {
        return .response(callback, .nothing)
    }
    
    public func onError(_ callback: @escaping (Error) -> Void) -> MessageHandler {
        return .error(callback, self)
    }
}

public indirect enum Message {
    case content(String)
    case sending(Connection, Message)
    case handled(MessageHandler, Message)
    
    public var content: String {
        switch self {
        case .content(let content):
            return content
        case .sending(_, let msg):
            return msg.content
        case .handled(_, let msg):
            return msg.content
        }
    }
    
    public init(_ content: String) {
        self = .content(content)
    }
    
    @discardableResult
    public func send(through conn: Connection) -> Message {
        guard case let .content(content) = self else {
            return self
        }
        conn.peer.socket.write(string: content)
        return .sending(conn, self)
    }
    
    @discardableResult
    public func handled(by handler: MessageHandler) -> Message {
        switch self {
        case .sending(let conn, _):
            conn.peer.socket.onText = handler.response
            return .handled(handler, self)
        case .handled(_, let msg):
            return msg.handled(by: handler)
        case .content(_):
            return self
        }
    }
}
