//
//  Extensions.swift
//  InfnoteChain
//
//  Created by Vergil Choi on 2018/9/30.
//

import Foundation

public extension Data {
    public var humanReadableSize: String {
        if count >= 2 << 29 {
            return String(format: "%.0f GB", round(Double(count) / Double(2 << 29) * 1000)  / 1000)
        }
        else if count >= 2 << 19 {
            return String(format: "%.0f MB", round(Double(count) / Double(2 << 19) * 1000)  / 1000)
        }
        else if count >= 2 << 9 {
            return String(format: "%.0f KB", round(Double(count) / Double(2 << 9) * 1000)  / 1000)
        }
        else if count > 1 {
            return "\(count) Bytes"
        }
        return "\(count) Byte"
    }
}
