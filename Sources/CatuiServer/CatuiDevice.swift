//
//  CatuiDevice.swift
//  term
//
//  Created by Nicholas Gulachek on 8/8/24.
//

import Foundation

public protocol CatuiDevice {
    var catuiVersion: Semver { get }
    var protocolName: String { get }
    var protocolVersion: Semver { get }
    
    func attachToServer(_ server: CatuiServerProxy) -> Void
    func newConnection(_ sock: UnixSocket) -> Void
}
