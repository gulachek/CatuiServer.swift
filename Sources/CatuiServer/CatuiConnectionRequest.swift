//
//  CatuiConnectionRequest.swift
//  term
//
//  Created by Nicholas Gulachek on 8/1/24.
//

import Foundation
import catui

struct CatuiConnectionRequest {
    let catuiVersion: Semver
    let protocolName: String
    let protocolVersion: Semver
    
    init(buf: inout [UInt8], msgSize: Int) throws {
        var req = catui_connect_request()
        guard catui_decode_connect(&buf, msgSize, &req) == 1 else {
            throw ErrorWithMessage("Invalid catui connection request")
        }
        
        self.catuiVersion = Semver(catui: req.catui_version)
        self.protocolName = String(cString:catui_ext_protocol_cstr(&req))
        self.protocolVersion = Semver(catui: req.version)
    }
}
