//
//  Behaviors.swift
//  InfnoteChain
//
//  Created by Vergil Choi on 2019/1/29.
//

import Foundation

protocol Behavior {
    func validate() -> ErrorMessage?
    func react() -> [Behavior]
    func dict() -> [String: Any]
}

class Info: Behavior {
    var version: String = ""
    var peers: Int = 0
    var chains: [String: Int] = [:]
    var platform: [String: String] = [:]
    var fullNode: Bool = false
    
    init?(dict: [String: Any]) {
        guard let version = dict["version"] as? String,
            let peers = dict["peers"] as? Int,
            let chains = dict["chains"] as? [String: Int],
            let platform = dict["platform"] as? [String: String],
            let fullNode = dict["full_node"] as? Bool else {
                return nil
        }
        self.version = version
        self.peers = peers
        self.chains = chains
        self.platform = platform
        self.fullNode = fullNode
    }
    
    init() {
        var chains: [String: Int] = [:]
        
        self.version = "1.1"
        self.peers = 0
        self.chains = Storage.shared.getAllChains().reduce(chains, { (result: [String: Int], chain: Chain) in
            var r = result
            r[chain.id] = chain.count
            return r
        })
        self.platform = ["system": "iOS", "version": UIDevice.current.systemVersion]
        self.fullNode = false
    }
    
    func validate() -> ErrorMessage? {
        if version != "1.1" {
            return ErrorMessage(.IncompatibleProtocolVersion, "only accept v1.1 protocol")
        }
        
        if peers < 0 {
            return ErrorMessage(.BadRequest, "'peers' needs to be a non-negative number")
        }
        
        return nil
    }
    
    func react() -> [Behavior] {
        var behaviors: [Behavior] = []
        
        if peers > 0 {
            behaviors.append(RequestPeers(count: peers))
        }
        
        for (id, count) in chains {
            if let chain = Storage.shared.getChain(id: id), chain.maxCount < count {
                behaviors.append(RequestBlocks(chainID: id, from: chain.maxCount, to: count - 1))
            }
        }
        
        return behaviors
    }
    
    func dict() -> [String : Any] {
        return [
            "version": version,
            "peers": peers,
            "chains": chains,
            "platform": platform,
            "full_node": fullNode,
        ]
    }
}

class RequestPeers: Behavior {
    var count: Int = 0
    
    init?(dict: [String: Any]) {
        guard let count = dict["count"] as? Int else {
            return nil
        }
        self.count = count
    }
    
    init(count: Int) {
        self.count = count
    }
    
    func validate() -> ErrorMessage? {
        if count < 0 {
            return ErrorMessage(.BadRequest, "'count' needs to be a non-negative number")
        }
        
        return nil
    }
    
    func react() -> [Behavior] {
        let fetch = PeerManager.shared.allPeers
        let count = self.count > fetch.count ? fetch.count : self.count
        var peers: [String] = []
        for i in 0..<count {
            peers.append(fetch[i].address)
        }
        
        return [ResponsePeers(peers: peers)]
    }
    
    func dict() -> [String : Any] {
        return [
            "count": count
        ]
    }
}

class RequestBlocks: Behavior {
    var chainID: String = ""
    var from: Int = 0
    var to: Int = 0
    
    init?(dict: [String: Any]) {
        guard let chainID = dict["chain_id"] as? String,
            let from = dict["from"] as? Int,
            let to = dict["to"] as? Int else {
            return nil
        }
        
        self.chainID = chainID
        self.from = from
        self.to = to
    }
    
    init(chainID: String, from: Int, to: Int) {
        self.chainID = chainID
        self.from = from
        self.to = to
    }
    
    func validate() -> ErrorMessage? {
        guard let chain = Storage.shared.getChain(id: chainID) else {
            return ErrorMessage(.ChainNotAccept, chainID)
        }
        
        if from > to {
            return ErrorMessage(.BadRequest, "'from' must greater or equal 'to'")
        }
    
        if chain.maxCount < from {
            return ErrorMessage(.BadRequest, "request not existed blocks")
        }
        
        return nil
    }
    
