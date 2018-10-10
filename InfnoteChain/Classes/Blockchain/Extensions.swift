//
//  Extensions.swift
//  InfnoteChain
//
//  Created by Vergil Choi on 2018/9/30.
//

import Foundation

public extension Data {
    public var humanReadableSize: String {
        if count > 2 << 29 {
            return String(format: "%.03f GB", Double(count) / Double(2 << 29))
        }
        else if count > 2 << 19 {
            return String(format: "%.03f MB", Double(count) / Double(2 << 19))
        }
        else if count > 2 << 9 {
            return String(format: "%.03f KB", Double(count) / Double(2 << 9))
        }
        else if count > 1 {
            return "\(count) Bytes"
        }
        return "\(count) Byte"
    }
}
