//
//  KQueue.swift
//  term
//
//  Created by Nicholas Gulachek on 7/29/24.
//

import Foundation

class KQueue {
    let fd: Int32
    
    init() throws {
        self.fd = kqueue()
        if self.fd == -1 {
            throw PosixError("kqueue")
        }
    }
    
    deinit {
        close(self.fd)
    }
    
    public func addReadFilter(_ fd: Int32) throws -> Void {
        var kev = kevent()
        kev.ident = UInt(fd)
        kev.filter = Int16(EVFILT_READ)
        kev.flags = UInt16(EV_ADD)
        kev.fflags = 0
        kev.data = 0
        kev.udata = nil
        
        if kevent(self.fd, &kev, 1, nil, 0, nil) == -1 {
            throw PosixError("kevent")
        }
    }
    
    public func addUserFilter(ident: Int32) throws -> Void {
        var kev = kevent()
        kev.ident = UInt(ident)
        kev.filter = Int16(EVFILT_USER)
        kev.flags = UInt16(EV_ADD)
        kev.fflags = 0
        kev.data = 0
        kev.udata = nil
        
        if kevent(self.fd, &kev, 1, nil, 0, nil) == -1 {
            throw PosixError("kevent")
        }
    }
    
    public func notifyUserFilter(ident: Int32) throws -> Void {
        var kev = kevent()
        kev.ident = UInt(ident)
        kev.filter = Int16(EVFILT_USER)
        kev.flags = 0
        kev.fflags = UInt32(NOTE_TRIGGER)
        kev.data = 0
        kev.udata = nil
        
        if kevent(self.fd, &kev, 1, nil, 0, nil) == -1 {
            throw PosixError("kevent")
        }
    }
    
    public func wait(timeoutMs: Int?) throws -> KEvent {
        var timeSpec = timespec()
        var ptrTimeSpec: UnsafePointer<timespec>? = nil
        if let timeoutMs {
            let (seconds, msec) = timeoutMs.quotientAndRemainder(dividingBy: 1000)
            timeSpec.tv_sec = seconds
            timeSpec.tv_nsec = 1000000*msec
            ptrTimeSpec = withUnsafePointer(to:timeSpec) { $0 }
        }
        
        var kev = kevent()
        let nevents = kevent(self.fd, nil, 0, &kev, 1, ptrTimeSpec)
        if nevents < 0 {
            throw PosixError("kevent")
        } else if nevents == 0 {
            return KEvent.timeout
        }
        
        switch Int32(kev.filter) {
        case EVFILT_READ:
            return KEvent.read(fd: Int32(kev.ident))
        case EVFILT_USER:
            return KEvent.user(ident: Int32(kev.ident))
        default:
            throw UnexpectedKEventFilter(kev.filter)
        }
    }
}

struct UnexpectedKEventFilter : LocalizedError {
    let filter: Int16
    
    init(_ filter: Int16) {
        self.filter = filter
    }
    
    var errorDescription: String? {
        get {
            return "Unexpected kevent filter '\(self.filter)'"
        }
    }
}

enum KEvent {
    case read(fd: Int32)
    case user(ident: Int32)
    case timeout
}
