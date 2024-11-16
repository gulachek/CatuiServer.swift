//
//  MsgstreamError.swift
//  term
//
//  Created by Nicholas Gulachek on 8/1/24.
//

import Foundation
import msgstream

struct MsgstreamError : LocalizedError {
    let functionName: String
    let errorCode: Int32
    
    init(fn: String, errorCode: Int32) {
        self.functionName = fn
        self.errorCode = errorCode
    }
    
    var errorDescription: String? {
        get {
            let errStr = String(cString:msgstream_errstr(self.errorCode))
            return "\(self.functionName)(): \(errStr)"
        }
    }
}
