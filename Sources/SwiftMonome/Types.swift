import clibmonome
import Foundation

public enum EventType: CaseIterable {
    case buttonUp
    case buttonDown
    case encoderDelta
    case encoderKeyUp
    case encoderKeyDown
    case tilt
}

extension EventType {
    init() {
        self = .buttonUp
    }
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

public enum Rotation {
    case left
    case bottom
    case right
    case top
}

extension Rotation {
    init() {
        self = .left
    }
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

public protocol EventProtocol {
    init(_ event: UnsafePointer<monome_event_t>)
    var event: UnsafePointer<monome_event_t> { get }
    var type: EventType { get }
    var timestamp: DispatchWallTime { get }
}

struct Event {
    static func event(for monomeEvent: UnsafePointer<monome_event_t>?) -> EventProtocol? {
        guard let monomeEvent = monomeEvent else {
            return nil
        }
        switch monomeEvent.pointee.event_type {
        case MONOME_BUTTON_UP, MONOME_BUTTON_DOWN:
            return GridEvent(monomeEvent)
        case MONOME_ENCODER_DELTA, MONOME_ENCODER_KEY_UP, MONOME_ENCODER_KEY_DOWN:
            return EncoderEvent(monomeEvent)
        case MONOME_TILT:
            return TiltEvent(monomeEvent)
        default:
            return nil
        }
    }
}

public struct GridEvent: EventProtocol {
    public init(_ event: UnsafePointer<monome_event_t>) {
        self.event = event
        self.timestamp = DispatchWallTime.now()
    }
    public var event: UnsafePointer<monome_event_t>
    public var type: EventType {
        return EventType(event.pointee.event_type)
    }
    public var timestamp: DispatchWallTime

    public var x: UInt32 {
        return event.pointee.grid.x
    }
    public var y: UInt32 {
        return event.pointee.grid.y
    }
}

public struct EncoderEvent: EventProtocol {
    public init(_ event: UnsafePointer<monome_event_t>) {
        self.event = event
        self.timestamp = DispatchWallTime.now()
    }
    public var event: UnsafePointer<monome_event_t>
    public var type: EventType {
        return EventType(event.pointee.event_type)
    }
    public var timestamp: DispatchWallTime

    public var number: UInt32 {
        return event.pointee.encoder.number
    }
    public var delta: Int32 {
        return event.pointee.encoder.delta
    }
}
public struct TiltEvent: EventProtocol {
    public init(_ event: UnsafePointer<monome_event_t>) {
        self.event = event
        self.timestamp = DispatchWallTime.now()
    }
    public var event: UnsafePointer<monome_event_t>
    public var type: EventType {
        return EventType(event.pointee.event_type)
    }
    public var timestamp: DispatchWallTime

    public var sensor: UInt32 {
        return event.pointee.tilt.sensor
    }
    public var x: Int32 {
        return event.pointee.tilt.x
    }
    public var y: Int32 {
        return event.pointee.tilt.y
    }
    public var z: Int32 {
        return event.pointee.tilt.z
    }
}

public enum MonomeLedStatus: UInt32 {
    case on = 0
    case off = 1
}
