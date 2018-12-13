import clibmonome

public typealias MonomeEventCallback = ((Monome, EventProtocol) -> Void)

public final class Monome {
    let monome: OpaquePointer
    var eventHandlers: [EventType: MonomeEventCallback] = [:]

    // MARK: - Lifecycle
    public init() {
        monome = monome_connect("osc.udp://127.0.0.1:19204/monome", "8000")
        let pMonome = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        EventType.allCases.forEach { eventType in
            monome_register_handler(monome, eventType.cType, monomeEventHandler, pMonome)
        }
    }
    deinit {
        EventType.allCases.forEach { eventType in
            monome_unregister_handler(monome, eventType.cType)
        }
        monome_close(monome)
    }

    // MARK: - Properties
    var rotation: Rotation {
        get {
            return Rotation(monome_get_rotation(monome))
        }
        set {
            monome_set_rotation(monome, newValue.cRotation)
        }
    }
    var serial: String? {
        get {
            return String(cString: monome_get_serial(monome))
        }
    }
    var devicePath: String? {
        get {
            return String(cString: monome_get_devpath(monome))
        }
    }
    var friendlyName: String? {
        get {
            return String(cString: monome_get_friendly_name(monome))
        }
    }
    var monomeProtocol: String? {
        get {
            return String(cString: monome_get_proto(monome))
        }
    }
    var rows: Int32 {
        get {
            return monome_get_rows(monome)
        }
    }
    var columns: Int32 {
        get {
            return monome_get_cols(monome)
        }
    }

    // MARK: - Public
    public func registerHandler(for eventType: EventType, callback: @escaping MonomeEventCallback) {
        eventHandlers[eventType] = callback
    }
    public func eventHandleNext() {
        monome_event_handle_next(monome)
    }
    // Grid Commands
    public func ledSet(x: UInt32, y: UInt32, status: MonomeLedStatus) {
        monome_led_set(monome, x, y, status.rawValue)
    }
    public func ledOn(x: UInt32, y: UInt32) {
        monome_led_on(monome, x, y)
    }
    public func ledOff(x: UInt32, y: UInt32) {
        monome_led_off(monome, x, y)
    }

    // MARK: - Private
    fileprivate func _handle(event: EventProtocol) {
        let handlers = eventHandlers.filter { (key, value) -> Bool in
            return event.type == key
        }
        handlers.values.forEach { handler in
            handler(self, event)
        }
    }
}

func monomeEventHandler(event: UnsafePointer<monome_event_t>?, userData: UnsafeMutableRawPointer?) {
    guard let userData = userData, let event = Event.event(for: event) else {
        return
    }
    let monome: Monome = Unmanaged<Monome>.fromOpaque(userData).takeUnretainedValue()
    monome._handle(event: event)
}
