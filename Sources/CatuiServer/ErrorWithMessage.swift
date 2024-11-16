//
//  ErrorWithMessage.swift
//  term
//
//  Created by Nicholas Gulachek on 8/7/24.
//

import Foundation

struct ErrorWithMessage : LocalizedError {
    var errorDescription: String?
    
    init(_ msg: String) {
        self.errorDescription = msg
    }
}
