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
    func neighbors(_ world: [[Cell]]) -> [Cell] {
        let columns: Int = world.count
        let rows: Int = world[0].count
        var neighbors: [Cell] = Array()
        neighbors[0] = world[(Int(coordinate.x) - 1) % columns][(Int(coordinate.y) - 1) % rows]
        neighbors[1] = world[(Int(coordinate.x) - 1) % columns][(Int(coordinate.y) + 1) % rows]
        neighbors[2] = world[(Int(coordinate.x) - 1) % columns][(Int(coordinate.y)) % rows]

        neighbors[3] = world[(Int(coordinate.x) + 1) % columns][(Int(coordinate.y) - 1) % rows]
        neighbors[4] = world[(Int(coordinate.x) + 1) % columns][(Int(coordinate.y) + 1) % rows]
        neighbors[5] = world[(Int(coordinate.x) + 1) % columns][(Int(coordinate.y)) % rows]

        neighbors[6] = world[(Int(coordinate.x)) % columns][(Int(coordinate.y) - 1) % rows]
        neighbors[7] = world[(Int(coordinate.x)) % columns][(Int(coordinate.y) + 1) % rows]
        return neighbors
    }

    func modNeighbors(_ world: [[Cell]], delta: Int) {
        let neighbors = self.neighbors(world)
        for cell in neighbors {
            // TODO: What is happening here? Casting an Int to a UInt8 is going to do what to our number value.
            cell.nnum += UInt8(delta)
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

    let scheduler: MonomeEventScheduler
    let columns: Int
    let rows: Int
    var state: [[Cell]]

    override init(monome: Monome, io: ConsoleIO) {
        self.scheduler = MonomeEventScheduler(monome: monome)
        self.columns = monome.columns == 0 ? 16 : Int(monome.columns)
        self.rows = monome.rows == 0 ? 16 : Int(monome.rows)
        self.state = Life.defaultState(columns: self.columns, rows: self.rows)

        super.init(monome: monome, io: io)
        self.name = Life.name()
        self.description = Life.description()
    }

    func displayUsage() {
        io.writeMessage("Usage:")
        io.writeMessage("   u - Display `\(name)` usage.")
        io.writeMessage("   q - Quit")
    }

    override func run() {
        // Monome setup & application state
        monome.registerGridHandler { [weak self] (monome: Monome, event: GridEvent) in
            if event.action == .buttonUp {
                // Toggle grid button LED status
//                guard let strongSelf = self else {
//                    return
//                }
//                let x = event.x
//                let y = event.y
//                let col = Int(x)
//                let row = Int(y)

//                let status = strongSelf.state[row][col]
//                let nextStatus: LED.Status = status == .on ? .off : .on
//                monome.set(x: x, y: y, status: nextStatus)
//                strongSelf.state[row][col] = nextStatus
            }
        }

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
        delegate?.applicationDidFinish(self, exitStatus: exitStatus)
    }
}

extension Life {
    static func defaultState(columns: Int, rows: Int) -> [[Cell]] {
        var state: [[Cell]] = Array()
        for x in 0..<columns {
            var column: [Cell] = Array()
            for y in 0..<rows {
                let cell = Cell()
                cell.coordinate = Point(x: x, y: y)
                column.append(cell)
            }
            state.append(column)
        }
        return state
    }

    static func updateState(_ state: [[Cell]]) {
        let columns: Int = state.count
        let rows: Int = state[0].count

        for x in 0..<columns {
            for y in 0..<rows {
                let cell = state[x][y]

                if cell.modNext {
                    var delta: Int = 0
                    if cell.isAlive {
                        cell.isAlive = false
                        delta = 1
                    } else {
                        cell.isAlive = true
                        delta = -1
                    }
                    cell.modNeighbors(state, delta: delta)
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
                    break
                case 2:
                    break
                default:
                    if cell.isAlive {
                        cell.modNext = true
                    }
                }
            }
        }
    }

    func chill(_ msec: Int) {
        var rem = timespec(tv_sec: 0, tv_nsec: 0)
        var req = timespec(tv_sec: msec * 1000000, tv_nsec: (msec * 1000000) / 1000000000)
        req.tv_nsec = req.tv_nsec - req.tv_sec * 1000000000
        nanosleep(&req, &rem)
    }

    func modNeighbors(_ coordinates: [Point], delta: UInt8) {
        coordinates.forEach { point in
            var cell = state[point.x][point.y]
            cell.nnum = cell.nnum + delta
            state[point.x][point.y] = cell
        }
    }

    func tick() {
//        var nextWorld = Array(repeating: Array(repeating: Cell(), count: columns), count: rows)
//        for x in 0..<columns {
//            for y in 0..<rows {
//                let cell = state[x][y]
//
//            }
//        }
//        for (x, row) in state.enumerated() {
//            for (y, cell) in row.enumerated() {
//                if cell.modNext != 0 {
////                    cell.isAlive = !cell.isAlive
//                }
//            }
//        }
    }
}
