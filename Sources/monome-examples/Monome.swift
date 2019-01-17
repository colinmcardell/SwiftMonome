import SwiftMonome
import Foundation

extension Monome {

    func clearEventHandlers() {
        arcEventHandler = nil
        gridEventHandler = nil
        tiltEventHandler = nil
    }
}

class MonomeEventScheduler: EventScheduler {

    let monome: Monome

    init(monome: Monome) {
        self.monome = monome
        super.init(.highPriority)

        self.eventHandler = { [weak self] in
            self?.monome.eventHandleNext()
        }
    }
}
