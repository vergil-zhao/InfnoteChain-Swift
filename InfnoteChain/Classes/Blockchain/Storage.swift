//
//  Storage.swift
//  InfnoteChain
//
//  Created by Vergil Choi on 2019/1/28.
//

import Foundation
import RealmSwift

public class Storage {
    public static var shared = Storage()
    
    private var database = try! Realm()
    
    public var fileURL: URL {
        return database.configuration.fileURL!
    }
    
    private init() {}
    
    public func getChain(id: String) -> Chain? {
        return database.objects(Chain.self).filter("id = '\(id)'").first
    }
    
    public func getAllChains() -> [Chain] {
        return database.objects(Chain.self).reduce([], {$0 + [$1]})
    }
    
    public func getBlockCount(id: String) -> Int {
        return database.objects(Block.self).filter("chainID = '\(id)'").count
    }
    
    public func getBlock(id: String, height: Int) -> Block? {
        return database.objects(Block.self).filter("chainID = '\(id)' AND height = \(height)").first
    }
    
    public func getBlockByHash(id: String, hash: String) -> Block? {
        return database.objects(Block.self).filter("chainID = '\(id)' AND blockHash = '\(hash)'").first
    }
    
    public func getBlocks(id: String, from: UInt64, to: Int) -> [Block] {
        return database.objects(Block.self).filter("chainID = '\(id)' AND height >= \(from) AND height <= \(to)").reduce([], {$0 + [$1]})
    }
    
    public func save(chain: Chain) {
        try! database.write {
            database.add(chain)
        }
    }
    
    public func save(block: Block) {
        try! database.write {
            database.add(block)
            getChain(id: block.chainID)?.maxCount += 1
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "[HH:mm:ss.SSS]"
        let time = dateFormatter.string(from: Date())
        print("\(time) new block saved")
    }
    
    public func clean(chain: Chain) {
        try! database.write {
            database.delete(database.objects(Block.self).filter("chainID = '\(chain.id)'"))
            database.delete(chain)
        }
    }
}
