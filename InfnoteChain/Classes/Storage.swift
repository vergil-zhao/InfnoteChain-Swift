//
//  Storage.swift
//  InfnoteChain
//
//  Created by Vergil Choi on 2018/9/28.
//

import Foundation
import RealmSwift


public protocol Storage {
    func add(block: Block)
    func block(ofChain chain: Blockchain, byHeight height: Int) -> Block?
    func block(ofChain chain: Blockchain, byHash hash: String) -> Block?
    func height(ofChain chain: Blockchain) -> Int
}

open class DatabaseStorage: Storage {
    private let database: Realm
    private var filterResultCache: [String: Results<Block>] = [:]
    
    init() {
        database = try! Realm()
        
        print("Realm is located at:", database.configuration.fileURL!)
    }
    
    open func block(ofChain chain: Blockchain, byHeight height: Int) -> Block? {
        return database.objects(Block.self).filter("chainID == '\(chain.id)' AND height == \(height)").first
    }
    
    open func block(ofChain chain: Blockchain, byHash hash: String) -> Block? {
        return database.objects(Block.self).filter("chainID == '\(chain.id)' AND blockHash == '\(hash)'").first
    }
    
    open func height(ofChain chain: Blockchain) -> Int {
        if let result = filterResultCache[chain.id] {
            return result.count
        }
        
        filterResultCache[chain.id] = database.objects(Block.self).filter("chainID == '\(chain.id)'")
        return filterResultCache[chain.id]!.count
    }
    
    open func add(block: Block) {
        try! database.write {
            database.add(block)
        }
    }
}

open class Block: Object {
    
    // block hash is a hash value of minimized(no space), sorted-keys, uft8 content json data
    @objc dynamic var blockHash: String   = ""
    @objc dynamic var prevHash: String    = ""
    
    // it should be a timestamp when hashing
    @objc dynamic var time: Date        = Date()
    @objc dynamic var signature: String   = ""
    
    // chain id is base58 encoded public key of chain owner
    @objc dynamic var chainID: String   = ""
    @objc dynamic var height: Int       = 0
    
    // it also needs to be a minimized(no space), sorted-keys, uft8 content json data
    @objc dynamic var payload: Data     = Data()
    
    open var isGenesis: Bool {
        return height == 0
    }
    
    open var dict: [String: Any] {
        var dict = [
            "signature": signature,
            "hash": blockHash,
            "time": Int(time.timeIntervalSince1970),
            "chain_id": chainID,
            "height": height,
            "payload": String(data: payload, encoding: .utf8)
            ] as [String: Any]
        if !isGenesis {
            dict["prev_hash"] = prevHash
        }
        return dict
    }
    
    open var dataForHashing: Data {
        var dict = self.dict
        dict["hash"] = nil
        dict["signature"] = nil
        return try! JSONSerialization.data(withJSONObject: dict, options: .sortedKeys)
    }
    
    open var data: Data {
        return try! JSONSerialization.data(withJSONObject: dict, options: .sortedKeys)
    }
    
    // TODO: validate dict
    convenience init(dict: [String: Any]) {
        self.init()
        
        blockHash = dict["hash"] as! String
        prevHash = dict["prev_hash"] as! String
        time = Date(timeIntervalSince1970: TimeInterval(dict["time"] as! Int))
        signature = dict["signature"] as! String
        chainID = dict["chain_id"] as! String
        height = dict["height"] as! Int
        payload = Data(base58: dict["payload"] as! String)!
    }
    
    override open static func primaryKey() -> String? {
        return "blockHash"
    }
    
    override open static func indexedProperties() -> [String] {
        return ["chainID", "height"]
    }
    
    override open var description: String {
        let jsonData = try! JSONSerialization.data(
            withJSONObject: dict,
            options: [.sortedKeys, .prettyPrinted])
        return String(data: jsonData, encoding: .utf8)!
    }
}

open class ChainObject: Object {
    @objc dynamic var publicKey: String = ""
    @objc dynamic var privateKey: String? = nil
    
    open var key: Key {
        if let sk = privateKey {
            return try! Key(privateKey: sk)
        }
        return try! Key(publicKey: publicKey)
    }
    
    open var chain: Blockchain {
        return Blockchain(key: key)
    }
    
    override open static func primaryKey() -> String? {
        return "publicKey"
    }
}

open class ChainManager {
    
    let database = try! Realm()
    
    public init() {}
    
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
            chain.addSignedBlock(block)
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
}
