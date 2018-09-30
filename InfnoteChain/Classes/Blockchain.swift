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
    open let manager = ChainManager.shared
    
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
        return manager.height(ofChain: id)
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

        save()
    }
    
    open subscript(height: Int) -> Block? {
        return manager.block(ofChain: id, byHeight: height)
    }
    
    open subscript(hash: String) -> Block? {
        return manager.block(ofChain: id, byHash: hash)
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
        let storage = ChainManager.shared
        if storage.get(chain: id) == nil {
            storage.add(chain: self)
        }
    }
}
