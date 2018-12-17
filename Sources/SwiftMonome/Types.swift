import clibmonome
import Foundation

enum UnderlyingEventType: CaseIterable {
    case ButtonUp
    case ButtonDown
    case EncoderDelta
    case EncoderKeyUp
    case EncoderKeyDown
    case Tilt
}

extension UnderlyingEventType {
    init(_ type: monome_event_type_t) {
        switch type {
        case MONOME_BUTTON_UP: self = .ButtonUp
        case MONOME_BUTTON_DOWN: self = .ButtonDown
        case MONOME_ENCODER_DELTA: self = .EncoderDelta
        case MONOME_ENCODER_KEY_UP: self = .EncoderKeyUp
        case MONOME_ENCODER_KEY_DOWN: self = .EncoderKeyDown
        case MONOME_TILT: self = .Tilt
        case MONOME_EVENT_MAX: self = .ButtonUp
        default: self = .ButtonUp
        }
    }
    var cType: monome_event_type_t {
        switch self {
        case .ButtonUp: return MONOME_BUTTON_UP
        case .ButtonDown: return MONOME_BUTTON_DOWN
        case .EncoderDelta: return MONOME_ENCODER_DELTA
        case .EncoderKeyUp: return MONOME_ENCODER_KEY_UP
        case .EncoderKeyDown: return MONOME_ENCODER_KEY_DOWN
        case .Tilt: return MONOME_TILT
        }
    }
}

public enum Rotation {
    case Left
    case Bottom
    case Right
    case Top
}

extension Rotation {
    init(_ rotation: monome_rotate_t) {
        switch rotation {
        case MONOME_ROTATE_0: self = .Left
        case MONOME_ROTATE_90: self = .Bottom
        case MONOME_ROTATE_180: self = .Right
        case MONOME_ROTATE_270: self = .Top
        default: self = .Left
        }
    }
    var cRotation: monome_rotate_t {
        switch self {
        case .Left: return MONOME_ROTATE_0
        case .Bottom: return MONOME_ROTATE_90
        case .Right: return MONOME_ROTATE_180
        case .Top: return MONOME_ROTATE_270
        }
    }
}

public protocol EventProtocol {
    init(_ event: UnsafePointer<monome_event_t>)
    var event: UnsafePointer<monome_event_t> { get }
    var type: EventType { get }
    var timestamp: DispatchWallTime { get }
}

extension Event {
    var type: UnderlyingEventType {
        return UnderlyingEventType(cEvent.pointee.event_type)
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

public enum LED {
    public enum Status: UInt32 {
        case On = 0
        case Off = 1
    }
}
