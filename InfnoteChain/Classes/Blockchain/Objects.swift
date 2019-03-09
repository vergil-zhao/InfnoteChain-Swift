//
//  Storage.swift
//  InfnoteChain
//
//  Created by Vergil Choi on 2018/9/28.
//

import Foundation
import RealmSwift

public class Chain: Object {
    @objc public dynamic var id: String = ""
    @objc public dynamic var wif: String? = nil
    @objc public dynamic var maxCount: Int = 0
    
    public var count: Int {
        return Storage.shared.getBlockCount(id: id)
    }
    
    open var key: Key? {
        if let sk = wif, let key = Key(wif: sk) {
            return key
        }
        return nil
    }
    
    override open static func primaryKey() -> String? {
        return "id"
    }
    
    public func validate(block: Block) -> Bool {
        return block.validate() && block.chainID == id
    }
    
    public subscript(height: Int) -> Block? {
        return Storage.shared.getBlock(id: id, height: height)
    }
    
    public func save(block: Block) {
        if validate(block: block) {
            Storage.shared.save(block: block)
        }
        NotificationCenter.default.post(name: .init("com.infnote.block.saved"), object: nil)
    }
    
    public func save() {
        Storage.shared.save(chain: self)
    }
    
    override open var description: String {
        var dict = ["chain_id": id]
        if let sk = wif {
            dict["wif"] = sk
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
    @objc public dynamic var time: Int           = 0
    @objc public dynamic var signature: String   = ""
    
    // chain id is base58 encoded public key of chain owner
    @objc public dynamic var chainID: String   = ""
    @objc public dynamic var height: Int       = 0
    
    // it also needs to be a minimized(no space), sorted-keys, uft8 content json data
    @objc public dynamic var payload: Data     = Data()
    
    open var isGenesis: Bool {
        return height == 0
    }
    
    open var dict: [String: Any] {
        var dict = [
            "signature": signature,
            "hash": blockHash,
            "time": time,
            "height": height,
            "payload": payload.base64EncodedString()
            ] as [String: Any]
        if !isGenesis {
            dict["prev_hash"] = prevHash
        }
        return dict
    }
    
    open var dataForHashing: Data {
        let pre = "\(height)\(time)".data(using: .ascii)!
        if prevHash.count > 0 {
            return pre + Base58.decode(prevHash)! + payload
        }
        return pre + payload
    }
    
    open var size: Int {
        return payload.count
    }
    
    public func validate() -> Bool {
        let chainID = Key.recover(signature: Data(base58: signature)!, message: dataForHashing)
        return (height == 0 || !prevHash.isEmpty)
            && dataForHashing.sha256.base58 == blockHash
            && chainID.count > 0
    }
    
    public convenience init?(jsonData data: Data) {
        guard let t = try? JSONSerialization.jsonObject(with: data, options: []),
            let json = t as? [String: Any] else {
            return nil
        }
        self.init(dict: json)
    }
    
    public convenience init?(dict: [String: Any]) {
        self.init()
        
        guard let blockHash = dict["hash"] as? String,
            let time = dict["time"] as? Int,
            let signature = dict["signature"] as? String,
            let height = dict["height"] as? Int,
            let encoded = dict["payload"] as? String,
            let payload = Data(base64Encoded: encoded) else {
            return nil
        }
        
        self.blockHash = blockHash
        self.prevHash = dict["prev_hash"] as? String ?? ""
        self.time = time
        self.signature = signature
        self.height = height
        self.payload = payload
        self.chainID = Key.recover(signature: Data(base58: signature)!, message: dataForHashing)
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
