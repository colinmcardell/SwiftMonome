import SwiftMonome

extension Monome {
    func clearHandlers() {
        unregisterHandler()
        unregisterArcHandler()
        unregisterGridHandler()
        unregisterTiltHandler()
    }
}
