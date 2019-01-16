//
//  Life.swift
//
//  Conway's Game of Life
//
#if os(Linux)
import Glibc
#else
import Darwin
#endif
import Foundation
import SwiftMonome

struct Point {

    var x: UInt32
    var y: UInt32
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

    func neighbors(_ world: [[Cell]]) -> [Cell] {
        let columns: Int = world.count
        let rows: Int = world[0].count
        var neighbors: [Cell] = Array()
        var xOffset: Int = -1
        var yOffset: Int = -1
        neighbors.append(world[_mod(Int(coordinate.x) + xOffset, columns)][_mod(Int(coordinate.y) + yOffset, rows)]) // 0
        yOffset = 1
        neighbors.append(world[_mod(Int(coordinate.x) + xOffset, columns)][_mod(Int(coordinate.y) + yOffset, rows)]) // 1
        yOffset = 0
        neighbors.append(world[_mod(Int(coordinate.x) + xOffset, columns)][_mod(Int(coordinate.y) + yOffset, rows)]) // 2

        xOffset = 1
        yOffset = -1
        neighbors.append(world[_mod(Int(coordinate.x) + xOffset, columns)][_mod(Int(coordinate.y) + yOffset, rows)]) // 3
        yOffset = 1
        neighbors.append(world[_mod(Int(coordinate.x) + xOffset, columns)][_mod(Int(coordinate.y) + yOffset, rows)]) // 4
        yOffset = 0
        neighbors.append(world[_mod(Int(coordinate.x) + xOffset, columns)][_mod(Int(coordinate.y) + yOffset, rows)]) // 5

        xOffset = 0
        yOffset = -1
        neighbors.append(world[_mod(Int(coordinate.x) + xOffset, columns)][_mod(Int(coordinate.y) + yOffset, rows)]) // 6
        yOffset = 1
        neighbors.append(world[_mod(Int(coordinate.x) + xOffset, columns)][_mod(Int(coordinate.y) + yOffset, rows)]) // 7
        return neighbors
    }

    func modNeighbors(_ world: [[Cell]], delta: Int) {
        let neighbors = self.neighbors(world)
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
        io.writeMessage("   u - Display `\(name)` usage.")
        io.writeMessage("   q - Quit")
    }

    override func gridEvent(event: GridEvent) {
        if event.action == .buttonUp {
            updateLock.wait()
            state[Int(event.x)][Int(event.y)].modNext = true
            updateLock.signal()
        }
    }

    override func run() {
        // Application description & usage
        io.writeMessage(self)
        displayUsage()
        io.displayCarrot(name)

        // Event Schedulers
        applicationEventScheduler.start()
        monomeEventScheduler.start()

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
        applicationEventScheduler.stop()
        monomeEventScheduler.stop()
        super.quit(exitStatus)
    }
}

extension Life {

    static func defaultState(columns: Int, rows: Int) -> [[Cell]] {
        var state: [[Cell]] = Array()
        for x in 0..<columns {
            var column: [Cell] = Array()
            for y in 0..<rows {
                let cell = Cell(coordinate: Point(x: UInt32(x), y: UInt32(y)))
                column.append(cell)
            }
            state.append(column)
        }
        return state
    }

    func tick() {
        for x in 0..<columns {
            for y in 0..<rows {
                let cell = state[x][y]

                if cell.modNext {
                    if cell.isAlive {
                        cell.isAlive = false
                        cell.modNeighbors(state, delta: -1)
                        monome.off(x: UInt32(x), y: UInt32(y))
                    } else {
                        cell.isAlive = true
                        cell.modNeighbors(state, delta: 1)
                        monome.on(x: UInt32(x), y: UInt32(y))
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
