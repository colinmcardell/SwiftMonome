#if os(Linux)
import Glibc
#else
import Darwin
#endif
import SwiftMonome

class Application: CustomStringConvertible {
    let monome: Monome
    let io: ConsoleIO
    var name: String = ""
    var description: String = ""

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
