#if os(Linux)
import Glibc
#else
import Darwin
#endif
import SwiftMonome

print("Initializing Monome...")
guard let monome = Monome("/dev/cu.usbserial-m1000286") else {
    print("Error: Monome Initialization Failed")
    exit(EXIT_FAILURE)
}
print("Monome Initialized")
print(monome)

monome.all(status: .off)

monome.registerGridHandler { (monome: Monome, event: GridEvent) in
    switch event.action {
    case .buttonDown:
//        monome.levelMap(xOffset: event.x, yOffset: 0, data: [[.l15, .l15, .l15, .l15, .l15, .l15, .l15, .l15],
//                                                             [.l14, .l14, .l14, .l14, .l14, .l14, .l14, .l14],
//                                                             [.l13, .l13, .l13, .l13, .l13, .l13, .l13, .l13],
//                                                             [.l12, .l12, .l12, .l12, .l12, .l12, .l12, .l12],
//                                                             [.l11, .l11, .l11, .l11, .l11, .l11, .l11, .l11],
//                                                             [.l10, .l10, .l10, .l10, .l10, .l10, .l10, .l10],
//                                                             [.l06, .l06, .l06, .l06, .l06, .l06, .l06, .l06],
//                                                             [.l13, .l13, .l13, .l13, .l13, .l13, .l13, .l13]])
//        monome.map(xOffset: event.x, yOffset: 0, data: [[.off, .on, .off, .on, .off, .on, .off, .on],
//                                                        [.on, .on, .off, .on, .off, .on, .off, .on],
//                                                        [.off, .on, .off, .on, .off, .on, .off, .on],
//                                                        [.off, .on, .off, .on, .off, .on, .off, .on],
//                                                        [.off, .on, .off, .on, .off, .on, .off, .on],
//                                                        [.off, .on, .off, .on, .off, .on, .off, .on],
//                                                        [.off, .on, .off, .on, .off, .on, .off, .on],
//                                                        [.off, .on, .off, .on, .off, .on, .off, .on]])
        var columnData = [LED.Status](repeating: .on, count: Int(monome.rows))
        columnData[Int(event.y)] = .off
        monome.column(x: event.x, yOffset: event.y % 8, data: columnData)
        var rowData = [LED.Status](repeating: .on, count: Int(monome.columns))
        rowData[Int(event.x)] = .off
        monome.row(xOffset: event.x % 8, y: event.y, data: rowData)
    case .buttonUp:
        monome.all(status: .off)
    }
    print(event)
}

while(true) {
    monome.eventHandleNext()
}
