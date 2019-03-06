//
//  Key.swift
//  infnote
//
//  Created by Vergil Choi on 2018/8/24.
//  Copyright © 2018 Vergil Choi. All rights reserved.
//

import UIKit
import OpenSSL

public class Key {
    
    public var raw: Data
    public var publicKey: Data {
        return SECP256K1.privateToPublic(privateKey: raw, compressed: true)!
    }
    public var wif: String {
        var payload = Data([0x80]) + raw + Data([0x01])
        let checksum = payload.sha256.sha256.prefix(4)
        return (payload + checksum).base58
    }
    public var address: String {
        return Key.generateAddress(publicKey: publicKey)
    }
    
    private static func generateRandomPrivateKeyData() -> Data {
        // Generate Random Private Key
        func check(_ vch: [UInt8]) -> Bool {
            let max: [UInt8] = [
                0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
                0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFE,
                0xBA, 0xAE, 0xDC, 0xE6, 0xAF, 0x48, 0xA0, 0x3B,
                0xBF, 0xD2, 0x5E, 0x8C, 0xD0, 0x36, 0x41, 0x40
            ]
            var fIsZero = true
            for byte in vch where byte != 0 {
                fIsZero = false
                break
            }
            if fIsZero {
                return false
            }
            for (index, byte) in vch.enumerated() {
                if byte < max[index] {
                    return true
                }
                if byte > max[index] {
                    return false
                }
            }
            return true
        }
        
        let count = 32
        var key = Data(count: count)
        var status: Int32 = 0
        repeat {
            status = key.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, count, $0) }
        } while (status != 0 || !check([UInt8](key)))
        
        return key
    }

    public static func loadDefaultKey() -> Key? {
        if let wif = UserDefaults.standard.string(forKey: "com.infnote.default.wif") {
            return Key(wif: wif)
        }
        return nil
    }
    
    public init() {
        raw = Key.generateRandomPrivateKeyData()
    }
    
    public init?(wif: String) {
        guard let data = Data(base58: wif) else {
            return nil
        }
        let checksum = Data(data.suffix(4))
        let payload = data.prefix(data.count - 4)
        guard payload.sha256.sha256.prefix(4) == checksum else {
            return nil
        }
        raw = payload.subdata(in: 1..<payload.count - 1)
        guard raw.count == 32 else {
            return nil
        }
    }
    
    public func sign(message: Data) -> Data {
        return SECP256K1.signForRecovery(hash: message.sha256, privateKey: raw, useExtraEntropy: false).serializedSignature!
    }
    
    public static func recover(signature: Data, message: Data) -> String {
        return generateAddress(publicKey: SECP256K1.recoverPublicKey(hash: message.sha256, signature: signature, compressed: true)!)
    }
    
    static func generateAddress(publicKey: Data) -> String {
        var data = Data(count: Int(RIPEMD160_DIGEST_LENGTH))
        data.withUnsafeMutableBytes { result in
            publicKey.sha256.withUnsafeBytes {
                RIPEMD160($0, 32, result)
            }
        }
        data = Data([0x00]) + data
        return (data + data.sha256.sha256.prefix(4)).base58
    }
    
    public static func verify(address: String, signature: Data, message: Data) -> Bool {
        return address == Key.recover(signature: signature, message: message)
    }
    
    public func save() {
        UserDefaults.standard.set(wif, forKey: "com.infnote.default.wif")
    }
    
    public static func clean() {
        UserDefaults.standard.set(nil, forKey: "com.infnote.default.wif")
    }
}

