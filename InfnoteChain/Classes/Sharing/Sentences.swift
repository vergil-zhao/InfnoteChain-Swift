//
//  Command.swift
//  InfnoteChain
//
//  Created by Vergil Choi on 2018/10/9.
//

import Foundation

public class Speaking {
    public enum Kind: String {
        case info       = "info"
        case error      = "error"
        case wantPeers  = "want_peers"
        case peers      = "peers"
        case wantBlocks = "want_blocks"
        case blocks     = "blocks"
        case newBlock   = "new_block"
    }
    
    public class Sentence: CustomStringConvertible {
        // original message
        public var message: Message? = nil
        
        var type: Kind {
            fatalError("Should not call \(#function) from class: \(String(describing: self))")
        }
        var dict: [String: Any] {
            return ["type": type.rawValue]
        }
        
        public var broadcast: Message {
            if let message = self.message {
                return Message(type: .broadcast, identifier: message.identifier, content: dict)
            }
            return Message(type: .broadcast, identifier: nil, content: dict)
        }
        
        // create a question type of message
        public var question: Message {
            return Message(
                type: .question,
                identifier: nil,
                content: dict
            )
        }
        
        // create a answer type of message
        public func answer(for question: Message) -> Message {
            return Message(
                type: type == .error ? .error : .answer,
                identifier: question.identifier,
                content: dict
            )
        }
        
        public var description: String {
            let maxWidth = dict.reduce(0) { $1.key.count > $0 ? $1.key.count : $0 }
            return dict.reduce("") {
                let spaces = String(repeating: " ", count: maxWidth - $1.key.count)
                let content = String(describing: $1.value)
                return $0 + "[\($1.key)\(spaces)] \(content)\n"
            }
        }
    }
    
    public class Info: Sentence {
        public override var type: Kind { return .info }
        public var version = "0.1"
        public var peers = 0
        public var chains: [String: Int] = [:]
        public var platform: [String: String] = [
            "system": UIDevice.current.systemName,
            "version": UIDevice.current.systemVersion,
            "node": UIDevice.current.name,
        ]
        public var isFullNode = false
        
        override var dict: [String: Any] {
            return super.dict + [
                "version": version,
                "peers": peers,
                "chains": chains,
                "platform": platform,
                "full_node": isFullNode
            ]
        }
        
        public convenience init?(with dict:[String: Any]) {
            guard let version = dict["version"] as? String,
                let peers = dict["peers"] as? Int,
                let chains = dict["chains"] as? [String: Int],
                let platform = dict["platform"] as? [String: String],
                let isFullNode = dict["full_node"] as? Bool else {
                    return nil
            }
            self.init()
            self.version = version
            self.peers = peers
            self.chains = chains
            self.platform = platform
            self.isFullNode = isFullNode
        }
        
        override init() {
            super.init()
            peers = PeerManager.shared.allPeers.count
            let chains = Array<Blockchain>(ChainManager.shared.allChains.map { $0.chain })
            for chain in chains {
                self.chains[chain.id] = chain.height
            }
        }
    }
    
    public class Error: Sentence {
        public override var type: Kind { return .error }
        public var code = 0
        public var desc = ""
        
        override var dict: [String: Any] {
            return super.dict + [
                "code": code,
                "desc": desc
            ]
        }
        
        public convenience init?(with dict:[String: Any]) {
            guard let code = dict["code"] as? Int,
                let desc = dict["desc"] as? String else {
                    return nil
            }
            self.init()
            self.code = code
            self.desc = desc
        }
    }
    
    public class WantPeers: Sentence {
        public override var type: Kind { return .wantPeers }
        public var count = 0
        
        override var dict: [String: Any] {
            return super.dict + [
                "count": count
            ]
        }
        
        public convenience init?(with dict:[String: Any]) {
            guard let count = dict["count"] as? Int else {
                return nil
            }
            self.init()
            self.count = count
        }
    }
    
    public class Peers: Sentence {
        public override var type: Kind { return .peers }
        public var peers: [Peer] = []
        
        override var dict: [String: Any] {
            return super.dict + [
                "peers": peers.map { $0.dict }
            ]
        }
        
        public convenience init?(with dict:[String: Any]) {
            guard let peers = dict["peers"] as? [[String: Any]] else {
                return nil
            }
            self.init()
            for dict in peers {
                if let address = dict["address"] as? String,
                    let port = dict["port"] as? Int,
                    let peer = Peer(address: address, port: port) {
                    self.peers.append(peer)
                }
            }
        }
    }
    
    public class WantBlocks: Sentence {
        public override var type: Kind { return .wantBlocks }
        public var chainID = ""
        public var from = 0
        public var to = 0
        
        override var dict: [String: Any] {
            return super.dict + [
                "chain_id": chainID,
                "from": from,
                "to": to
            ]
        }
        
        public convenience init?(with dict:[String: Any]) {
            guard let chainID = dict["chain_id"] as? String,
                let from = dict["from"] as? Int,
                let to = dict["to"] as? Int else {
                return nil
            }
            self.init()
            self.chainID = chainID
            self.from = from
            self.to = to
        }
    }
    
    public class Blocks: Sentence {
        public override var type: Kind { return .blocks }
        public var blocks: [Block] = []
        
        override var dict: [String: Any] {
            return super.dict + [
                "blocks": blocks.map { $0.dict }
            ]
        }
        
        public convenience init?(with dict:[String: Any]) {
            guard let blocks = dict["blocks"] as? [[String: Any]] else {
                return nil
            }
            self.init()
            for dict in blocks {
                if let block = Block(dict: dict) {
                    self.blocks.append(block)
                }
            }
        }
    }
    
    public class NewBlock: Sentence {
        public override var type: Kind { return .newBlock }
        public var chainID = ""
        public var height = 0
        
        override var dict: [String: Any] {
            return super.dict + [
                "chain_id": chainID,
                "height": height
            ]
        }
        
        public convenience init?(with dict:[String: Any]) {
            guard let chainID = dict["chain_id"] as? String,
                let height = dict["height"] as? Int else {
                return nil
            }
            self.init()
            self.chainID = chainID
            self.height = height
        }
    }
    
    public class func create(from message: Message) -> Sentence? {
        guard let content = message.content,
            let type = content["type"] as? String,
            let kind = Kind(rawValue: type),
            let sentence = self.create(with: kind, content: content) else {
                return nil
        }
        sentence.message = message
        return sentence
    }
    
    class func create(with type: Kind, content: [String: Any]) -> Sentence? {
        switch type {
        case .info:
            return Info(with: content)
        case .error:
            return Error(with: content)
        case .wantPeers:
            return WantPeers(with: content)
        case .peers:
            return Peers(with: content)
        case .wantBlocks:
            return WantBlocks(with: content)
        case .blocks:
            return Blocks(with: content)
        case .newBlock:
            return NewBlock(with: content)
        }
    }
}

func + <K, V> (left: [K: V], right: [K: V]) -> [K: V] {
    return left.merging(right) { $1 }
}

func += <K, V> (left: inout [K: V], right: [K: V]) {
    left.merge(right) { $1 }
}

