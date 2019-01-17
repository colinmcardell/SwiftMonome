//
//  Simple.swift
//
//  Press a button to toggle it!
//
#if os(Linux)
import Glibc
#else
import Darwin
#endif

import Foundation
import SwiftMonome

final class Simple: Application {
    static func name() -> String {
        return "simple"
    }
    static func description() -> String {
        return "\(Simple.name()) – Press a button to toggle it!"
    }

    let scheduler: MonomeEventScheduler
    var state: [[LED.Status]] = Array(repeating: Array(repeating: .off, count: 16), count: 16)

    override init(monome: Monome, io: ConsoleIO) {
        self.scheduler = MonomeEventScheduler(monome: monome)
        super.init(monome: monome, io: io)

        self.name = Simple.name()
        self.description = Simple.description()
    }

    func clear() {
        var columns = Int(monome.columns)
        var rows = Int(monome.rows)
        if columns == 0 {
            columns = 16
        }
        if rows == 0 {
            rows = 16
        }
        state = Array(repeating: Array(repeating: .off, count: columns), count: rows)
        monome.all(.off)
    }

    func displayUsage() {
        io.writeMessage("Usage:")
        io.writeMessage("   u - Display `\(name)` usage.")
        io.writeMessage("   q - Quit")
    }

    override func gridEvent(event: GridEvent) {
        if event.action == .buttonUp {
            // Toggle grid button LED status
            let x = event.x
            let y = event.y
            let col = Int(x)
            let row = Int(y)

            let status = state[row][col]
            let nextStatus: LED.Status = status == .on ? .off : .on
            monome.set(x: x, y: y, status: nextStatus)
            state[row][col] = nextStatus
        }
    }

    override func run() {
        // Monome setup & application state
        clear()

        // Application description & usage
        io.writeMessage(self)
        displayUsage()
        io.displayCarrot(name)

        scheduler.start() // Start Monome Event Scheduler

        // Listen for user input
        var shouldQuit: Bool = false
        while !shouldQuit {
            guard let input = io.getInput() else {
                continue
            }
            if input == "q" {
                shouldQuit = true
            } else {
                displayUsage()
                io.displayCarrot(name)
            }
        }

        // All done
        monome.all(.off)
        quit(EXIT_SUCCESS)
    }

    override func quit(_ exitStatus: Int32) {
        scheduler.stop()
        super.quit(exitStatus)
    }
}
