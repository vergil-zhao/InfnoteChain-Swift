//
//  Storage.swift
//  InfnoteChain
//
//  Created by Vergil Choi on 2018/9/28.
//

import Foundation
import RealmSwift


protocol Storage {
    func add(block: Block)
    func block(ofChain chain: Blockchain, byHeight height: Int) -> Block?
    func block(ofChain chain: Blockchain, byHash hash: String) -> Block?
    func height(ofChain chain: Blockchain) -> Int
}

class DatabaseStorage: Storage {
    private let database: Realm
    private var filterResultCache: [String: Results<Block>] = [:]
    
    init() {
        database = try! Realm()
        
        debugPrint("Realm is located at:", database.configuration.fileURL!)
    }
    
    func block(ofChain chain: Blockchain, byHeight height: Int) -> Block? {
        return database.objects(Block.self).filter("chainID = \(chain.id) AND height == \(height)").first
    }
    
    func block(ofChain chain: Blockchain, byHash hash: String) -> Block? {
        return database.objects(Block.self).filter("chainID = \(chain.id) AND blockHash == \(hash)").first
    }
    
    func height(ofChain chain: Blockchain) -> Int {
        if let result = filterResultCache[chain.id] {
            return result.count
        }
        
        filterResultCache[chain.id] = database.objects(Block.self).filter("chainID == \(chain.id)")
        return filterResultCache[chain.id]!.count
    }
    
    func add(block: Block) {
        try! database.write {
            database.add(block)
        }
    }
}

class Block: Object {
    
    // block hash is a hash value of minimized(no space), sorted-keys, uft8 content json data
    @objc dynamic var blockHash: Data   = Data()
    @objc dynamic var prevHash: Data    = Data()
    
    // it should be a timestamp when hashing
    @objc dynamic var time: Date        = Date()
    @objc dynamic var signature: Data   = Data()
    
    // chain id is base58 encoded public key of chain owner
    @objc dynamic var chainID: String   = ""
    @objc dynamic var height: Int       = 0
    
    // it also needs to be a minimized(no space), sorted-keys, uft8 content json data
    @objc dynamic var payload: Data     = Data()
    
    var isGenesis: Bool {
        return height == 0
    }
    
    var dict: [String: Any] {
        var dict = [
            "signature": signature.base58,
            "hash": blockHash.base58,
            "time": Int(time.timeIntervalSince1970),
            "chain_id": chainID,
            "height": height,
            "payload": String(data: payload, encoding: .utf8)
            ] as [String: Any]
        if !isGenesis {
            dict["prev_hash"] = prevHash.base58
        }
        return dict
    }
    
    var dataForHashing: Data {
        var dict = self.dict
        dict["hash"] = nil
        dict["signature"] = nil
        return try! JSONSerialization.data(withJSONObject: dict, options: .sortedKeys)
    }
    
    var data: Data {
        return try! JSONSerialization.data(withJSONObject: dict, options: .sortedKeys)
    }
    
    // TODO: validate dict
    convenience init(dict: [String: Any]) {
        self.init()
        
        blockHash = Data(base58: dict["hash"] as! String)!
        prevHash = Data(base58: dict["prev_hash"] as! String)!
        time = Date(timeIntervalSince1970: TimeInterval(dict["time"] as! Int))
        signature = Data(base58: dict["signature"] as! String)!
        chainID = dict["chain_id"] as! String
        height = dict["height"] as! Int
        payload = Data(base58: dict["payload"] as! String)!
        
    }
    
    override static func primaryKey() -> String? {
        return "blockHash"
    }
    
    override static func indexedProperties() -> [String] {
        return ["chainID", "height"]
    }
    
    override static func ignoredProperties() -> [String] {
        return ["chain"]
    }
    
    override var description: String {
        let jsonData = try! JSONSerialization.data(
            withJSONObject: dict,
            options: [.sortedKeys, .prettyPrinted])
        return String(data: jsonData, encoding: .utf8)!
    }
}

class KeyStorage {
    
    class KeyObject: Object {
        @objc dynamic var publicKey: String = ""
        @objc dynamic var privateKey: String? = nil
    }
    
    let database = try! Realm()
    
    var allKeys: [Key] {
        var keys: [Key] = []
        for object in database.objects(KeyObject.self) {
            if let sk = object.privateKey {
                keys.append(try! Key(privateKey: sk))
            }
            keys.append(try! Key(publicKey: object.publicKey))
        }
        return keys
    }
    
    func get(key pk: String) -> Key? {
        if let object = database.objects(KeyObject.self).filter("publicKey == '\(pk)'").first {
            if let sk = object.privateKey {
                return try! Key(privateKey: sk)
            }
            return try! Key(publicKey: object.publicKey)
        }
        return nil
    }
    
    func add(key: Key) {
        let object = KeyObject()
        object.publicKey = key.publicKey.base58
        object.privateKey = key.privateKey?.base58
        
        try! database.write {
            database.add(object)
        }
    }
}
