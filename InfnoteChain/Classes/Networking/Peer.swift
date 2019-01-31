//
//  Peer.swift
//  InfnoteChain
//
//  Created by Vergil Choi on 2018/10/4.
//

import Foundation
import RealmSwift
import Starscream

public class Service {
    public static var shared = Service()
    
    private var peers: [Peer] = []
    
    public func start() {}
}

public class Peer: Object {
    
    @objc open dynamic var address: String = ""
    @objc open dynamic var rank: Int = 100
    @objc open dynamic var last: Int = 0
    
    private var socket: WebSocket?
    
    public var isConnected: Bool {
        if socket == nil {
            return false
        }
        return socket!.isConnected
    }
    
    public override static func primaryKey() -> String? {
        return "address"
    }
    
    public convenience init?(address: String, rank: Int = 100) {
        guard let url = URL(string: address),
            let scheme = url.scheme,
            scheme == "ws" || scheme == "wss" else {
                return nil
        }
        
        self.init()
        self.address = address
        self.rank = rank
        
    }
    
    public static func == (lhs: Peer, rhs: Peer) -> Bool {
        return lhs.address == rhs.address
    }
    
    public func connect() {
        socket = WebSocket(url: URL(string: address)!)
        socket!.connect()
        socket!.onConnect = {
            NotificationCenter.default.post(name: .init("com.infnote.peer.connected"), object: nil)
        }
        socket!.onText = {
            for data in handleJSON(message: $0, sender: self) {
                self.socket!.write(data: data)
            }
        }
        socket!.onDisconnect = {
            print($0)
            NotificationCenter.default.post(name: .init("com.infnote.peer.disconnected"), object: nil)
        }
    }
    
    public func disconnect() {
        socket?.disconnect()
    }
}

public class PeerManager {
    
    public static var shared = PeerManager()
    
    public var allPeers: Results<Peer> {
        return database.objects(Peer.self).sorted(byKeyPath: "rank", ascending: false)
    }
    
    let database = try! Realm()
    
    private init() {}
    
    public func addOrUpdate(_ peer: Peer) {
        try! database.write {
            database.add(peer, update: true)
        }
    }
    
    public func getPeer(_ address: String) -> Peer? {
        return database.objects(Peer.self).filter("address == '\(address)'").first
    }
    
    public func remove(_ peer: Peer) {
        guard let real = getPeer(peer.address) else {
            return
        }
        try! database.write {
            database.delete(real)
        }
    }
}
