//
//  Peer.swift
//  InfnoteChain
//
//  Created by Vergil Choi on 2018/10/4.
//

import Foundation
import RealmSwift
import Starscream


public class Peer: Object {
    
    @objc open dynamic var address: String = ""
    @objc open dynamic var port: Int = 80
    @objc open dynamic var rank: Int = 100
    
    var dispatcher: Dispatcher! = nil
    
    public override static func primaryKey() -> String? {
        return "address"
    }
    
    public convenience init?(address: String, port: Int = 80) {
        self.init()
        self.address = address
        self.port = port
        guard let socket = createSocket() else {
            return nil
        }
        self.dispatcher = Dispatcher(with: socket)
    }
    
    func createSocket() -> WebSocket? {
        guard let url = URL(string: "ws://\(address):\(port)") else {
            return nil
        }
        return WebSocket(url: url)
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
}
