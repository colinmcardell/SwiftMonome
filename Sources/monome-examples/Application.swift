//
//  Application.swift
//  SwiftMonome - monome-examples
//
//  Colin McArdell <colin@colinmcardell.com>
//

#if os(Linux)
import Glibc
#else
import Darwin
#endif

import SwiftMonome

class Application: CustomStringConvertible {

    let monome: Monome
    let io: ConsoleIO
    var name: String = "" // TODO: This doesn't need to exists if I have static funcs that do the same thing
    var description: String = "" // TODO: This doesn't need to exists if I have static funcs that do the same thing

    weak var delegate: ApplicationDelegate?

    init(monome: Monome, io: ConsoleIO) {
        self.monome = monome
        self.io = io

        self.monome.gridEventDelegate = self
    }

    func gridEvent(event: GridEvent) {
        fatalError("Must override in subclass")
    }

    func run() {
        fatalError("Must override in subclass")
    }
    func quit(_ exitStatus: Int32) {
        monome.clearEventHandlers()
        monome.gridEventDelegate = nil
        delegate?.applicationDidFinish(self, exitStatus: exitStatus)
    }
}

// Application - Event Handling
extension Application: MonomeGridEventDelegate {

    func handleGridEvent(monome: Monome, event: GridEvent) {
        gridEvent(event: event)
    }
}

protocol ApplicationDelegate: AnyObject {

    func applicationDidFinish(_ application: Application, exitStatus: Int32)
}
