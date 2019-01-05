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

class EventScheduler {

    enum SchedulerType {
        case highPriority
        case lowPriority
        case background
    }

    typealias EventHandler = DispatchSourceProtocol.DispatchSourceHandler

    let queue: DispatchQueue

    var timer: DispatchSourceTimer?

    var eventHandler: EventHandler?

    var interval: DispatchTimeInterval = .milliseconds(16)

    init(_ type: SchedulerType = .highPriority) {
        var dispatchQueue: DispatchQueue
        switch type {
        case .highPriority:
            dispatchQueue = DispatchQueue.global(qos: .userInitiated)
        case .lowPriority:
            dispatchQueue = DispatchQueue.global(qos: .utility)
        case .background:
            dispatchQueue = DispatchQueue.global(qos: .background)
        }
        self.queue = dispatchQueue
    }

    deinit {
        stop()
    }

    func start() {
        stop()
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.setEventHandler { [weak self] in
            guard let strongSelf = self, let eventHandler = strongSelf.eventHandler else { return }
            eventHandler()
        }
        timer?.schedule(deadline: .now(), repeating: interval)
        timer?.resume()
    }

    func stop() {
        guard let timer = timer else { return }
        timer.setEventHandler {}
        timer.cancel()
        self.timer = nil
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