    func react() -> [Behavior] {
        let chain = Storage.shared.getChain(id: chainID)!
        var size = 0
        var behaviors: [Behavior] = []
        var blocks: [[String: Any]] = []
        for i in from...to {
            guard let block = chain[Int(i)] else {
                continue
            }
            
            if block.size + size > 1024*1024 {
                behaviors.append(ResponseBlocks(blocks: blocks))
                blocks = [block.dict]
                size = block.size
            } else {
                blocks.append(block.dict)
            }
        }
        
        if blocks.count > 0 {
            behaviors.append(ResponseBlocks(blocks: blocks))
        }
        
        return behaviors
    }
    
    func dict() -> [String : Any] {
        return [
            "chain_id": chainID,
            "from": from,
            "to": to,
        ]
    }
}

class ResponsePeers: Behavior {
    var peers: [String] = []
    
    init?(dict: [String: Any]) {
        guard let peers = dict["peers"] as? [String] else {
            return nil
        }
        
        self.peers = peers
    }
    
    init(peers: [String]) {
        self.peers = peers
    }
    
    func validate() -> ErrorMessage? {
        for addr in peers {
            guard let url = URL(string: addr) else {
                return ErrorMessage(.InvalidURL, "failed to parse")
            }
            guard let scheme = url.scheme, scheme == "ws" || scheme == "wss" else {
                return ErrorMessage(.InvalidURL, "not a websocket URL")
            }
        }
        
        return nil
    }
    
    func react() -> [Behavior] {
        for addr in peers {
            PeerManager.shared.addOrUpdate(Peer(address: addr)!)
        }
        
        return []
    }
    
    func dict() -> [String : Any] {
        return [
            "peers": peers
        ]
    }
}

class ResponseBlocks: Behavior {
    var blocks: [[String: Any]] = []
    
    init?(dict: [String: Any]) {
        guard let blocks = dict["blocks"] as? [[String: Any]] else {
            return nil
        }
        
        self.blocks = blocks
    }
    
    init(blocks: [[String: Any]]) {
        self.blocks = blocks
    }
    
    func validate() -> ErrorMessage? {
        for info in blocks {
            guard let block = Block(dict: info), block.validate() else {
                return ErrorMessage(.BlockValidation, "invalid block")
            }
            
            guard let chain = Storage.shared.getChain(id: block.chainID) else {
                return ErrorMessage(.ChainNotAccept, "recovered chain ID: \(block.chainID)")
            }
        }
        
        return nil
    }
    
    func react() -> [Behavior] {
        for info in blocks {
            let block = Block(dict: info)!
            let chain = Storage.shared.getChain(id: block.chainID)!
            chain.save(block: block)
        }
        
        return []
    }
    
    func dict() -> [String : Any] {
        return [
            "blocks": blocks
        ]
    }
}

class BroadcastBlock: Behavior {
    var block: [String: Any] = [:]
    var id: String?
    var sender: Peer?
    
    private static var idCache: [String: Bool] = [:]
    static var callback: ((BroadcastBlock) -> Void)?
    
    init?(dict: [String: Any]) {
        guard let block = dict["block"] as? [String: Any] else {
            return nil
        }
        
        self.block = block
    }
    
    func validate() -> ErrorMessage? {
        guard let identifier = id else {
            return ErrorMessage(.InvalidBehavior, "missing broadcast id")
        }
        
        guard BroadcastBlock.idCache[identifier] == nil else {
            return ErrorMessage(.InvalidBehavior, "used broadcast id")
        }
        
        guard let block = Block(dict: block) else {
            return ErrorMessage(.JSONDecode, "invalid json data for block")
        }
        
        guard let chain = Storage.shared.getChain(id: block.chainID) else {
            return ErrorMessage(.ChainNotAccept, "recovered chain ID: \(block.chainID)")
        }
        
        guard chain.validate(block: block) else {
            return ErrorMessage(.BlockValidation, "invalid block")
        }
        
        return nil
    }
    
    func react() -> [Behavior] {
        let block = Block(dict: self.block)!
        let chain = Storage.shared.getChain(id: block.chainID)!
        chain.save(block: block)
        BroadcastBlock.idCache[id!] = true
        BroadcastBlock.callback?(self)
        
        return []
    }
    
    func dict() -> [String : Any] {
        return ["block": block]
    }
}
