//
//  Key.swift
//  infnote
//
//  Created by Vergil Choi on 2018/8/24.
//  Copyright © 2018 Vergil Choi. All rights reserved.
//

import UIKit

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
    public convenience init(privateKey: String) throws {
        try self.init(privateKey: Data(base58: privateKey)!)
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
        let query: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits as String: Key.keySizeInBits
        ]
        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateWithData(
            publicKey as CFData,
            query as CFDictionary,
            &error) else {
                throw ImportError.privateKeyParseFailed
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
    open func save() throws {
        guard let privateKey = self.privateKey else {
            return
        }
        
        Key.clean()
        
        let status = SecItemAdd([
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: Key.defaultTag,
            kSecValueRef as String: privateKey
            ] as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeyError.saveSecKeyItemFailed(status)
        }
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

