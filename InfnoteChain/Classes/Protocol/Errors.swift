//
//  Errors.swift
//  InfnoteChain
//
//  Created by Vergil Choi on 2019/1/29.
//

import Foundation


class ErrorMessage: Behavior {
    enum Kind: String {
        case InvalidMessage = "InvalidMessageError"
        case InvalidBehavior = "InvalidBehaviorError"
        case IncompatibleProtocolVersion = "IncompatibleProtocolVersionError"
        case BadRequest = "BadRequestError"
        case JSONDecode = "JSONDecodeError"
        case ChainNotAccept = "ChainNotAcceptError"
        case BlockValidation = "BlockValidationError"
        case InvalidURL = "InvalidURLError"
        case DuplicateBroadcast = "DuplicateBroadcastError"
    }
    
    var code: String = ""
    var desc: String = ""
    
    init?(dict: [String: Any]) {
        guard let code = dict["code"] as? String,
            let desc = dict["desc"] as? String else {
            return nil
        }
        
        self.code = code
        self.desc = desc
    }
    
    init(_ type: Kind, _ desc: String) {
        code = type.rawValue
        self.desc = desc
    }
    
    func validate() -> ErrorMessage? {
        return nil
    }
    
    func react() -> [Behavior] {
        return []
    }
    
    func dict() -> [String : Any] {
        return [
            "code": code,
            "desc": desc,
        ]
    }
}
