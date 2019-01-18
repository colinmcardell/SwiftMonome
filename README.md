# SwiftMonome

A Monome library written in Swift

SwiftMonome is a package that wraps around the [`libmonome`](https://github.com/monome/libmonome) C library allowing connection and communication to Monome Grid and Arc devices using the Swift programming language.

Tested and working on MacOS and Linux.

----------------------------------------
## Prerequisites
----------------------------------------

### [libmonome](https://github.com/monome/libmonome):

| OS           | Information                     | Instructions                                        |
| ------------ | ------------------------------- | --------------------------------------------------- |
| Mac OS       | Use [Homebrew](https://brew.sh) | `brew install libmonome`                            |
| Linux        | Manual Compile Recommended      | More info [here](https://monome.org/docs/linux/)    |
| Raspberry Pi | Manual Compile Recommended      | More info [here](https://monome.org/docs/raspbian/) |

### [Swift](https://swift.org):

| OS           | Information                                                     | Instructions                                                |
| ------------ | --------------------------------------------------------------- | ----------------------------------------------------------- |
| Mac OS       | Comes with Xcode                                                | Get [Xcode](https://itunes.apple.com/app/xcode/id497799835) |
| Linux        | A good number of official distributions                         | Download [here](https://swift.org/download/)                |
| Raspberry Pi | Compiling takes forever, try an unofficial pre-compiled version | Download [here](https://github.com/futurejones/swift-arm64) |

## Install & Connect
----------------------------------------

Add `SwiftMonome` to you `Package.swift` as a dependency:

```swift
// Package.swift

// swift-tools-version:4.2
import PackageDescription

let package = Package(
    // ...
    dependencies: [
        .Package(url: "https://github.com/colinmcardell/SwiftMonome.git", from: "0.0.3")
    ],
    // ...
    targets: [
        .target(
            //...
            dependencies: ["SwiftMonome"]),
    ]
)
```
Basic connection to an attached Monome device:

```swift
import SwiftMonome

// Monome? Failable Initializer, optional value of Monome or nil
let monome: Monome? = Monome("/dev/ttyUSB0")

// or
let monome: Monome? = Monome("/dev/cu.usbserial-m1000286")

// or
let monome: Monome? = Monome("osc.udp://127.0.0.1:9000/monome")

// or
// default device "osc.udp://127.0.0.1:8080/monome"
let monome: Monome? = Monome()

// or
// Using guard during initialization
guard let monome = Monome("/dev/ttyUSB0") else {
    fatalError("Error connecting to Monome device.")
}
```

## Usage Basics
----------------------------------------
Here are some basic examples on how to communicate to a Monome device with SwiftMonome. These examples all assume an optional constant `let monome: Monome? = Monome()` described in the section above on connecting to a Monome device... 

For additional examples look in the [`/Sources/monome-examples` folder](https://github.com/colinmcardell/SwiftMonome/tree/master/Sources/monome-examples) of this repo.

### LED on/off/level

```swift
// Setting the status of all LEDs on a Grid

// Value of 0 or 1
monome?.all(1) // All LEDs on
```

```swift
// Setting the intensity of all of the LEDs that are set to on

// Value of 0 through 15
monome?.intensity(15) // All LEDs that are on scaled to 100% brightness
```

```swift
// Setting the status of a specific LED

monome?.set(x: 0, y: 0, status: 1) // Top left corner set to on
monome?.set(x: 7, y: 15, status: 1) // Bottom right corner set to on
monome?.set(x: 0, y: 0, status: 0) // Top left corner set to off
```

```swift
// Display a map of values
// ... specifically a nice greeting from your Monome grid

func displayHello() {
    let hello: [[UInt8]] = [
        [0b01110101,
         0b00010101,
         0b00110111,
         0b00010101,
         0b00010101,
         0b00010101,
         0b00010101,
         0b01110101], // H E
        [0b01100101,
         0b10010101,
         0b10010101,
         0b10010101,
         0b10010101,
         0b10010101,
         0b10010101,
         0b01101111] // L L O
    ]
    monome?.map(x: 0, y: 0, data: hello[0])
    monome?.map(x: 8, y: 0, data: hello[1])
}

displayHello()
```

### Events

Events are handled by closures or delegation.

```swift
// Adding a event handling closure to respond to grid button events

monome?.gridEventHandler = { event in
    let x = event.x // Int value
    let y = event.y // Int value

    switch event.action {
    case .buttonDown:
        print("Got a button goin' dooooown - x: \(x), y: \(y)")
    case .buttonUp:
        print("Got a button jumpin' up - x: \(x), y: \(y)")
    }
}
```

```swift
// Setting a class as an event delegate

class MonomeController: MonomeGridEventDelegate {

    let monome = Monome()

    init() {
        monome?.gridEventDelegate = self
        // ... a bit of code to drive the eventHandleNext() call (see next code block)
    }

    func handleGridEvent(monome: Monome, event: GridEvent) {
        switch event.action {
        case .buttonDown:
            print("Button Down! Button Down!")
        case .buttonUp:
            print("Nevermind, it's back up.")
        }
    }
}
```

Events that have been triggered need to be driven by a timer, periodically calling `eventHandleNext()`.

```swift
// Driving the events of the connected Monome device

monome?.eventHandleNext()

// or
// Using a blocking loop
var shouldQuit = false
while !shouldQuit {
    monome?.eventHandleNext()
}

// or
// Using a dispatch source
let timeInterval: DispatchTimeInterval = .milliseconds(16)
let queue: DispatchQueue = DispatchQueue.global(qos: .userInteractive)
let timer: DispatchSourceTimer = DispatchSource.makeTimerSource(queue: queue)
timer.setEventHandler {
    monome?.eventHandleNext()
}
timer.schedule(deadline: .now(), repeating: timeInterval)
timer.resume()
```

## More Examples
----------------------------------------

A number of Swift reimplementations of the `libmonome` examples are provided that can be used as a reference, [here](https://github.com/colinmcardell/SwiftMonome/tree/master/Sources/monome-examples).

## Contribution
----------------------------------------

Feedback and comments are welcome. Please file an issue or make a PR.

Thanks!


Colin McArdell - colin(at)colinmcardell(dot)com
