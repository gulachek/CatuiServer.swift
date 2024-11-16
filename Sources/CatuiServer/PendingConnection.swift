//
//  PendingConnection.swift
//  term
//
//  Created by Nicholas Gulachek on 7/31/24.
//

import Foundation
import msgstream
import catui

class PendingConnection {
    private let sock: UnixSocket
    private var buf: [UInt8]
    private let reader: msgstream_incremental_reader
    private let startTime: ContinuousClock.Instant
    
    init(_ sock: UnixSocket, startTime: ContinuousClock.Instant) {
        self.sock = sock
        self.buf = [UInt8].init(repeating:0, count:1024)
        self.reader = msgstream_incremental_reader_alloc(&self.buf, self.buf.count)
        self.startTime = startTime
    }
    
    deinit {
        msgstream_incremental_reader_free(self.reader)
    }
    
    public func readSomeReq() throws -> CatuiConnectionRequest? {
        var isComplete: Int32 = 0
        var msgSize: Int = 0
        let result = msgstream_fd_incremental_recv(self.sock.fd, self.reader, &isComplete, &msgSize)
        
        guard result == MSGSTREAM_OK else {
            self.sock.close()
            throw MsgstreamError(fn:"msgstream_fd_incremental_recv", errorCode:result)
        }
        
        if isComplete != 1 {
            return nil
        }
        
        var req = catui_connect_request()
        guard catui_decode_connect(&self.buf, msgSize, &req) == 1 else {
            self.sock.close()
            throw ErrorWithMessage("Invalid catui connection request")
        }
        
        return try CatuiConnectionRequest(buf:&self.buf, msgSize:msgSize)
    }
    
    public func closeIfExpired(t: ContinuousClock.Instant) -> Bool {
        if (t - self.startTime > .seconds(3)) {
            self.sock.close()
            return true
        }
        
        return false
    }
}
