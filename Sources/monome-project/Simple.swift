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

class Simple: Application {
    static func name() -> String {
        return "simple"
    }
    static func description() -> String {
        return "\(Simple.name()) – Press a button to toggle it!"
    }
    var monome: Monome
    var io: ConsoleIO
    var name: String {
        return Simple.name()
    }
    var description: String {
        return Simple.description()
    }

    let scheduler: MonomeEventScheduler
    weak var delegate: ApplicationDelegate?
    var state: [[LED.Status]] = Array(repeating: Array(repeating: .off, count: 16), count: 16)

    init(monome: Monome, io: ConsoleIO) {
        self.monome = monome
        self.io = io
        self.scheduler = MonomeEventScheduler(monome: self.monome)
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
        monome.all(status: .off)
    }

    func displayUsage() {
        io.writeMessage("Usage:")
        io.writeMessage("   u - Display `\(name)` usage.")
        io.writeMessage("   q - Quit")
    }

    func run() {
        // Monome setup & application state
        monome.registerGridHandler { [weak self] (monome: Monome, event: GridEvent) in
            if event.action == .buttonUp {
                // Toggle grid button LED status
                guard let strongSelf = self else {
                    return
                }
                let x = event.x
                let y = event.y
                let col = Int(x)
                let row = Int(y)

                let status = strongSelf.state[row][col]
                let nextStatus: LED.Status = status == .on ? .off : .on
                monome.set(x: x, y: y, status: nextStatus)
                strongSelf.state[row][col] = nextStatus
            }
        }
        clear()

        // Application description & usage
        io.writeMessage(self)
        displayUsage()

        scheduler.start() // Start Monome Event Scheduler

        // Listen for user input
        var shouldQuit: Bool = false
        while !shouldQuit {
            io.displayCarrot("simple")
            guard let input = io.getInput() else {
                continue
            }
            if input == "q" {
                shouldQuit = true
            } else {
                displayUsage()
            }
        }

        // All done
        monome.all(status: .off)
        quit(EXIT_SUCCESS)
    }

    func quit(_ exitStatus: Int32) {
        scheduler.stop()
        delegate?.applicationDidFinish(self, exitStatus: exitStatus)
    }
}
