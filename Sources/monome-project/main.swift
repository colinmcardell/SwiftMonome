#if os(Linux)
import Glibc
srandom(UInt32(time(nil)))
#else
import Darwin
#endif

import SwiftMonome

class Main {
    enum OptionType: String {
        case close = "c"
        case help = "help"
        case open = "o"
        case quit = "q"
        case life = "l"
        case simple = "s"
        case test = "t"
        case torture = "to"
        case usage = "u"
        case unknown
        
        init(value: String) {
            switch value {
            case "c": self = .close
            case "help": self = .help
            case "o": self = .open
            case "q": self = .quit
            case "l": self = .life
            case "s": self = .simple
            case "t": self = .test
            case "to": self = .torture
            case "u": self = .usage
            default: self = .unknown
            }
        }
        
        var usage: String {
            switch self {
            case .close:
                return "    \(self.rawValue) - Close a connection to a Monome device."
            case .help:
                return "    \(self.rawValue) - Display `monome-project` usage."
            case .open:
                return "    \(self.rawValue) - Open a connection with a Monome device."
            case .quit:
                return "    \(self.rawValue) - Quit"
            case .life:
                return "    \(self.rawValue) - Load: \(Life.description())"
            case .simple:
                return "    \(self.rawValue) - Load: \(Simple.description())"
            case .test:
                return "    \(self.rawValue) - Load: \(Test.description())"
            case .torture:
                return "    \(self.rawValue) - Load: \(Torture.description())"
            case .usage:
                return "    \(self.rawValue) - Display `monome-project` usage."
            case .unknown:
                return "Unknown option type: \(self.rawValue)"
            }
        }
    }

    let io: ConsoleIO = ConsoleIO()
    var monome: Monome?

    var currentOption: OptionType = .unknown
    var currentApplication: Application?
    
    func displayUsage() {
        io.writeMessage("Usage:")
        io.writeMessage(OptionType.open.usage)
        io.writeMessage(OptionType.close.usage)
        io.writeMessage(OptionType.simple.usage)
        io.writeMessage(OptionType.life.usage)
        io.writeMessage(OptionType.test.usage)
        io.writeMessage(OptionType.torture.usage)
        io.writeMessage(OptionType.usage.usage)
        io.writeMessage(OptionType.quit.usage)
    }
    
    func displayCarrot(_ option: OptionType) {
        if option == .unknown {
            io.displayCarrot()
        } else {
            io.displayCarrot("\(currentOption)")
        }
    }

    func close() {
        io.writeMessage("Closing connection to Monome device if necessary...")
        guard let monome = monome, let path = monome.devicePath else {
            io.writeMessage("No connection to Monome device.")
            return
        }
        self.monome = nil
        io.writeMessage("CLOSED - Connection to Monome device (\(path)).")
    }
    
    func run() {
        io.writeMessage("Welcome to the SwiftMonome example project.")
        displayUsage()
        var shouldQuit = false
        while !shouldQuit {
            currentOption = .unknown
            displayCarrot(currentOption)
            guard let input = io.getInput() else {
                continue
            }
            currentOption = OptionType(value: input)
            switch currentOption {
            case .open:
                io.writeMessage("Please provide monome device path, or press [Enter] for default (\(Monome.DefaultDevice))")
                displayCarrot(currentOption)
                guard let path = io.getInput() else {
                    continue
                }
                if path.count == 0 {
//                    monome = Monome()
                    monome = Monome("/dev/cu.usbserial-m1000286")
                } else {
                    monome = Monome(path)
                }
                guard let monome = monome else {
                    io.writeMessage("Connection to Monome device at provided path failed.", to: .error)
                    continue
                }
                monome.all(0)
                io.writeMessage(monome)
            case .close:
                close()
                continue
            case .quit:
                close()
                shouldQuit = true
            case .simple:
                guard let monome = monome else {
                    io.writeMessage("Monome device connection unavailable, try opening a connect [o]", to: .error)
                    continue
                }
                currentApplication = Simple(monome: monome, io: io)
                currentApplication?.delegate = self
                currentApplication?.run()
                continue
            case .life:
                guard let monome = monome else {
                    io.writeMessage("Monome device connection unavailable, try opening a connect [o]", to: .error)
                    continue
                }
                currentApplication = Life(monome: monome, io: io)
                currentApplication?.delegate = self
                currentApplication?.run()
                continue
            case .test:
                guard let monome = monome else {
                    io.writeMessage("Monome device connection unavailable, try opening a connect [o]", to: .error)
                    continue
                }
                currentApplication = Test(monome: monome, io: io)
                currentApplication?.delegate = self
                currentApplication?.run()
                continue
            case .torture:
                guard let monome = monome else {
                    io.writeMessage("Monome device connection unavailable, try opening a connect [o]", to: .error)
                    continue
                }
                io.writeMessage("\(Torture.name()) will likely overwhelm libmonome, as well as this process.\nThis will require you to:\n1) Interrupt or kill this process.\n2) Disconnect and reconnect your Monome device.")
                io.writeMessage("Do you wish to continue?\nPress [y] for yes, or any other key for no.")
                displayCarrot(.unknown)
                guard let nextInput = io.getInput() else {
                    continue
                }
                if nextInput != "y" {
                    continue
                }
                currentApplication = Torture(monome: monome, io: io)
                currentApplication?.delegate = self
                currentApplication?.run()
                continue
            case .usage, .help, .unknown:
                displayUsage()
                continue
            }
        }
        
        io.writeMessage("Thanks, that was fun.")
        exit(EXIT_SUCCESS)
    }
}

extension Main: ApplicationDelegate {
    func applicationDidFinish(_ application: Application, exitStatus: Int32) {
        if exitStatus == EXIT_SUCCESS {
            io.writeMessage("\(application.name) did finish.")
        } else {
            io.writeMessage("\(application.name) did finish with status: \(exitStatus)", to: .error)
        }
        currentApplication = nil
        monome?.all(0)
        monome?.intensity(15)
        displayUsage()
    }
}

var main: Main = Main()

main.run()
