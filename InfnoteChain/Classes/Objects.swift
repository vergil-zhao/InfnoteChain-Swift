//
//  Storage.swift
//  InfnoteChain
//
//  Created by Vergil Choi on 2018/9/28.
//

import Foundation
import RealmSwift

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
    
    override open var description: String {
        var dict = ["public_key": publicKey]
        if let sk = privateKey {
            dict["private_key"] = sk
        }
        let jsonData = try! JSONSerialization.data(
            withJSONObject: dict,
            options: [.sortedKeys, .prettyPrinted])
        return String(data: jsonData, encoding: .utf8)!
    }
}

open class Block: Object {
    
    // block hash is a hash value of minimized(no space), sorted-keys, uft8 content json data
    @objc public dynamic var blockHash: String   = ""
    @objc public dynamic var prevHash: String    = ""
    
    // it should be a timestamp when hashing
    @objc public dynamic var time: Date          = Date()
    @objc public dynamic var signature: String   = ""
    
    // chain id is base58 encoded public key of chain owner
    @objc public dynamic var chainID: String   = ""
    @objc public dynamic var height: Int       = 0
    
    // it also needs to be a minimized(no space), sorted-keys, uft8 content json data
    @objc public dynamic var payload: Data     = Data()
    
    open var isGenesis: Bool {
        return height == 0
    }
    
    open var prev: Block? {
        return ChainManager.shared.block(ofChain: chainID, byHeight: height - 1)
    }
    
    open var next: Block? {
        return ChainManager.shared.block(ofChain: chainID, byHeight: height + 1)
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
    
    open var isValid: Bool {
        let key = try! Key(publicKey: chainID)
        return (height == 0 || !prevHash.isEmpty)
            && dataForHashing.sha256.base58 == blockHash
            && key.verify(base58Data: blockHash, signture: signature)
    }
    
    // TODO: check data
    public convenience init(jsonData data: Data) {
        self.init(dict: try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any])
    }
    
    // TODO: validate dict
    public convenience init(dict: [String: Any]) {
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
