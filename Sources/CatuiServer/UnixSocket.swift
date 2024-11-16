//
//  UnixSocket.swift
//  term
//
//  Created by Nicholas Gulachek on 7/31/24.
//

import Foundation
import unixsocket

public class UnixSocket {
    let fd: Int32
    var isOpen: Bool
    private(set) var path: String? = nil
    
    init() throws {
        self.fd = unix_socket()
        self.isOpen = true
        
        if self.fd == -1 {
            self.isOpen = false
            throw PosixError("unixsocket_create")
        }
    }
    
    init(_ fd: Int32) {
        self.fd = fd
        self.isOpen = fd != -1
    }
    
    deinit {
        self.close()
        
        if let path = self.path {
            unlink(path)
        }
    }
    
    public func close() -> Void {
        if self.isOpen {
            Darwin.close(self.fd)
            self.isOpen = false
        }
    }
    
    public func bindToPath(_ path: String) throws -> Void {
        guard unix_bind(self.fd, path) != -1 else {
            throw PosixError("unixsocket_bind")
        }
        
        self.path = path
    }
    
    public func listenWithBacklog(_ backlog: Int) throws -> Void {
        guard unix_listen(self.fd, Int32(backlog)) != -1 else {
            throw PosixError("listen")
        }
    }
    
    public func shouldBlock(_ shouldBlock: Bool) throws -> Void {
        let fl = Int32(shouldBlock ? 0 : O_NONBLOCK)
        guard fcntl(self.fd, F_SETFL, fl) != -1 else {
            throw PosixError("fcntl")
        }
    }
    
    public func accept() throws -> UnixSocket? {
        let fd = unix_accept(self.fd)
        if fd == -1 {
            if errno == EWOULDBLOCK {
                return nil
            } else {
                throw PosixError("accept")
            }
        }
        
        return UnixSocket(fd)
    }
}
