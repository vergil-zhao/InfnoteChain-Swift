//
//  Blockchain.swift
//  InfnoteChain
//
//  Created by Vergil Choi on 2018/9/28.
//

import Foundation

open class Blockchain {
    
    open let key: Key
    open let id: String
    open let storage: Storage
    
    var _info: [String: Any]?
    open var info: [String: Any]? {
        if _info != nil {
            return _info
        }
        if let block = self[0], let info = try? JSONSerialization.jsonObject(with: block.payload, options: []) as? [String: Any] {
            _info = info
            return info
        }
        return nil
    }
    
    open var height: Int {
        return storage.height(ofChain: self)
    }
    
    open var isOwner: Bool {
        return key.canSign
    }
    
    public convenience init(publicKey: String) {
        self.init(key: try! Key(publicKey: publicKey))
    }
    
    required public init(key: Key) {
        self.key = key
        self.id = key.publicKey.base58
        
        storage = DatabaseStorage()
        save()
    }
    
    open subscript(height: Int) -> Block? {
        return storage.block(ofChain: self, byHeight: height)
    }
    
    open subscript(hash: String) -> Block? {
        return storage.block(ofChain: self, byHash: hash)
    }
    
    // TODO: check if data is a valid json
    open func addSignedBlock(from data: Data) {
        addSignedBlock(from: try! JSONSerialization.jsonObject(with: data) as! [String: Any])
    }
    
    open func addSignedBlock(from data: [String: Any]) {
        let block = Block(dict: data)
        addSignedBlock(block)
    }
    
    open func addSignedBlock(_ block: Block) {
        if validate(block: block) && self[block.height] == nil {
            storage.add(block: block)
        }
    }
    
    open func createBlock(withPayload payload: Data) -> Block? {
        if key.canSign {
            let block = Block()
            if height != 0 {
                block.prevHash = self[height - 1]!.blockHash
            }
            block.chainID = id
            block.height = height
            block.payload = payload
            block.blockHash = block.dataForHashing.sha256.base58
            block.signature = try! key.sign(base58Data: block.blockHash).base58
            return block
        }
        
        return nil
    }
    
    open func save() {
        let storage = ChainManager()
        if storage.get(chain: id) == nil {
            storage.add(chain: self)
        }
    }
    
    open func validate(block: Block) -> Bool {
        return (block.height == 0 || !block.prevHash.isEmpty)
            && block.dataForHashing.sha256.base58 == block.blockHash
            && key.verify(base58Data: block.blockHash, signture: block.signature)
    }
}
