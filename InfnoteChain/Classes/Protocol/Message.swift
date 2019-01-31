//
//  Message.swift
//  InfnoteChain
//
//  Created by Vergil Choi on 2018/10/8.
//

import Foundation


public class Message: CustomStringConvertible {
    
    public var id: String = ""
    public var type: String = ""
    public var data: [String: Any] = [:]
    
    public var dict: [String: Any] {
        var basic = [
            "id": id,
            "type": type
        ] as [String: Any]
        if data != nil {
            basic["data"] = data
        }
        return basic
    }
    
    public var json: String {
        return try! JSONSerialization.data(withJSONObject: dict, options: []).utf8!
    }
    
    var behavior: Behavior? {
        var b: Behavior? = nil
        
        switch type {
        case "info":
            b = Info(dict: data)
        case "error":
            b = ErrorMessage(dict: data)
        case "request:peers":
            b = RequestPeers(dict: data)
        case "request:blocks":
            b = RequestBlocks(dict: data)
        case "response:peers":
            b = ResponsePeers(dict: data)
        case "response:blocks":
            b = ResponseBlocks(dict: data)
        case "broadcast:block":
            b = BroadcastBlock(dict: data)
        default:
            b = nil
        }
        
        return b
    }
    
    public init?(_ dict: [String: Any]) {
        guard let identifier = dict["id"] as? String,
            let type = dict["type"] as? String else {
            return nil
        }
        
        self.id = identifier
        self.type = type
        
        if let data = dict["data"] as? [String: Any] {
            self.data = data
        }
    }
    
    public init(type: String, content: [String: Any], identifier: String? = nil) {
        self.id = identifier ?? String.random(10, dictionary: .characters + .digits)
        self.type = type
        self.data = content
    }
    
    init(behavior: Behavior) {
        self.type = "\(Mirror(reflecting: behavior).subjectType)"
        
        let matchFirst = try! NSRegularExpression(pattern: "(.)([A-Z][a-z]+)", options: [])
        let matchAll = try! NSRegularExpression(pattern: "([a-z0-9])([A-Z])", options: [])
        self.type = matchFirst.stringByReplacingMatches(in: self.type, options: [], range: NSRange(location: 0, length: self.type.count), withTemplate: "$1:$2")
        self.type = matchAll.stringByReplacingMatches(in: self.type, options: [], range: NSRange(location: 0, length: self.type.count), withTemplate: "$1:$2")
        
        self.type = self.type.lowercased()
        
        self.data = behavior.dict()
        self.id = String.random(10, dictionary: .characters + . digits)
    }
    
    public var description: String {
        return "[ID  ] \(id)\n[Type] \(type)\n[Data] \(data)\n"
    }
}

public extension String {
    public static var uppercase: String {
        return "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    }
    
    public static var lowercase: String {
        return "abcdefghijklmnopqrstuvwxyz"
    }
    
    public static var digits: String {
        return "0123456789"
    }
    
    public static var characters: String {
        return uppercase + lowercase
    }
    
    public static func random(_ length: Int, dictionary: String) -> String {
        return (0..<length)
            .map { _ in dictionary[Int.random(in: 0..<dictionary.count)] }
            .reduce("", +)
    }
    
    public subscript (i: Int) -> String {
        return String(self[index(startIndex, offsetBy: i)])
    }
}
