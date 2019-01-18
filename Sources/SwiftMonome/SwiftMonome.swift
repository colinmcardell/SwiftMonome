import clibmonome

// MARK: - Event Callbacks
public typealias MonomeEventHandler = ((Event) -> Void)

public typealias MonomeGridEventHandler = ((GridEvent) -> Void)

public typealias MonomeArcEventHandler = ((ArcEvent) -> Void)

public typealias MonomeTiltEventHandler = ((TiltEvent) -> Void)

// MARK: - Event Delegate
public protocol MonomeEventDelegate: AnyObject {
    func handleEvent(monome: Monome, event: Event)
}

public protocol MonomeGridEventDelegate: AnyObject {
    func handleGridEvent(monome: Monome, event: GridEvent)
}

public protocol MonomeArcEventDelegate: AnyObject {
    func handleArcEvent(monome: Monome, event: ArcEvent)
}

public protocol MonomeTiltEventDelegate: AnyObject {
    func handleTiltEvent(monome: Monome, event: TiltEvent)
}

public final class Monome {

    public static let DefaultDevice = "osc.udp://127.0.0.1:8080/monome"

    public let monome: OpaquePointer!

    public var eventDelegate: MonomeEventDelegate?

    public var gridEventDelegate: MonomeGridEventDelegate?

    public var arcEventDelegate: MonomeArcEventDelegate?

    public var tiltEventDelegate: MonomeTiltEventDelegate?

    public var eventHandler: MonomeEventHandler?

    public var gridEventHandler: MonomeGridEventHandler?

    public var arcEventHandler: MonomeArcEventHandler?

    public var tiltEventHandler: MonomeTiltEventHandler?

    // Lifecycle
    public init?(_ device: String = DefaultDevice) {
        guard let monome = monome_connect(device, "8000") else {
            return nil
        }
        self.monome = monome

        // Register internal handler for each of the event types
        let pMonome = Unmanaged.passUnretained(self).toOpaque()
        UnderlyingEventType.allCases.forEach { type in
            monome_register_handler(self.monome, type.cType, _underlyingEventHandler, pMonome)
        }
    }
    deinit {
        UnderlyingEventType.allCases.forEach { eventType in
            monome_unregister_handler(monome, eventType.cType)
        }
        monome_close(monome)
    }
}

// MARK: - Monome: Computed Properties
extension Monome: CustomStringConvertible {
    public var rotation: Rotation {
        get {
            return Rotation(monome_get_rotation(monome))
        }
        set {
            monome_set_rotation(monome, newValue.cRotation)
        }
    }
    public var serial: String? {
        guard let serial = monome_get_serial(monome) else {
            return nil
        }
        return String(cString: serial)
    }
    public var devicePath: String? {
        guard let devicePath = monome_get_devpath(monome) else {
            return nil
        }
        return String(cString: devicePath)
    }
    public var friendlyName: String? {
        guard let friendlyName = monome_get_friendly_name(monome) else {
            return nil
        }
        return String(cString: friendlyName)
    }
    public var monomeProtocol: String? {
        guard let proto = monome_get_proto(monome) else {
            return nil
        }
        return String(cString: proto)
    }
    public var rows: Int32 {
        return monome_get_rows(monome)
    }
    public var columns: Int32 {
        get {
            return monome_get_cols(monome)
        }
    }
    public var description: String {
        return """
        Rotation: \(rotation)
        Serial: \(serial ?? "Undefined")
        Device Path: \(devicePath ?? "Unknown")
        Friendly Name: \(friendlyName ?? "Unknown")
        Protocol: \(monomeProtocol ?? "Unknown")
        Rows: \(rows)
        Columns: \(columns)
        """
    }
}

// MARK: - Monome: Public Functions
extension Monome {
    public func eventHandleNext() {
        monome_event_handle_next(monome)
    }
    public func eventLoop() {
        monome_event_loop(monome)
    }
    public func getFd() -> Int32 {
        return monome_get_fd(monome)
    }

    // MARK: - Monome: Grid Commands
    public func set(x: Int, y: Int, status: UInt8) {
        monome_led_set(monome, UInt32(x), UInt32(y), UInt32(status))
    }

