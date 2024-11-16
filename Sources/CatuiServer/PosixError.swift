//
//  PosixError.swift
//  term
//
//  Created by Nicholas Gulachek on 7/29/24.
//

import Foundation

struct PosixError : LocalizedError {
    let functionName: String
    let errnoCode: Int32
    
    init(_ fn: String) {
        self.functionName = fn
        self.errnoCode = errno
    }
    
    var errorDescription: String? {
        get {
            let strError = String(cString:strerror(self.errnoCode))
            return "\(self.functionName)(): \(strError)"
        }
    }
}
