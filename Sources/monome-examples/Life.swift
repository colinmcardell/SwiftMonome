//
//  Life.swift
//  Conway's Game of Life.
//  SwiftMonome - monome-examples
//
//  Colin McArdell <colinmcardell@gmail.com>
//

#if os(Linux)
import Glibc
#else
import Darwin
#endif

import Foundation
import SwiftMonome

struct Point {

    var x: Int
    var y: Int
}

class Cell {

    var isAlive: Bool
    var modNext: Bool
    var coordinate: Point
    var nnum: UInt8

    // Lifecycle
    init() {
        self.isAlive = false
        self.modNext = false
        self.coordinate = Point(x: 0, y: 0)
        self.nnum = 0
    }

    convenience init(coordinate: Point) {
        self.init()
        self.coordinate = coordinate
    }

    private func _mod(_ dividend: Int, _ divisor: Int) -> Int {
        precondition(divisor > 0, "divisor must to positive")
        let remainder = dividend % divisor
        return remainder >= 0 ? remainder : remainder + divisor
    }

    func getNeighbors(_ cells: [[Cell]]) -> [Cell] {
        let columns: Int = cells.count
        let rows: Int = cells[0].count
        var neighbors: [Cell] = Array()

        for n in 0..<8 {
            var xOffset: Int = 0
            var yOffset: Int = 0
            switch n {
            case 0:
                xOffset = -1
                yOffset = -1
                break
            case 1:
                xOffset = -1
                yOffset = 1
                break
            case 2:
                xOffset = -1
                yOffset = 0
                break
            case 3:
                xOffset = 1
                yOffset = -1
                break
            case 4:
                xOffset = 1
                yOffset = 1
                break
            case 5:
                xOffset = 1
                yOffset = 0
                break
            case 6:
                xOffset = 0
                yOffset = -1
                break
            case 7:
                xOffset = 0
                yOffset = 1
                break
            default:
                break
            }
            neighbors.append(cells[_mod(coordinate.x + xOffset, columns)][_mod(coordinate.y + yOffset, rows)])
        }
        return neighbors
    }

    func modNeighbors(_ cells: [[Cell]], delta: Int) {
        let neighbors = self.getNeighbors(cells)
        for cell in neighbors {
            if delta < 0 {
                cell.nnum = cell.nnum &- UInt8(abs(delta))
            } else {
                cell.nnum = cell.nnum &+ UInt8(delta)
            }
        }
    }
}

final class Life: Application {

    static func name() -> String {
        return "life"
    }
    static func description() -> String {
        return "\(Life.name()) – Conway's Game of Life"
    }

    let monomeEventScheduler: MonomeEventScheduler
    let applicationEventScheduler: EventScheduler = EventScheduler(.highPriority)
    let columns: Int
    let rows: Int
    var isRunning: Bool = false
    let updateLock = DispatchSemaphore(value: 1)
    var state: [[Cell]]

    override init(monome: Monome, io: ConsoleIO) {
        self.monomeEventScheduler = MonomeEventScheduler(monome: monome)
        self.columns = monome.columns == 0 ? 16 : Int(monome.columns)
        self.rows = monome.rows == 0 ? 16 : Int(monome.rows)
        self.state = Life.defaultState(columns: self.columns, rows: self.rows)

        super.init(monome: monome, io: io)
        self.applicationEventScheduler.interval = .milliseconds(75)
        self.applicationEventScheduler.eventHandler = { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.updateLock.wait()
            strongSelf.tick()
            strongSelf.updateLock.signal()
        }
        self.name = Life.name()
        self.description = Life.description()
    }

    func displayUsage() {
        io.writeMessage("Usage:")
        io.writeMessage("   r - Run \(name).")
        io.writeMessage("   s - Suspend \(name).")
        io.writeMessage("   u - Display `\(name)` usage.")
        io.writeMessage("   q - Quit")
    }

    override func gridEvent(event: GridEvent) {
        if event.action == .buttonUp {
            updateLock.wait()

            let x = event.x
            let y = event.y

            if isRunning {
                state[x][y].modNext = true
            } else {
                // Toggle
                let modNext = !state[x][y].modNext
                state[x][y].modNext = modNext
                monome.set(x: x, y: y, status: modNext ? 1 : 0)
            }

            updateLock.signal()
        }
    }

    override func run() {
        // Application description & usage
        io.writeMessage(self)
        displayUsage()

        // Event Schedulers
        applicationEventScheduler.start()
        monomeEventScheduler.start()

        // Listen for user input
        var shouldQuit: Bool = false
        while !shouldQuit {
            io.displayCarrot(name)
            guard let input = io.getInput() else {
                continue
            }
            switch input {
            case "q":
                shouldQuit = true
            case "r":
                updateLock.wait()
                isRunning = true;
                updateLock.signal()
                continue
            case "s":
                updateLock.wait()
                isRunning = false
                updateLock.signal()
                continue
            default:
                displayUsage()
                io.displayCarrot(name)
                continue
            }
        }

        // All done
        monome.all(0)
        quit(EXIT_SUCCESS)
    }

    override func quit(_ exitStatus: Int32) {
        applicationEventScheduler.stop()
        monomeEventScheduler.stop()
        super.quit(exitStatus)
    }
}

extension Life {

    static func defaultState(columns: Int, rows: Int) -> [[Cell]] {
        var cells: [[Cell]] = Array()
        for x in 0..<columns {
            var column: [Cell] = Array()
            for y in 0..<rows {
                let cell = Cell(coordinate: Point(x: x, y: y))
                column.append(cell)
            }
            cells.append(column)
        }
        return cells
    }

    func tick() {
        guard isRunning else {
            return
        }
        for x in 0..<columns {
            for y in 0..<rows {
                let cell = state[x][y]

                if cell.modNext {
                    if cell.isAlive {
                        cell.isAlive = false
                        cell.modNeighbors(state, delta: -1)
                        monome.off(x: x, y: y)
                    } else {
                        cell.isAlive = true
                        cell.modNeighbors(state, delta: 1)
                        monome.on(x: x, y: y)
                    }
                    cell.modNext = false
                }
            }
        }

        for x in 0..<columns {
            for y in 0..<rows {
                let cell = state[x][y]

                switch cell.nnum {
                case 3:
                    if !cell.isAlive {
                        cell.modNext = true
                    }
                case 2:
                    break
                default:
                    if cell.isAlive {
                        cell.modNext = true
                    }
                    break
                }
            }
        }
    }
}
