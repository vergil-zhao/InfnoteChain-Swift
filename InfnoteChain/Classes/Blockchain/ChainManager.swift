//
//  ChainManager.swift
//  InfnoteChain
//
//  Created by Vergil Choi on 2018/9/30.
//

import Foundation
import RealmSwift

open class ChainManager {
    
    public static var shared = ChainManager()
    
    private let database = try! Realm()
    private var filterResultCache: [String: Results<Block>] = [:]
    private let lock = NSLock()
    
    private init() {
        print(database.configuration.fileURL)
    }
    
    // MARK: - Chain operations
    
    open var allChains: Results<ChainObject> {
        return database.objects(ChainObject.self)
    }
    
    open func get(chain id: String) -> ChainObject? {
        return database.objects(ChainObject.self).filter("publicKey == '\(id)'").first
    }
    
    open func add(chain: Blockchain) {
        let object = ChainObject()
        object.publicKey = chain.key.compressedPublicKey.base58
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
    
    open func blocks(ofChain chainID: String, from: Int, to: Int) -> [Block] {
        return Array(database
            .objects(Block.self)
            .filter("chainID == '\(chainID)' AND height >= \(from) AND height <= \(to)")
        )
    }
    
    open func height(ofChain chainID: String) -> Int {
        if let result = filterResultCache[chainID] {
            return result.count
        }
        
        filterResultCache[chainID] = database.objects(Block.self).filter("chainID == '\(chainID)'")
        return filterResultCache[chainID]!.count
    }
    
    open func add(block: Block) {
        self.lock.lock()
        let result = self.block(ofChain: block.chainID, byHeight: block.height)
        guard block.isValid && result == nil else {
            self.lock.unlock()
            return
        }
        if block.height > 0, let prev = block.prev, prev.blockHash != block.prevHash {
            self.lock.unlock()
            return
        }
        try! database.write {
            database.add(block)
        }
        // TODO: send a global notification
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss,SSS"
        print("[\(formatter.string(from: now))] New valid block saved: \(block.blockHash)")
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "InfnoteChain.Block.Saved"), object: block)
        self.lock.unlock()
    }
    
    // MARK: - Debug
    
    open var storageFileURL: URL {
        print("Realm is located at:", database.configuration.fileURL!)
        return database.configuration.fileURL!
    }
}
