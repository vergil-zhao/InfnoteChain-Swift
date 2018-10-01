//
//  ChainManager.swift
//  InfnoteChain
//
//  Created by Vergil Choi on 2018/9/30.
//

import Foundation
import RealmSwift

open class ChainManager {
    
    open static var shared = ChainManager()
    
    private let database = try! Realm()
    private var filterResultCache: [String: Results<Block>] = [:]
    
    private init() {}
    
    // MARK: - Chain operations
    
    open var allChains: Results<ChainObject> {
        return database.objects(ChainObject.self)
    }
    
    open func get(chain id: String) -> ChainObject? {
        return database.objects(ChainObject.self).filter("publicKey == '\(id)'").first
    }
    
    open func add(chain: Blockchain) {
        let object = ChainObject()
        object.publicKey = chain.key.publicKey.base58
        object.privateKey = chain.key.privateKey?.base58
        
        try! database.write {
            database.add(object)
        }
    }
    
    open func create(chain info: [String: Any]) -> Blockchain {
        let chain = Blockchain(key: try! Key())
        if let block = chain.createBlock(withPayload: try! JSONSerialization.data(withJSONObject: info, options: .sortedKeys)) {
            add(block: block)
        }
        return chain
    }
    
    open func remove(chain: ChainObject) {
        try! database.write {
            for block in database.objects(Block.self).filter("chainID == '\(chain.publicKey)'") {
                database.delete(block)
            }
            database.delete(chain)
        }
    }
    
    // MARK: - Block operations
    
    open func block(ofChain chainID: String, byHeight height: Int) -> Block? {
        return database.objects(Block.self).filter("chainID == '\(chainID)' AND height == \(height)").first
    }
    
    open func block(ofChain chainID: String, byHash hash: String) -> Block? {
        return database.objects(Block.self).filter("chainID == '\(chainID)' AND blockHash == '\(hash)'").first
    }
    
    open func height(ofChain chainID: String) -> Int {
        if let result = filterResultCache[chainID] {
            return result.count
        }
        
        filterResultCache[chainID] = database.objects(Block.self).filter("chainID == '\(chainID)'")
        return filterResultCache[chainID]!.count
    }
    
    open func add(block: Block) {
        let result = self.block(ofChain: block.chainID, byHeight: block.height)
        if block.isValid && result == nil {
            return
        }
        if block.height > 0, let prev = block.prev, prev.blockHash != block.prevHash {
            return
        }
        try! database.write {
            database.add(block)
        }
    }
    
    // MARK: - Debug
    
    open var storageFileURL: URL {
        print("Realm is located at:", database.configuration.fileURL!)
        return database.configuration.fileURL!
    }
}