    public func on(x: Int, y: Int) {
        monome_led_on(monome, UInt32(x), UInt32(y))
    }
    public func off(x: Int, y: Int) {
        monome_led_off(monome, UInt32(x), UInt32(y))
    }

    public func all(_ status: UInt8) {
        monome_led_all(monome, UInt32(status))
    }

    public func map(x: Int, y: Int, data: [UInt8]) {
        monome_led_map(monome, UInt32(x), UInt32(y), data)
    }

    /// Set a column by sending either an array of 0s or 1s or a byte buffer.
    /// The values of the provided data corresponds to the on/off values of the
    /// LEDs at the provided coordinates.
    ///
    /// - Parameters:
    ///   - x: The `x` coordinate of the row to be rendered.
    ///   - y: The `y` offset to be applied to the column data.
    ///   - count: Number of "bits" contained in the data array (aka number of LEDs to set in the column).
    ///   - data: An array of values, either UInt8 values of 0 or 1, or an actual byte buffer (let data = UInt8(0b010101)). The former being the default, where each element in the array is treated as a bit and the values are packed up into a byte buffer before sending them to the device, the latter being non-default and configurable by setting `shouldReduceBytes` to `false`.
    ///   - shouldReduceBytes: Optional value that is used to indicate if the `data` passed to this function should be treated as an array of UInt8 with each value either 0 or 1 (which means that it should be reduced to a byte buffer), or if the `data` is already a byte buffer.
    public func column(x: Int, y: Int, count: Int, data: [UInt8], shouldReduceBytes: Bool = true) {
        monome_led_col(monome, UInt32(x), UInt32(y), count, shouldReduceBytes ? data.pack() : data)
    }
    public func column(x: Int, y: Int, data: [UInt8], shouldReduceBytes: Bool = true) {
        let d = shouldReduceBytes ? data.pack() : data
        column(x: x, y: y, count: d.count, data: d, shouldReduceBytes: false)
    }

    /// Set a row by sending either an array of 0s or 1s or a byte buffer. The
    /// values of the provided data corresponds to the on/off values of the LEDs
    /// at the provided coordinates.
    ///
    /// - Parameters:
    ///   - x: The `x` offset to be applied to the row data.
    ///   - y: The `y` coordinate of the row to be rendered.
    ///   - count: Number of "bits" contained in the data array (aka number of LEDs to set in the column).
    ///   - data: An array of values, either UInt8 values of 0 or 1, or an actual byte buffer (let data = UInt8(0b010101)). The former being the default, where each element in the array is treated as a bit and the values are packed up into a byte buffer before sending them to the device, the latter being non-default and configurable by setting `shouldReduceBytes` to `false`.
    ///   - shouldReduceBytes: Optional value that is used to indicate if the `data` passed to this function should be treated as an array of UInt8 with each value either 0 or 1 (which means that it should be reduced to a byte buffer), or if the `data` is already a byte buffer.
    public func row(x: Int, y: Int, count: Int, data: [UInt8], shouldReduceBytes: Bool = true) {
        monome_led_row(monome, UInt32(x), UInt32(y), count, shouldReduceBytes ? data.pack() : data)
    }
    public func row(x: Int, y: Int, data: [UInt8], shouldReduceBytes: Bool = true) {
        let d = shouldReduceBytes ? data.pack() : data
        row(x: x, y: y, count: d.count, data: data, shouldReduceBytes: false)
    }

    public func intensity(_ level: UInt8) {
        monome_led_intensity(monome, UInt32(level))
    }

    public func levelSet(x: Int, y: Int, level: UInt8) {
        monome_led_level_set(monome, UInt32(x), UInt32(y), UInt32(level))
    }

    public func levelAll(_ level: UInt8) {
        monome_led_level_all(monome, UInt32(level))
    }

    public func levelMap(x: Int, y: Int, data: [UInt8]) {
        monome_led_level_map(monome, UInt32(x), UInt32(y), data)
    }

    public func levelRow(x: Int, y: Int, count: Int, data: [UInt8]) {
        monome_led_level_row(monome, UInt32(x), UInt32(y), count, data)
    }

    public func levelColumn(x: Int, y: Int, count: Int, data: [UInt8]) {
        monome_led_level_col(monome, UInt32(x), UInt32(y), count, data)
    }

