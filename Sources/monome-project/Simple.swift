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
    var monome: Monome
    var io: ConsoleIO
    var name: String {
        return "Simple"
    }
    var description: String {
        return "\(name) – Press a button to toggle it!"
    }
    weak var delegate: ApplicationDelegate?
    var state: [[LED.Status]] = Array(repeating: Array(repeating: .off, count: 16), count: 16)

    init(monome: Monome, io: ConsoleIO) {
        self.monome = monome
        self.io = io
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

    func run() {
        io.writeMessage(self)
        clear()
        monome.registerGridHandler { [weak self] (monome: Monome, event: GridEvent) in
            if event.action == .buttonUp {
                // Toggle
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

//        var timer: DispatchSourceTimer?
        let queue = DispatchQueue.global(qos: .userInteractive)
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: .milliseconds(16))
        timer.setEventHandler { [weak self] in
            self?.monome.eventHandleNext()
        }
        timer.resume()
        var shouldQuit: Bool = false
        while !shouldQuit {
            guard let input = io.getInput() else {
                continue
            }
            if input == "q" {
                timer.cancel()
                shouldQuit = true
            }
        }
        monome.all(status: .off)
        quit(EXIT_SUCCESS)
    }

    func quit(_ exitStatus: Int32) {
        delegate?.applicationDidFinish(self, exitStatus: exitStatus)
    }
}
