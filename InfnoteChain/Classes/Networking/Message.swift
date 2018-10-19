//
//  Message.swift
//  InfnoteChain
//
//  Created by Vergil Choi on 2018/10/8.
//

import Foundation


public class Message: CustomStringConvertible {
    
    public enum Kind: String {
        case broadcast  = "broadcast"
        case question   = "question"
        case answer     = "answer"
        case error      = "error"
    }
    
    public let identifier: String!
    public let type: Kind!
    public var content: [String: Any]? = nil
    
    public var dict: [String: Any] {
        var basic = [
            "identifier": identifier!,
            "type": type!.rawValue
        ] as [String: Any]
        if content != nil {
            basic["content"] = content
        }
        return basic
    }
    
    public var json: String {
        return try! JSONSerialization.data(withJSONObject: dict, options: []).utf8!
    }
    
    public init?(_ dict: [String: Any]) {
        guard let identifier = dict["identifier"] as? String,
            let type = dict["type"] as? String else {
            return nil
        }
        
        self.identifier = identifier
        self.type = Kind(rawValue: type)
        
        if let content = dict["content"] as? [String: Any] {
            self.content = content
        }
    }
    
    public init(type: Kind, identifier: String? = nil, content: [String: Any]? = nil) {
        self.identifier = identifier ?? String.random(10, dictionary: .characters + .digits)
        self.type = type
        self.content = content
    }
    
    public var description: String {
        var result = "[Type      ] \(type.rawValue)\n[Identifier] \(identifier!)"
        if let content = content {
            result += "\n[Content   ] \(content)"
        }
        return result + "\n"
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
