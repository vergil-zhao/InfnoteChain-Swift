//
//  ShareManager.swift
//  InfnoteChain
//
//  Created by Vergil Choi on 2018/10/9.
//

import Foundation

public class ShareManager {
    public static var shared = ShareManager()
    public var maxPeers = 10 {
        didSet {
            self.refresh()
        }
    }
    
    var peers: [Peer] = []
    var spreadCache: [String] = []
    
    private init() {}
    
    public func sharing() {
        connect()
        // TODO: Refresh every n seconds
    }
    
    func refresh() {
        peers.forEach { peer in
            self.sendInfo(to: Connection(peer))
        }
        
        let newPeers = Array(PeerManager.shared.allPeers.prefix(maxPeers).suffix(maxPeers - peers.count))
            .filter { $0.createDispatcher() }
        newPeers.forEach { self.connect(to: $0) }
        peers.append(contentsOf: newPeers)
    }
    
    func connect() {
        peers = Array(PeerManager.shared.allPeers.prefix(maxPeers))
            .filter { $0.createDispatcher() }
            
        peers.forEach { self.connect(to: $0) }
    }
    
    func connect(to peer: Peer) {
        let conn = Connection(peer)
        conn.handled(by: ConnectionObserver
            .onConnected { conn in
                print("[Connected   ] \(peer.address):\(peer.port)")
                self.sendInfo(to: conn)
            }
            .onDisconnected { error, conn in
                print("[Disconnected] \(peer.address):\(peer.port)")
                if let e = error {
                    print(e)
                }
                _ = self.peers.remove(at: self.peers.firstIndex(of: peer)!)
            })
            .connect()
        
        peer.dispatcher.globalHandler = { message in
            self.answer(question: message, for: conn)
        }
    }
    
    func answer(question: Message, for conn: Connection) {
        guard let sentence = Speaking.create(from: question) else {
            self.unexpected(question)
            return
        }

        switch sentence.type {
        case .wantBlocks:
            let wantBlocks = sentence as! Speaking.WantBlocks
            let blocks = Speaking.Blocks()
            blocks.blocks = ChainManager.shared.blocks(ofChain: wantBlocks.chainID, from: wantBlocks.from, to: wantBlocks.to)
            Courier.bring(blocks.answer(for: question)).send(through: conn)
        case .wantPeers:
            let wantPeers = sentence as! Speaking.WantPeers
            let peers = Speaking.Peers()
            peers.peers = Array(PeerManager.shared.allPeers.prefix(wantPeers.count))
            Courier.bring(peers.answer(for: question)).send(through: conn)
        case .newBlock:
            let newBlock = sentence as! Speaking.NewBlock
            spread(sentence: newBlock, except: conn.peer)
        default:
            self.unexpected(question)
        }
    }
    
    func sendInfo(to conn: Connection) {
        let info = Speaking.Info()
        // TODO: Assign current information
        let message = info.question
        Courier.bring(message).send(through: conn).handled(by: CourierObserver
            .onResponse { message in
                guard let info = Speaking.create(from: message) as? Speaking.Info else {
                    self.unexpected(message)
                    return
                }
                self.peersStrategy(info, for: conn)
                self.chainsStrategy(info, for: conn)
            }
        )
    }
    
    func spread(sentence: Speaking.NewBlock, except: Peer) {
        guard spreadCache.firstIndex(of: sentence.message!.identifier) == nil else {
            return
        }
        peers.forEach { peer in
            guard peer != except else {
                return
            }
            Courier.bring(sentence.question).send(through: Connection(peer))
        }
        spreadCache.append(sentence.message!.identifier)
    }
    
    // TEMP: save all peers server has
    func peersStrategy(_ info: Speaking.Info, for conn: Connection) {
        guard info.peers > 0 else {
            return
        }
        
        let wantPeers = Speaking.WantPeers()
        wantPeers.count = info.peers
        Courier.bring(wantPeers.question).send(through: conn).handled(by: CourierObserver
            .onResponse { message in
                guard let peers = Speaking.create(from: message) as? Speaking.Peers else {
                    self.unexpected(message)
                    return
                }
                peers.peers.forEach { PeerManager.shared.addOrUpdate($0) }
            }
        )
    }
    
    // TEMP: save all chains and blocks server has
    func chainsStrategy(_ info: Speaking.Info, for conn: Connection) {
        guard info.chains.count > 0 else {
            return
        }
        
        info.chains.forEach { args in
            let wantBlocks = Speaking.WantBlocks()
            wantBlocks.chainID = args.key
            wantBlocks.from = 0
            
            if let chain = ChainManager.shared.get(chain: args.key)?.chain {
                let height = chain.height
                if height < args.value {
                    wantBlocks.from = height
                }
                else {
                    return
                }
            }
            else {
                Blockchain(publicKey: args.key).save()
            }
            wantBlocks.to = args.value - 1
            
            Courier.bring(wantBlocks.question).send(through: conn).handled(by: CourierObserver
                .onResponse { message in
                    guard let blocks = Speaking.create(from: message) as? Speaking.Blocks else {
                        self.unexpected(message)
                        return
                    }
                    blocks.blocks.forEach { ChainManager.shared.add(block: $0) }
                }
            )
        }
    }
    
    func unexpected(_ message: Message) {
        print(message)
    }
    
    func rank(peers: [Peer]) {
        // TODO: test peers to give a rank to every peer
        // 1. Could connect to the peer or not (0)
        // 2. How much time needed to receive a pong after sending a ping (1-100)
        // 3. Request a random block, test if it is valid or not (0)
        // ...
    }
}