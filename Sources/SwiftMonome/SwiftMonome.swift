import clibmonome

//public typealias MonomeEventCallback = monome_event_callback_t
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
    public func registerHandler(for eventType: EventType, callback: MonomeEventCallback) {

    }
    public func eventHandleNext() {
        monome_event_handle_next(monome)
    }

    // MARK: - Private
    fileprivate func _handle(event: EventProtocol) {
        print(event)
    }
}

func monomeEventHandler(event: UnsafePointer<monome_event_t>?, userData: UnsafeMutableRawPointer?) {
    guard let userData = userData, let event = Event.event(for: event) else {
        return
    }
    let monome: Monome = Unmanaged<Monome>.fromOpaque(userData).takeUnretainedValue()
    monome._handle(event: event)
}
