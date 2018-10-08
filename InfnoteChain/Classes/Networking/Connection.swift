//
//  Connection.swift
//  InfnoteChain
//
//  Created by Vergil Choi on 2018/10/5.
//

import Foundation
import Starscream

public indirect enum ConnectionHandler {
    case nothing
    case connect((Connection) -> Void, ConnectionHandler)
    case disconnect((Error?, Connection) -> Void, ConnectionHandler)
    
    public var connect: ((Connection) -> Void)? {
        switch self {
        case .connect(let callback, _):
            return callback
        case .disconnect(_, let handler):
            return handler.connect
        default:
            return nil
        }
    }
    
    public var disconnect: ((Error?, Connection) -> Void)? {
        guard case let .disconnect(callback, _) = self else {
            return nil
        }
        return callback
    }
    
    public static func onConnected(_ callback: @escaping (Connection) -> Void) -> ConnectionHandler {
        return .connect(callback, .nothing)
    }
    
    public func onDisconnected(_ callback: @escaping (Error?, Connection) -> Void) -> ConnectionHandler {
        return .disconnect(callback, self)
    }
}

public indirect enum Connection {
    case initial(Peer)
    case handled(ConnectionHandler, Connection)
    case connecting(Connection)
    case disconnecting(Connection)
    
    public var peer: Peer {
        switch self {
        case .initial(let peer):
            return peer
        case .handled(_, let conn):
            return conn.peer
        case .connecting(let conn):
            return conn.peer
        case .disconnecting(let conn):
            return conn.peer
        }
    }
    
    public var isConnected: Bool {
        switch self {
        case .initial(let peer):
            return peer.socket.isConnected
        case .handled(_, let conn):
            return conn.isConnected
        case .connecting(let conn):
            return conn.isConnected
        case .disconnecting(let conn):
            return conn.isConnected
        }
    }
    
    public init(_ peer: Peer) {
        peer.createSocket()
        self = .initial(peer)
    }
    
    public func handled(by handler: ConnectionHandler) -> Connection {
        switch self {
        case .initial(let peer):
            peer.socket.onConnect = { handler.connect?(self) }
            peer.socket.onDisconnect = { e in handler.disconnect?(e, self) }
            return .handled(handler, self)
        case let .handled(_, conn):
            return conn.handled(by: handler)
        case .connecting(let conn):
            return conn.handled(by: handler)
        case .disconnecting(let conn):
            return conn.handled(by: handler)
        }
    }
    
    @discardableResult
    public func connect() -> Connection {
        switch self {
        case .initial(let peer):
            peer.socket.connect()
            return .connecting(self)
        case let .handled(handler, conn):
            return conn.connect()
        case .connecting(let conn):
            return conn.connect()
        case .disconnecting(let conn):
            return conn.connect()
        }
    }
    
    @discardableResult
    public func disconnect() -> Connection {
        switch self {
        case .initial(let peer):
            peer.socket.disconnect(forceTimeout: 0, closeCode: CloseCode.normal.rawValue)
            return .disconnecting(self)
        case .connecting(let conn):
            return conn.disconnect()
        case .handled(_, let conn):
            return conn.disconnect()
        case .disconnecting(_):
            return self
        }
    }
}
