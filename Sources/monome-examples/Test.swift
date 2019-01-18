//
//  Test.swift
//  Basic program to test all of the output commands to the monome.
//  A reimplementation of `test.c` from libmonome.
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

final class Test: Application {
    static func name() -> String {
        return "test"
    }
    static func description() -> String {
        return "\(Test.name()) – Test all of the output commands to the monome."
    }

    override init(monome: Monome, io: ConsoleIO) {
        super.init(monome: monome, io: io)
        self.name = Test.name()
        self.description = Test.description()
    }

    override func run() {
        monome.all(0)
        monome.intensity(15)

        // Application description & usage
        io.writeMessage(self)
        io.writeMessage("Running \(name)...")

        for _ in 0..<2 {
            testLedRow8(1)
            testLedCol8(1)
        }
        for _ in 0..<2 {
            testLedRow16(1)
            testLedCol16(1)
        }

        testLedCol16(0)
        testLedOnOff()
        testLedMap()

        chill(4)

        fadeOut()

        monome.all(0)
        monome.intensity(15)
        quit(EXIT_SUCCESS)
    }
}

extension Test {

    static var BPM: Int = 98

    func chill(_ speed: Int) {
        var rem = timespec(tv_sec: 0, tv_nsec: 0)
        var req = timespec(tv_sec: 0, tv_nsec: ((60000 / (Test.BPM * speed)) * 1000000))
        nanosleep(&req, &rem)
    }

    func testLedOnOff() {
        var s = 2
        while s >= 0 {
            for i in 0..<16 {
                for j in 0..<16 {
                    monome.set(x: j, y: i, status: UInt8(s))
                    chill(128)
                }
            }
            s -= 1
        }
    }

    func testLedRow8(_ status: UInt8) {
        var on = status
        for i in 0..<8 {
            monome.row(x: 0, y: i, data: [on], shouldReduceBytes: false)
            chill(16)
            on |= on << 1
        }

        for i in 8..<16 {
            monome.row(x: 0, y: i, data: [on], shouldReduceBytes: false)
            chill(16)
            on >>= 1
        }
    }

    func testLedCol8(_ status: UInt8) {
        var on = status
        for i in 0..<8 {
            monome.column(x: i, y: 0, data: [on], shouldReduceBytes: false)
            chill(16)
            on |= on << 1
        }
        for i in 8..<16 {
            monome.column(x: i, y: 0, data: [on], shouldReduceBytes: false)
            chill(16)
            on >>= 1
        }
    }

    func testLedRow16(_ status: UInt8) {
        var buf = UnsafeMutablePointer<UInt16>.allocate(capacity: 1)
        buf.initialize(to: UInt16(status))
        defer {
            buf.deallocate()
        }
        for i in 0..<16 {
            buf.withMemoryRebound(to: UInt8.self, capacity: 2) {
                let data: [UInt8] = [UInt8](UnsafeMutableBufferPointer(start: $0, count: 2))
                monome.row(x: 0, y: i, data: data, shouldReduceBytes: false)
            }
            chill(16)
            buf.pointee |= buf.pointee << 1
        }
    }

    func testLedCol16(_ status: UInt8) {
        var buf = UnsafeMutablePointer<UInt16>.allocate(capacity: 1)
        buf.initialize(to: UInt16(status))
        defer {
            buf.deallocate()
        }
        for i in 0..<16 {
            buf.withMemoryRebound(to: UInt8.self, capacity: 2) {
                let data: [UInt8] = [UInt8](UnsafeMutableBufferPointer(start: $0, count: 2))
                monome.column(x: i, y: 0, data: data, shouldReduceBytes: false)
            }
            chill(16)
            buf.pointee |= buf.pointee << 1
        }
    }

    func testLedMap() {
        var pattern: [[UInt8]] = [
            [0, 34, 20, 8, 8, 8, 8, 0],         // Y
            [0, 126, 2, 2, 30, 2, 126, 0],      // E
            [0, 124, 66, 66, 126, 66, 66, 0],   // A
            [0, 36, 36, 36, 60, 36, 36, 0],     // H
        ]
        var q: Int = 0
        for l in 0..<8 {
            monome.map(x: ((q & 1) * 8), y: ((q & 2) * 4), data: pattern[q])
            for i in 0..<8 {
                pattern[q][i] ^= 0xFF
            }
            chill(2)
            if l % 2 != 0 {
                q = (q + 1) & 3
            }
        }
    }

    func fadeOut() {
        var i: Int = 0x10
        while i > 0 {
            i -= 1
            monome.intensity(UInt8(i))
            chill(16)
        }
    }

    func testLedRingSet() {
        var yeah: [UInt8]
        for i in 0..<1024 {
            yeah = [UInt8](repeating: 0, count: 64)
            yeah[i & 63] = 15
            monome.ringMap(ring: 0, levels: yeah)
            chill(32)
        }
    }
}
