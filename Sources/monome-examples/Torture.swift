//
//  Torture.swift
//  Write a ton of data to a monome.
//  A reimplementation of `torture.c` from libmonome.
//  SwiftMonome - monome-examples
//
//  Colin McArdell <colin@colinmcardell.com>
//

#if os(Linux)
import Glibc
#else
import Darwin
#endif

import Foundation
import SwiftMonome

final class Torture: Application {
    static func name() -> String {
        return "torture"
    }
    static func description() -> String {
        return "\(Torture.name()) – Write a ton of data to a monome."
    }

    let buf: UnsafeMutablePointer<UInt16>

    override init(monome: Monome, io: ConsoleIO) {
        self.buf = UnsafeMutablePointer<UInt16>.allocate(capacity: 1)
        self.buf.initialize(to: 0)

        super.init(monome: monome, io: io)
        self.name = Torture.name()
        self.description = Torture.description()
    }

    deinit {
        buf.deallocate()
    }

    override func run() {
        monome.all(0)
        monome.intensity(15)

        // Application description & usage
        io.writeMessage(self)
        io.writeMessage("Running \(name)...")

        let w = 16
        let h = 16
        var s: UInt16 = 0

        while true {
            for y in 0..<h {
                buf.pointee = (1 << UInt16(y)) - s
                buf.withMemoryRebound(to: UInt8.self, capacity: 2) {
                    let data: [UInt8] = [UInt8](UnsafeMutableBufferPointer(start: $0, count: 2))
                    monome.row(x: y, y: (w / 8), count: y, data: data)
                }
                monome.set(x: w - 1, y: y, status: UInt8(getRandom() & 1))
                randomChill()
            }
            s = (s == 0) ? 1 : 0
        }
    }
}

extension Torture {
    func randomChill() {
        var rem = timespec(tv_sec: 0, tv_nsec: 0)
        var req = timespec(tv_sec: 0, tv_nsec: Int(((getRandom() % 100000) + 100)))
        nanosleep(&req, &rem)
    }
    func getRandom() -> Int {
        #if os(Linux)
        return random()
        #else
        return Int(arc4random())
        #endif
    }
}
