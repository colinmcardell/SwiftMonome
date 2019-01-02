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
    }

    func run() {
        quit(EXIT_SUCCESS)
    }
    func quit(_ exitStatus: Int32) {
        delegate?.applicationDidFinish(self, exitStatus: exitStatus)
    }
}

protocol ApplicationDelegate: AnyObject {
    func applicationDidFinish(_ application: Application, exitStatus: Int32)
}
