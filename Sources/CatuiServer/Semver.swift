//
//  Semver.swift
//  term
//
//  Created by Nicholas Gulachek on 8/3/24.
//

import Foundation
import catui

public struct Semver {
    public let major: UInt
    public let minor: UInt
    public let patch: UInt
    
    public init(_ major: UInt, _ minor: UInt, _ patch: UInt) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }
    
    init(catui: catui_semver) {
        self.major = UInt(catui.major)
        self.minor = UInt(catui.minor)
        self.patch = UInt(catui.patch)
    }
    
    public init(fromString str: String) throws {
        let maxCount = 32
        // Assume 32 bit integer fields, means 10 digits per field, 2 periods, max 32 total
        if str.count > maxCount {
            throw SemverError.tooLong(count: str.count, maxCount: maxCount)
        }
        
        let fields = str.split(separator:".")
        if fields.count != 3 {
            throw SemverError.invalidFieldCount(count: fields.count)
        }
        
        let nums = try fields.map() {
            guard let n = UInt($0) else {
                throw SemverError.invalidNumberField(field: String($0))
            }
            
            return n
        }
        
        self.major = nums[0]
        self.minor = nums[1]
        self.patch = nums[2]
    }
    
    public func canSupport(_ other: Semver) -> Bool {
        if (self.major != other.major) {
            return false
        }
        
        if (self.minor == other.minor) {
            return self.patch >= other.patch
        }
        
        return self.minor > other.minor
    }
    
    public func canUse(_ other: Semver) -> Bool {
        return other.canSupport(self)
    }
}

enum SemverError : LocalizedError {
    case tooLong(count: Int, maxCount: Int)
    case invalidFieldCount(count: Int)
    case invalidNumberField(field: String)
}
