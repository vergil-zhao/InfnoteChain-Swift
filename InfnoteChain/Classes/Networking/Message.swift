//
//  Message.swift
//  InfnoteChain
//
//  Created by Vergil Choi on 2018/10/8.
//

import Foundation


public class Message: CustomStringConvertible {
    
    public enum Kind: String {
        case hello  = "hello"
        case ok     = "ok"
        case ask    = "ask"
        case answer = "answer"
    }
    
    public let identifier: String!
    public let type: Kind!
    public var content: [String: Any]? = nil
    public var error: Any? = nil
    
    public var dict: [String: Any] {
        return [
            "identifier": identifier,
            "type": type.rawValue,
            "content": content,
            "error": error
        ]
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
        if let error = dict["error"] {
            self.error = error
        }
    }
    
    public init(type: Kind, content: [String: Any]? = nil, error: Any? = nil, identifier: String? = nil) {
        self.identifier = identifier ?? String.random(10, dictionary: .characters + .digits)
        self.type = type
        self.content = content
        self.error = error
    }
    
    public var description: String {
        var result = "\n[Type]       \(type.rawValue)\n[Identifier] \(identifier!)"
        if let content = content {
            result += "\n[Content]    \(content)"
        }
        if let error = error {
            result += "\n[Error]      \(error)"
        }
        return result
    }
}

public extension String {
    open static var uppercase: String {
        return "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    }
    
    open static var lowercase: String {
        return "abcdefghijklmnopqrstuvwxyz"
    }
    
    open static var digits: String {
        return "0123456789"
    }
    
    open static var characters: String {
        return uppercase + lowercase
    }
    
    open static func random(_ length: Int, dictionary: String) -> String {
        return (0..<length)
            .map { _ in dictionary[Int.random(in: 0..<dictionary.count)] }
            .reduce("", +)
    }
    
    subscript (i: Int) -> String {
        return String(self[index(startIndex, offsetBy: i)])
    }
}
