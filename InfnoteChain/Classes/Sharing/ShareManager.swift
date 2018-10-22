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
    
    public var peers: [Peer] = []
    var spreadCache: [String] = []
    
    private init() {}
    
    public func sharing() {
//        connect()
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
        let peers = Array(PeerManager.shared.allPeers.prefix(maxPeers))
        peers.forEach { self.connect(to: $0) }
    }
    
    public func isConnected(with peer: Peer) -> Bool {
        var flag = false
        for p in peers {
            if p == peer {
                flag = true
            }
        }
        return flag
    }
    
    public func connect(to peer: Peer) {
        guard peer.createDispatcher() else {
            return
        }
        let conn = Connection(peer)
        conn.handled(by: ConnectionObserver
            .onConnected { conn in
                print("[Connected] \(peer.address):\(peer.port)")
                self.peers.append(peer)
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "InfnoteChain.Peer.Connected"), object: peer)
                self.sendInfo(to: conn)
            }
            .onDisconnected { error, conn in
                print("[Disconnected] \(peer.address):\(peer.port)")
                if let e = error {
                    print(e)
                }
                if let index = self.peers.firstIndex(of: peer) {
                    _ = self.peers.remove(at: index)
                }
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "InfnoteChain.Peer.Disconnected"), object: peer)
            })
            .connect()
        
        peer.dispatcher.globalHandler = { message in
            self.answer(question: message, for: conn)
        }
    }
    
    public func disconnect(to peer: Peer) {
        for p in peers {
            if p == peer {
                p.dispatcher.socket.disconnect()
            }
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
            sendBlocks(with: wantBlocks, to: conn)
        case .wantPeers:
            let wantPeers = sentence as! Speaking.WantPeers
            let peers = Speaking.Peers()
            peers.peers = Array(PeerManager.shared.allPeers.prefix(wantPeers.count))
            Courier.bring(peers.answer(for: question)).send(through: conn)
        case .newBlock:
            let newBlock = sentence as! Speaking.NewBlock
            if let chain = ChainManager.shared.get(chain: newBlock.chainID)?.chain {
                if chain.height < newBlock.height {
                    getBlock(from: conn, of: chain.id, from: chain.height, to: newBlock.height - 1) {
                        self.broadcast(sentence: newBlock, except: conn.peer)
                    }
                }
            }
            else {
                Blockchain(publicKey: newBlock.chainID).save()
                getBlock(from: conn, of: newBlock.chainID, from: 0, to: newBlock.height - 1) {
                    self.broadcast(sentence: newBlock, except: conn.peer)
                }
            }
        case .blocks:
            let blocks = sentence as! Speaking.Blocks
            blocks.blocks.forEach { ChainManager.shared.add(block: $0) }
            
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
                    return true
                }
                self.peersStrategy(info, for: conn)
                self.chainsStrategy(info, for: conn)
                return true
            }
        )
    }
    
    func broadcast(sentence: Speaking.NewBlock, except: Peer?) {
        if let message = sentence.message, spreadCache.firstIndex(of: message.identifier) != nil {
            return
        }
        let msg = sentence.broadcast
        spreadCache.append(msg.identifier)
        peers.forEach { peer in
            if let e = except, peer == e {
                return
            }
            Courier.bring(msg).send(through: Connection(peer))
        }
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
                    return true
                }
                peers.peers.forEach { PeerManager.shared.addOrUpdate($0) }
                return true
            }
        )
    }
    
    // TEMP: save all chains and blocks server has
    func chainsStrategy(_ info: Speaking.Info, for conn: Connection) {
        guard info.chains.count > 0 else {
            return
        }
        
        info.chains.forEach { args in
            if args.value <= 0 {
                return
            }
            
            var start = 0
            if let chain = ChainManager.shared.get(chain: args.key)?.chain {
                let height = chain.height
                if height < args.value {
                    start = height
                }
                else {
                    return
                }
            }
            else {
                Blockchain(publicKey: args.key).save()
            }
            
            let end = args.value - 1
            
            self.getBlock(from: conn, of: args.key, from: start, to: end)
        }
    }
    
    // TODO: should collect all servers info before fetching blocks
    func getBlock(from conn: Connection, of chainID: String, from: Int, to: Int, complete: (() -> Void)? = nil) {
        let wantBlocks = Speaking.WantBlocks()
        wantBlocks.chainID = chainID
        wantBlocks.from = from
        wantBlocks.to = to
        
        Courier.bring(wantBlocks.question).send(through: conn).handled(by: CourierObserver
            .onResponse { message in
                guard let blocks = Speaking.create(from: message) as? Speaking.Blocks else {
                    self.unexpected(message)
                    return true
                }
                blocks.blocks.forEach { ChainManager.shared.add(block: $0) }
                if blocks.end {
                    complete?()
                }
                return blocks.end
            }
        )
    }
    
    func sendBlocks(with wantBlocks: Speaking.WantBlocks, to conn: Connection) {
        let blocks = ChainManager.shared.blocks(ofChain: wantBlocks.chainID, from: wantBlocks.from, to: wantBlocks.to)
        var size = 0
        var tmp: [Block] = []
        var result: [Speaking.Blocks] = []
        for block in blocks {
            if size + block.size > Int(Double(1 >> 20) * 1.5) {
                Courier.bring(Speaking.Blocks(tmp, end: false).answer(for: wantBlocks.message!)).send(through: conn)
                tmp = [block]
                size = 0
            }
            else {
                size += block.size
                tmp.append(block)
            }
        }
        if !tmp.isEmpty {
            Courier.bring(Speaking.Blocks(tmp, end: false).answer(for: wantBlocks.message!)).send(through: conn)
        }
    }
    
    func unexpected(_ message: Message) {
        print("Got unexpected message:")
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