    // MARK: - Monome: LED Ring Commands
    public func ringSet(ring: Int, led: Int, level: UInt8) {
        monome_led_ring_set(monome, UInt32(ring), UInt32(led), UInt32(level))
    }

    public func ringAll(ring: Int, level: UInt8) {
        monome_led_ring_all(monome, UInt32(ring), UInt32(level))
    }

    public func ringMap(ring: Int, levels: [UInt8]) {
        monome_led_ring_map(monome, UInt32(ring), levels)
    }

    public func ringRange(ring: Int, start: Int, end: Int, level: UInt8) {
        monome_led_ring_range(monome, UInt32(ring), UInt32(start), UInt32(end), UInt32(level))
    }

    // MARK: - Monome: Tilt Commands
    public func tiltEnable(for sensor: Int) {
        monome_tilt_enable(monome, UInt32(sensor))
    }
    public func tiltDisable(for sensor: Int) {
        monome_tilt_disable(monome, UInt32(sensor))
    }
}

// MARK: - Monome: Private
fileprivate extension Monome {
    func _handleEvent(_ event: Event) {
        switch event {
        case is GridEvent:
            gridEventHandler?(event as! GridEvent)
            gridEventDelegate?.handleGridEvent(monome: self, event: event as! GridEvent)
            break
        case is ArcEvent:
            arcEventHandler?(event as! ArcEvent)
            arcEventDelegate?.handleArcEvent(monome: self, event: event as! ArcEvent)
            break
        case is TiltEvent:
            tiltEventHandler?(event as! TiltEvent)
            tiltEventDelegate?.handleTiltEvent(monome: self, event: event as! TiltEvent)
            break
        default: break
        }
        eventHandler?(event)
        eventDelegate?.handleEvent(monome: self, event: event)
    }
}
fileprivate func _underlyingEventHandler(monomeEvent: UnsafePointer<monome_event_t>?, userData: UnsafeMutableRawPointer?) {
    guard let monomeEvent = monomeEvent, let userData = userData else {
        return
    }
    let monome: Monome = Unmanaged<Monome>.fromOpaque(userData).takeUnretainedValue()

    var event: Event
    switch monomeEvent.pointee.event_type {
    case MONOME_BUTTON_UP, MONOME_BUTTON_DOWN:
        event = GridEvent(monomeEvent)
    case MONOME_ENCODER_DELTA, MONOME_ENCODER_KEY_UP, MONOME_ENCODER_KEY_DOWN:
        event = ArcEvent(monomeEvent)
    case MONOME_TILT:
        event = TiltEvent(monomeEvent)
    default:
        return
    }
    monome._handleEvent(event)
}

// MARK: - Events & Actions
public protocol Event: CustomStringConvertible {
    init(_ event: UnsafePointer<monome_event_t>)
    var cEvent: UnsafePointer<monome_event_t> { get }
}

extension Event {
    var type: UnderlyingEventType {
        return UnderlyingEventType(cEvent.pointee.event_type)
    }
}

/// Grid specific event
public struct GridEvent: Event {
    public enum Action: CustomStringConvertible {
        case buttonDown
        case buttonUp

        public var description: String {
            switch self {
            case .buttonDown:
                return "Button Down"
            case .buttonUp:
                return "Button Up"
            }
        }
    }
    public init(_ event: UnsafePointer<monome_event_t>) {
        self.cEvent = event
    }
    public var cEvent: UnsafePointer<monome_event_t>
    public var description: String {
        return "Monome Grid Event – x: \(x), y: \(y), action: \(action)"
    }

    public var x: Int {
        return Int(cEvent.pointee.grid.x)
    }
    public var y: Int {
        return Int(cEvent.pointee.grid.y)
    }
    public var action: GridEvent.Action {
        return Action(cEvent.pointee.event_type)
    }
}
extension GridEvent.Action {
    init(_ eventType: monome_event_type_t) {
        if eventType == MONOME_BUTTON_UP {
            self = .buttonUp
        } else {
            self = .buttonDown
        }
    }
}

/// Arc specific event
public struct ArcEvent: Event {
    public enum Action: CustomStringConvertible {
        case delta
        case keyUp
        case keyDown

