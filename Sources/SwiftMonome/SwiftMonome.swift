import clibmonome

// MARK: - Monome
public typealias MonomeEventCallback = ((Monome, Event) -> Void)
public typealias MonomeGridCallback = ((Monome, GridEvent) -> Void)
public typealias MonomeArcCallback = ((Monome, ArcEvent) -> Void)
public typealias MonomeTiltCallback = ((Monome, TiltEvent) -> Void)

public final class Monome {
    public static let DefaultDevice = "osc.udp://127.0.0.1:8080/monome"
    public let monome: OpaquePointer!
    var eventHandler: MonomeEventCallback?
    var gridCallback: MonomeGridCallback?
    var arcCallback: MonomeArcCallback?
    var tiltCallback: MonomeTiltCallback?

    // Lifecycle
    public init?(_ device: String = DefaultDevice) {
        guard let monome = monome_connect(device, "8000") else {
            return nil
        }
        self.monome = monome

        // Register internal handler for each of the event types
        let pMonome = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
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
    public func registerHandler(_ handler: @escaping MonomeEventCallback) {
        eventHandler = handler
    }
    public func unregisterHandler() {
        eventHandler = nil
    }
    public func registerGridHandler(_ handler: @escaping MonomeGridCallback) {
        gridCallback = handler
    }
    public func unregisterGridHandler() {
        gridCallback = nil
    }
    public func registerArcHandler(_ handler: @escaping MonomeArcCallback) {
        arcCallback = handler
    }
    public func unregisterArcHandler() {
        arcCallback = nil
    }
    public func registerTiltHandler(_ handler: @escaping MonomeTiltCallback) {
        tiltCallback = handler
    }
    public func unregisterTiltHandler() {
        tiltCallback = nil
    }
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
    public func set(x: UInt32, y: UInt32, status: UInt32) {
        monome_led_set(monome, x, y, status)
    }
    public func set(x: UInt32, y: UInt32, status: LED.Status) {
        set(x: x, y: y, status: status.rawValue)
    }

    public func on(x: UInt32, y: UInt32) {
        monome_led_on(monome, x, y)
    }
    public func off(x: UInt32, y: UInt32) {
        monome_led_off(monome, x, y)
    }

    public func all(_ status: UInt32) {
        monome_led_all(monome, status)
    }
    public func all(_ status: LED.Status) {
        all(status.rawValue)
    }

    public func map(xOffset: UInt32, yOffset: UInt32, data: UnsafePointer<UInt8>!) {
        monome_led_map(monome, xOffset, yOffset, data)
    }
    public func map(xOffset: UInt32, yOffset: UInt32, data: [[LED.Status]]) {
        // TODO: Return type (-1 is an error, I think...)
        map(xOffset: xOffset, yOffset: yOffset, data: data.toBytes())
    }

    public func column(x: UInt32, yOffset: UInt32, count: Int, data: UnsafePointer<UInt8>!) {
        monome_led_col(monome, x, yOffset, count, data)
    }
    public func column(x: UInt32, yOffset: UInt32, data: [LED.Status]) {
        // TODO: Return type (-1 is an error, I think...)
        let bytes = data.toBytes()
        column(x: x, yOffset: yOffset, count: bytes.count, data: bytes)
    }

    public func row(xOffset: UInt32, y: UInt32, count: Int, data: UnsafePointer<UInt8>!) {
        monome_led_row(monome, xOffset, y, count, data)
    }
    public func row(xOffset: UInt32, y: UInt32, data: [LED.Status]) {
        // TODO: Return type (-1 is an error, I think...)
        let bytes = data.toBytes()
        row(xOffset: xOffset, y: y, count: bytes.count, data: bytes)
    }

    public func intensity(_ level: UInt32) {
        monome_led_intensity(monome, level)
    }
    public func intensity(_ level: LED.Level) {
        // TODO: Return type (-1 is an error, I think...)
        intensity(level.rawValue)
    }

    public func levelSet(x: UInt32, y: UInt32, level: UInt32) {
        // TODO: Return type (-1 is an error, I think...)
        monome_led_level_set(monome, x, y, level)
    }
    public func levelSet(x: UInt32, y: UInt32, level: LED.Level) {
        // TODO: Return type (-1 is an error, I think...)
        levelSet(x: x, y: y, level: level.rawValue)
    }

    public func levelAll(_ level: UInt32) {
        monome_led_level_all(monome, level)
    }
    public func levelAll(_ level: LED.Level) {
        // TODO: Return type (-1 is an error, I think...)
        levelAll(level.rawValue)
    }

    public func levelMap(xOffset: UInt32, yOffset: UInt32, data: UnsafePointer<UInt8>!) {
        monome_led_level_map(monome, xOffset, yOffset, data)
    }
    public func levelMap(xOffset: UInt32, yOffset: UInt32, data: [[LED.Level]]) {
        // TODO: Return type (-1 is an error, I think...)
        levelMap(xOffset: xOffset, yOffset: yOffset, data: data.toBytes())
    }

    public func levelRow(xOffset: UInt32, y: UInt32, count: Int, data: UnsafePointer<UInt8>!) {
        // TODO: Return type (-1 is an error, I think...)
        monome_led_level_row(monome, xOffset, y, count, data)
    }
    public func levelRow(xOffset: UInt32, y: UInt32, data: [LED.Level]) {
        // TODO: Return type (-1 is an error, I think...)
        levelRow(xOffset: xOffset, y: y, count: data.count, data: data.toBytes())
    }

    public func levelColumn(x: UInt32, yOffset: UInt32, count: Int, data: UnsafePointer<UInt8>!) {
        // TODO: Return type (-1 is an error, I think...)
        monome_led_level_col(monome, x, yOffset, count, data)
    }
    public func levelColumn(x: UInt32, yOffset: UInt32, data: [LED.Level]) {
        // TODO: Return type (-1 is an error, I think...)
        levelColumn(x: x, yOffset: yOffset, count: data.count, data: data.toBytes())
    }

    // MARK: - Monome: LED Ring Commands
    public func ringSet(ring: UInt32, led: UInt32, level: UInt32) {
        // TODO: Return type (-1 is an error, I think...)
        monome_led_ring_set(monome, ring, led, level)
    }
    public func ringSet(ring: UInt32, led: UInt32, level: LED.Level) {
        // TODO: Return type (-1 is an error, I think...)
        ringSet(ring: ring, led: led, level: level.rawValue)
    }

    public func ringAll(ring: UInt32, level: UInt32) {
        // TODO: Return type (-1 is an error, I think...)
        monome_led_ring_all(monome, ring, level)
    }
    public func ringAll(ring: UInt32, level: LED.Level) {
        // TODO: Return type (-1 is an error, I think...)
        ringAll(ring: ring, level: level.rawValue)
    }

    public func ringMap(ring: UInt32, levels: UnsafePointer<UInt8>!) {
        monome_led_ring_map(monome, ring, levels)
    }
    public func ringMap(ring: UInt32, levels: [[LED.Level]]) {
        // TODO: Return type (-1 is an error, I think...)
        ringMap(ring: ring, levels: levels.toBytes())
    }

    public func ringRange(ring: UInt32, start: UInt32, end: UInt32, level: UInt32) {
        // TODO: Return type (-1 is an error, I think...)
        monome_led_ring_range(monome, ring, start, end, level)
    }
    public func ringRange(ring: UInt32, start: UInt32, end: UInt32, level: LED.Level) {
        // TODO: Return type (-1 is an error, I think...)
        ringRange(ring: ring, start: start, end: end, level: level.rawValue)
    }

    // MARK: - Monome: Tilt Commands
    public func tiltEnable(for sensor: UInt32) {
        // TODO: Return type (-1 is an error, I think...)
        monome_tilt_enable(monome, sensor)
    }
    public func tiltDisable(for sensor: UInt32) {
        // TODO: Return type (-1 is an error, I think...)
        monome_tilt_disable(monome, sensor)
    }
}

// MARK: - Monome: Private
fileprivate extension Monome {
    func _handleEvent(_ event: Event) {
        switch event {
        case is GridEvent: gridCallback?(self, event as! GridEvent)
        case is ArcEvent: arcCallback?(self, event as! ArcEvent)
        case is TiltEvent: tiltCallback?(self, event as! TiltEvent)
        default: break
        }
        eventHandler?(self, event)
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
    public enum Action {
        case buttonDown
        case buttonUp
    }
    public init(_ event: UnsafePointer<monome_event_t>) {
        self.cEvent = event
    }
    public var cEvent: UnsafePointer<monome_event_t>
    public var description: String {
        return "Monome Grid Event – x:\(x) y:\(y) action: \(action)"
    }

    public var x: UInt32 {
        return cEvent.pointee.grid.x
    }
    public var y: UInt32 {
        return cEvent.pointee.grid.y
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
    public enum Action {
        case delta
        case keyUp
        case keyDown
    }
    public init(_ event: UnsafePointer<monome_event_t>) {
        self.cEvent = event
    }
    public var cEvent: UnsafePointer<monome_event_t>
    public var description: String {
        return "Monome Arc Event – number:\(number) delta:\(delta) action:\(action)"
    }

    public var number: UInt32 {
        return cEvent.pointee.encoder.number
    }
    public var delta: Int32 {
        return cEvent.pointee.encoder.delta
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

    public var sensor: UInt32 {
        return cEvent.pointee.tilt.sensor
    }
    public var x: Int32 {
        return cEvent.pointee.tilt.x
    }
    public var y: Int32 {
        return cEvent.pointee.tilt.y
    }
    public var z: Int32 {
        return cEvent.pointee.tilt.z
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

public enum LED {
    public enum Status: UInt32 {
        case off = 0
        case on = 1
        public init(_ value: Int) {
            self = value <= 0 ? .off : .on
        }
    }
    public enum Level: UInt32 {
        case l00 = 0
        case l01 = 1
        case l02 = 2
        case l03 = 3
        case l04 = 4
        case l05 = 5
        case l06 = 6
        case l07 = 7
        case l08 = 8
        case l09 = 9
        case l10 = 10
        case l11 = 11
        case l12 = 12
        case l13 = 13
        case l14 = 14
        case l15 = 15
    }
}

extension Array where Element == LED.Status {
    func toBytes() -> [UInt8] {
        let numBytes = (count + 7) / 8
        var bytes = [UInt8](repeating: 0, count: numBytes)

        for (index, status) in self.enumerated() {
            if status.rawValue == 1 {
                bytes[index / 8] += UInt8(1 << (index % 8))
            }
        }
        return bytes
    }
}

extension Array where Element == LED.Level {
    func toBytes() -> [UInt8] {
        return self.map({ level -> UInt8 in
            return UInt8(level.rawValue)
        })
    }
}

extension Array where Element == [LED.Status] {
    func toBytes() -> [UInt8] {
        return self.flatMap { (value) -> [UInt8] in
            return value.toBytes()
        }
    }
}

extension Array where Element == [LED.Level] {
    func toBytes() -> [UInt8] {
        return self.flatMap { value -> [UInt8] in
            return value.map({ level -> UInt8 in
                return UInt8(level.rawValue)
            })
        }
    }
}
