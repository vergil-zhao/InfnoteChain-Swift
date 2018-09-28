//
//  Blockchain.swift
//  InfnoteChain
//
//  Created by Vergil Choi on 2018/9/28.
//

import Foundation

class Blockchain {
    
    let key: Key
    let id: String
    let storage: Storage
    
    var height: Int {
        return storage.height(ofChain: self)
    }
    
    var isOwner: Bool {
        return key.canSign
    }
    
    class func create() -> Self {
        return self.init(key: try! Key())
    }
    
    convenience init(publicKey: String) {
        self.init(key: try! Key(publicKey: publicKey))
    }
    
    required init(key: Key) {
        self.key = key
        self.id = key.publicKey.base58
        
        storage = DatabaseStorage()
    }
    
    subscript(height: Int) -> Block? {
        return storage.block(ofChain: self, byHeight: height)
    }
    
    // TODO: check if data is a valid json
    func addSignedBlock(from data: Data) {
        addSignedBlock(from: try! JSONSerialization.jsonObject(with: data) as! [String: Any])
    }
    
    func addSignedBlock(from data: [String: Any]) {
        let block = Block(dict: data)
        addSignedBlock(block: block)
    }
    
    func addSignedBlock(block: Block) {
        if validate(block: block) && self[block.height] == nil {
            storage.add(block: block)
        }
    }
    
    func createBlock(withPayload payload: Data) -> Block? {
        if key.canSign {
            let block = Block()
            if height != 0 {
                block.prevHash = self[height - 1]!.blockHash
            }
            block.chainID = id
            block.height = height
            block.payload = payload
            block.blockHash = block.dataForHashing.sha256
            block.signature = try! key.sign(data: block.blockHash)
            return block
        }
        
        return nil
    }
    
    func validate(block: Block) -> Bool {
        return (block.height == 0 || block.prevHash != Data())
            && block.dataForHashing.sha256 == block.blockHash
            && key.verify(data: block.blockHash, signature: block.signature)
    }
}
