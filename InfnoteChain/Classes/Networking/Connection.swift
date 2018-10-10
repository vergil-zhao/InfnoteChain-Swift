//
//  Connection.swift
//  InfnoteChain
//
//  Created by Vergil Choi on 2018/10/5.
//

import Foundation
import Starscream

public indirect enum ConnectionObserver {
    case nothing
    case connect((Connection) -> Void, ConnectionObserver)
    case disconnect((Error?, Connection) -> Void, ConnectionObserver)
    
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
    
    public static func onConnected(_ callback: @escaping (Connection) -> Void) -> ConnectionObserver {
        return .connect(callback, .nothing)
    }
    
    public func onDisconnected(_ callback: @escaping (Error?, Connection) -> Void) -> ConnectionObserver {
        return .disconnect(callback, self)
    }
}

public indirect enum Connection {
    case initial(Peer)
    case handled(ConnectionObserver, Connection)
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
            return peer.dispatcher!.socket.isConnected
        case .handled(_, let conn):
            return conn.isConnected
        case .connecting(let conn):
            return conn.isConnected
        case .disconnecting(let conn):
            return conn.isConnected
        }
    }
    
    public init(_ peer: Peer) {
        self = .initial(peer)
    }
    
    public func handled(by handler: ConnectionObserver) -> Connection {
        switch self {
        case .initial(let peer):
            peer.dispatcher!.onConnected = { handler.connect?(self) }
            peer.dispatcher!.onDisconnected = { e in handler.disconnect?(e, self) }
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
            peer.dispatcher!.socket.connect()
            return .connecting(self)
        case .handled(_, let conn):
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
            peer.dispatcher!.socket.disconnect(forceTimeout: 0, closeCode: CloseCode.normal.rawValue)
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
