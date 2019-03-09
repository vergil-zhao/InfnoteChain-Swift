//
//  factory.swift
//  InfnoteChain
//
//  Created by Vergil Choi on 2019/1/29.
//

import Foundation

func handleJSON(message: String, sender: Peer) -> [Data] {
    guard let data = message.data(using: .utf8),
        let json = try? JSONSerialization.jsonObject(with: data, options: []),
        let dict = json as? [String: Any],
        let msg = Message(dict),
        let behavior = msg.behavior else {
        return []
    }
    
    if let broadcast = behavior as? BroadcastBlock {
        broadcast.id = msg.id
        broadcast.sender = sender
    }
    
    if let err = behavior.validate() {
        return [try! JSONSerialization.data(withJSONObject: err.dict(), options: [])]
    }
    
    return behavior.react()
        .map({Message(behavior: $0)})
        .map({try! JSONSerialization.data(withJSONObject: $0.dict, options: [])})
}
