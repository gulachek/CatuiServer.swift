//
//  CatuiServer.swift
//  term
//
//  Created by Nicholas Gulachek on 7/28/24.
//

import Foundation
import Cocoa

public class CatuiServer : Thread {
    let socketBacklog = 16;
    private let userQuit = Int32(0x7fffffff)
    
    private var server: UnixSocket!
    private var kq: KQueue!
    private var group = DispatchGroup()
    private var devices: Dictionary<String, CatuiDevice> = [:]
    
    public init(_ devices: [CatuiDevice]) {
        super.init()
        self.group.enter()
        
        self.attachDevices(devices)
        
        do {
            
            self.server = try UnixSocket()
            
            try server.bindToPath("test.sock")
            try server.listenWithBacklog(self.socketBacklog)
            try server.shouldBlock(false)
            
            self.kq = try KQueue()
            try kq.addReadFilter(server.fd)
            
            try kq.addUserFilter(ident: self.userQuit)
        } catch {
            assertionFailure("Failed to set up basic system resources for catui server: \(error.localizedDescription)")
        }
    }
    
    private func attachDevices(_ devices: [CatuiDevice]) -> Void {
        for device in devices {
            // perhaps need multiple version support, duplicate error checking, etc
            self.devices[device.protocolName] = device
        }
    }
    
    public override func main() {
        defer {
            print("Exiting catui server thread")
            self.group.leave()
        }
        
        for (_, device) in self.devices {
            let proxy = CatuiServerProxy(device)
            device.attachToServer(proxy)
        }
        
        do {
            print("Listening at: \(FileManager.default.currentDirectoryPath)/\(server.path!)")
            
            var pendingConnections = [Int32:PendingConnection].init(minimumCapacity: self.socketBacklog)
            
            while server.isOpen {
                var timeoutMs: Int? = nil
                if !pendingConnections.isEmpty {
                    timeoutMs = 500
                }
                
                let resultEvent = try kq.wait(timeoutMs: timeoutMs)
                let now = ContinuousClock.now
                
                // Don't let pending connections hang out forever
                for (fd, con) in pendingConnections {
                    if con.closeIfExpired(t:now) {
                        pendingConnections.removeValue(forKey:fd)
                    }
                }
                
                switch resultEvent {
                case .read(let fd):
                    if fd == server.fd {
                        if let con = try server.accept() {
                            // Prevent flooding this server with pending connections
                            if (pendingConnections.count <= self.socketBacklog) {
                                try kq.addReadFilter(con.fd)
                                pendingConnections[con.fd] = PendingConnection(con, startTime:now)
                            } else {
                                con.close()
                            }
                        }
                    } else if let con = pendingConnections[fd] {
                        var request: CatuiConnectionRequest?
                        
                        do {
                            request = try con.readSomeReq()
                        } catch {
                            print("Error reading catui connection request: \(error.localizedDescription)")
                            pendingConnections.removeValue(forKey:fd)
                        }
                        
                        if let request {
                            pendingConnections.removeValue(forKey:fd)
                            print("Requested protocol \(request.protocolName)/\(request.protocolVersion)")
                        }
                    }
                case .user(let ident):
                    assert(ident == self.userQuit, "Unexpected user filter triggered on kqueue")
                    server.close()
                    // TODO: close all pending connections too?
                case .timeout:
                    continue
                }
                    
            }
        } catch {
            let msg = error.localizedDescription
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = msg
                alert.runModal()
            }
        }
    }
    
    public func quit() throws -> Void {
        assert(Thread.isMainThread, "quit can only be called from main thread")
        try self.kq.notifyUserFilter(ident: self.userQuit)
        self.group.wait()
    }
    
    private func perror(_ op: String) -> Void {
        let posixErr = String(cString:strerror(errno))
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.icon = NSImage(systemSymbolName:"exclamation.triangle", accessibilityDescription: "Error")
            alert.messageText = "\(op): \(posixErr)"
            alert.runModal()
            NSApp.terminate(nil)
        }
    }
}
