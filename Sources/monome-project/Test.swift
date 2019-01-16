//
//  Test.swift
//  Basic program to test all of the output commands to the monome.
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
        monome.all(.off)
        monome.intensity(15)

        // Application description & usage
        io.writeMessage(self)
        io.writeMessage("Running \(name)...")

        for _ in 0..<2 {
            testLedRow8(.on)
            testLedCol8(.on)
        }
        for _ in 0..<2 {
            testLedRow16(.on)
            testLedCol16(.on)
        }

        testLedCol16(.off)
        testLedOnOff()
        testLedMap()

        chill(4)

        fadeOut()

        monome.all(.off)
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
                    monome.set(x: UInt32(j), y: UInt32(i), status: LED.Status(s))
                    chill(128)
                }
            }
            s -= 1
        }
    }
    func testLedRow8(_ status: LED.Status) {
        var on: UInt8 = status == .on ? 1 : 0
        for i in 0..<8 {
            monome.row(xOffset: 0, y: UInt32(i), count: 1, data: &on)
            chill(16)
            on |= on << 1
        }

        for i in 8..<16 {
            monome.row(xOffset: 0, y: UInt32(i), count: 1, data: &on)
            chill(16)
            on >>= 1
        }
    }
    func testLedCol8(_ status: LED.Status) {
        var on: UInt8 = status == .on ? 1 : 0
        for i in 0..<8 {
            monome.column(x: UInt32(i), yOffset: 0, count: 1, data: &on)
            chill(16)
            on |= on << 1
        }
        for i in 8..<16 {
            monome.column(x: UInt32(i), yOffset: 0, count: 1, data: &on)
            chill(16)
            on >>= 1
        }
    }
    func testLedRow16(_ status: LED.Status) {
        var on: UInt8 = status == .on ? 1 : 0
        for i in 0..<16 {
            monome.row(xOffset: 0, y: UInt32(i), count: 2, data: &on)
            chill(16)
            on |= on << 1
        }
    }
    func testLedCol16(_ status: LED.Status) {
        var on: UInt8 = status == .on ? 1 : 0
        for i in 0..<16 {
            monome.column(x: UInt32(i), yOffset: 0, count: 2, data: &on)
            chill(16)
            on |= on << 1
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
            monome.map(xOffset: UInt32(((q & 1) * 8)), yOffset: UInt32(((q & 2) * 4)), data: pattern[q])
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
        while(i > 0) {
            i -= 1
            monome.intensity(UInt32(i))
            chill(16)
        }
    }
    func testLedRingSet() {
        let yeah = UnsafeMutablePointer<UInt8>.allocate(capacity: 64)
        defer {
            yeah.deallocate()
        }
        for i in 0..<1024 {
            memset(yeah, 0, 64)
            yeah[i & 63] = 15
            monome.ringMap(ring: 0, levels: yeah)
            chill(32)
        }
    }
}
