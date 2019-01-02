import SwiftMonome
import Foundation

extension Monome {
    func clearHandlers() {
        unregisterHandler()
        unregisterArcHandler()
        unregisterGridHandler()
        unregisterTiltHandler()
    }
}

class MonomeEventScheduler {
    let monome: Monome
    let queue: DispatchQueue
    let timer: DispatchSourceTimer
    var interval: DispatchTimeInterval = .milliseconds(16)

    init(monome: Monome) {
        self.monome = monome
        self.queue = DispatchQueue.global(qos: .userInteractive)
        self.timer = DispatchSource.makeTimerSource(queue: self.queue)
        self.timer.setEventHandler { [weak self] in
            self?.monome.eventHandleNext()
        }
    }
    deinit {
        // TODO: This crashes
        timer.cancel()
    }

    func start() {
        timer.schedule(deadline: .now(), repeating: interval)
        timer.resume()
    }

    func stop() {
        timer.suspend()
    }
}