        public var description: String {
            switch self {
            case .delta:
                return "Delta"
            case .keyUp:
                return "Key Up"
            case .keyDown:
                return "Key Down"
            }
        }
    }
    public init(_ event: UnsafePointer<monome_event_t>) {
        self.cEvent = event
    }
    public var cEvent: UnsafePointer<monome_event_t>
    public var description: String {
        return "Monome Arc Event – number: \(number), delta: \(delta), action: \(action)"
    }

    public var number: Int {
        return Int(cEvent.pointee.encoder.number)
    }
    public var delta: Int {
        return Int(cEvent.pointee.encoder.delta)
    }
    public var action: ArcEvent.Action {
        return Action(cEvent.pointee.event_type)
    }
}
extension ArcEvent.Action {
    init(_ eventType: monome_event_type_t) {
        switch eventType {
        case MONOME_ENCODER_DELTA: self = .delta
        case MONOME_ENCODER_KEY_UP: self = .keyUp
        case MONOME_ENCODER_KEY_DOWN: self = .keyDown
        default: self = .delta
        }
    }
}

/// Tilt event
public struct TiltEvent: Event {
    public init(_ event: UnsafePointer<monome_event_t>) {
        self.cEvent = event
    }
    public var cEvent: UnsafePointer<monome_event_t>
    public var description: String {
        return "Monome Tilt Event – sensor:\(sensor) x:\(x) y:\(y) z:\(z)"
    }

    public var sensor: Int {
        return Int(cEvent.pointee.tilt.sensor)
    }
    public var x: Int {
        return Int(cEvent.pointee.tilt.x)
    }
    public var y: Int {
        return Int(cEvent.pointee.tilt.y)
    }
    public var z: Int {
        return Int(cEvent.pointee.tilt.z)
    }
}

// MARK: - Convenience Wrappers
public enum Rotation {
    case left
    case bottom
    case right
    case top
}

extension Rotation {
    init(_ rotation: monome_rotate_t) {
        switch rotation {
        case MONOME_ROTATE_0: self = .left
        case MONOME_ROTATE_90: self = .bottom
        case MONOME_ROTATE_180: self = .right
        case MONOME_ROTATE_270: self = .top
        default: self = .left
        }
    }
    var cRotation: monome_rotate_t {
        switch self {
        case .left: return MONOME_ROTATE_0
        case .bottom: return MONOME_ROTATE_90
        case .right: return MONOME_ROTATE_180
        case .top: return MONOME_ROTATE_270
        }
    }
}

enum UnderlyingEventType: CaseIterable {
    case buttonUp
    case buttonDown
    case encoderDelta
    case encoderKeyUp
    case encoderKeyDown
    case tilt
}

extension UnderlyingEventType {
    init(_ type: monome_event_type_t) {
        switch type {
        case MONOME_BUTTON_UP: self = .buttonUp
        case MONOME_BUTTON_DOWN: self = .buttonDown
        case MONOME_ENCODER_DELTA: self = .encoderDelta
        case MONOME_ENCODER_KEY_UP: self = .encoderKeyUp
        case MONOME_ENCODER_KEY_DOWN: self = .encoderKeyDown
        case MONOME_TILT: self = .tilt
        case MONOME_EVENT_MAX: self = .buttonUp
        default: self = .buttonUp
        }
    }
    var cType: monome_event_type_t {
        switch self {
        case .buttonUp: return MONOME_BUTTON_UP
        case .buttonDown: return MONOME_BUTTON_DOWN
        case .encoderDelta: return MONOME_ENCODER_DELTA
        case .encoderKeyUp: return MONOME_ENCODER_KEY_UP
        case .encoderKeyDown: return MONOME_ENCODER_KEY_DOWN
        case .tilt: return MONOME_TILT
        }
    }
}

extension Array where Element == UInt8 {
    func pack() -> [UInt8] {
        let numBytes = (count + 7) / 8
        var bytes = [UInt8](repeating: 0, count: numBytes)

        for (index, value) in self.enumerated() {
            if value == 1 {
                bytes[index / 8] += UInt8(1 << (index % 8))
            }
        }
        return bytes
    }
}
