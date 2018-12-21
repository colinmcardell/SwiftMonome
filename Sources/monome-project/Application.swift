import SwiftMonome

protocol Application: CustomStringConvertible {
    var monome: Monome { get }
    var io: ConsoleIO { get }
    var name: String { get }

    func run()
    func quit(_ exitStatus: Int32)
}

protocol ApplicationDelegate: AnyObject {
    func applicationDidFinish(_ application: Application, exitStatus: Int32)
}
