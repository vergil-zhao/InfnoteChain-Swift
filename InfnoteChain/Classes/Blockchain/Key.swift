//
//  Key.swift
//  infnote
//
//  Created by Vergil Choi on 2018/8/24.
//  Copyright © 2018 Vergil Choi. All rights reserved.
//

import UIKit
import BigInt

open class Key {
    public static let defaultTag = "com.infnote.keys.default"
    public static let keySizeInBits = 256
    
    public enum ImportError: Error {
        case cannotExtractPublicKey
        case publicKeyParseFailed
        case privateKeyParseFailed
    }
    
    public enum KeyError: Error {
        case loadSecKeyItemFailed(Error)
        case saveSecKeyItemFailed(OSStatus)
        case signFailed(Error)
        case generateKeyFailed(Error)
        case onlyPublicKey
    }

    public let publicKey: SecKey
    public var privateKey: SecKey?
    
    open var canSign: Bool {
        return privateKey != nil
    }
    
    open class func loadDefaultKey() -> Key? {
        var item: CFTypeRef?
        let status = SecItemCopyMatching([
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: defaultTag,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: keySizeInBits,
            kSecReturnRef as String: true
            ] as CFDictionary, &item)
        guard status == errSecSuccess else {
            return nil
        }
        return try? Key(privateKey: item as! SecKey)
    }
    
    open class func clean() {
        let attributes: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: defaultTag,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: keySizeInBits
        ]
        SecItemDelete(attributes as CFDictionary)
    }
    
    public init() throws {
        let attributes: [String: Any] =
            [kSecAttrKeyType as String:            kSecAttrKeyTypeECSECPrimeRandom,
             kSecAttrKeySizeInBits as String:      Key.keySizeInBits,
             kSecPrivateKeyAttrs as String:
                [kSecAttrIsPermanent as String:    true,
                 kSecAttrEffectiveKeySize as String: Key.keySizeInBits]
        ]
        
        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            throw KeyError.generateKeyFailed(error!.takeRetainedValue() as Error)
        }
        
        self.privateKey = privateKey
        self.publicKey = SecKeyCopyPublicKey(privateKey)!
    }
    
    // TODO: check if base58 string is valid
    public convenience init?(privateKey: String) {
        guard let data = Data(base58: privateKey) else {
            return nil
        }
        try? self.init(privateKey: data)
    }
    
    public convenience init(privateKey: Data) throws {
        let query: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecAttrKeySizeInBits as String: Key.keySizeInBits
        ]
        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateWithData(
            privateKey as CFData,
            query as CFDictionary,
            &error) else {
            throw ImportError.privateKeyParseFailed
        }
        try self.init(privateKey: key)
    }
    
    // TODO: check if base58 string is valid
    public convenience init(publicKey: String) throws {
        try self.init(publicKey: Data(base58: publicKey)!)
    }
    
    public convenience init(publicKey: Data) throws {
        let uncompressed = Key.decompress(publicKey: publicKey)
        let query: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits as String: Key.keySizeInBits
        ]
        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateWithData(
            uncompressed as CFData,
            query as CFDictionary,
            &error) else {
                throw ImportError.publicKeyParseFailed
        }
        try self.init(publicKey: key)
    }
    
    public init(privateKey: SecKey) throws {
        self.privateKey = privateKey
        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw ImportError.cannotExtractPublicKey
        }
        self.publicKey = publicKey
    }
    
    public init(publicKey: SecKey) throws {
        self.publicKey = publicKey
    }
    
    // Just keep one private key for now
    // TODO: Keep more than one private keys
    @discardableResult
    open func save() -> Bool {
        guard let privateKey = self.privateKey else {
            return false
        }
        
        Key.clean()
        
        let status = SecItemAdd([
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: Key.defaultTag,
            kSecValueRef as String: privateKey
            ] as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    open func sign(data: Data) throws -> Data {
        guard let privateKey = self.privateKey else {
            throw KeyError.onlyPublicKey
        }
        
        var error: Unmanaged<CFError>?
        guard let signature = SecKeyCreateSignature(
            privateKey,
            .ecdsaSignatureMessageX962SHA256,
            data as CFData,
            &error) as Data? else {
            throw KeyError.signFailed(error!.takeRetainedValue() as Error)
        }
        return signature
    }
    
    open func verify(data: Data, signature: Data) -> Bool {
        return publicKey.verify(message: data, signature: signature)
    }
    
    public var compressedPublicKey: Data {
        let data = self.publicKey.data
        let x = data[1...32]
        let last = data.last!
        let flag = 2 + (last & 1)
        return Data(bytes: [flag]) + x
    }
    
    static func decompress(publicKey: Data) -> Data {
        let prime  = BigUInt("115792089210356248762697446949407573530086143415290314195533631308867097853951")!
        let b      = BigUInt("41058363725152142129326129780047268409114441015993725554835256314039467401291")!
        let pIdent = BigUInt("28948022302589062190674361737351893382521535853822578548883407827216774463488")!
        
        let flag = publicKey.first! - 2
        let x = BigUInt(publicKey[1...])
        var y = (x.power(3) - x * 3 + b).power(pIdent, modulus: prime)
        if y % 2 != flag {
            y = prime - y
        }
        return Data(bytes: [0x04]) + publicKey[1...] + y.serialize()
    }
}


public extension SecKey {
    
    // TODO: Add attribute judgement to avoid exceptions
    public var data: Data {
        return SecKeyCopyExternalRepresentation(self, nil)! as Data
    }
    
    public var hex: String {
        return data.hex
    }
    
    public var base58: String {
        return data.base58
    }
    
    // TODO: Add attribute judgement & remove print
    public func verify(message: Data, signature: Data) -> Bool {
        var error: Unmanaged<CFError>?
        guard SecKeyVerifySignature(self,
                                    .ecdsaSignatureMessageX962SHA256,
                                    message as CFData,
                                    signature as CFData,
                                    &error) else {
                                        print(error!.takeRetainedValue() as Error)
                                        return false
        }
        
        return true
    }
}

