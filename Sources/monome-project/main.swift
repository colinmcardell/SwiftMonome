#if os(Linux)
import Glibc
#else
import Darwin
#endif
import SwiftMonome

class Main {
    enum OptionType: String {
        case close = "c"
        case open = "o"
        case quit = "q"
        case simple = "s"
        case usage = "u"
        case unknown
        
        init(value: String) {
            switch value {
            case "c": self = .close
            case "o": self = .open
            case "q": self = .quit
            case "s": self = .simple
            case "u": self = .usage
            default: self = .unknown
            }
        }
        
        var usage: String {
            switch self {
            case .close:
                return "    \(self.rawValue) - Close a connection to a Monome device."
            case .open:
                return "    \(self.rawValue) - Open a connection with a Monome device."
            case .quit:
                return "    \(self.rawValue) - Quit"
            case .simple:
                return "    \(self.rawValue) - Load a simple Monome application run with the connected Monome device"
            case .usage:
                return "    \(self.rawValue) - Display example project usage."
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
                    monome = Monome()
                } else {
                    monome = Monome(path)
                }
                guard let monome = monome else {
                    io.writeMessage("Connection to Monome device at provided path failed.", to: .error)
                    continue
                }
                monome.all(status: .off)
                io.writeMessage(monome)
            case .close:
                guard let monome = monome, let path = monome.devicePath else {
                    io.writeMessage("No connection Monome device currently open.", to: .error)
                    continue
                }
                self.monome = nil
                io.writeMessage("Connection to Monome device (\(path)) CLOSED.")
            case .quit:
                shouldQuit = true
            case .simple:
                guard let monome = monome else {
                    io.writeMessage("Monome device connection unavailable, try opening a connect [o]", to: .error)
                    continue
                }
                currentApplication = Simple(monome: monome, io: io)
                currentApplication?.run()
                continue
            case .usage:
                displayUsage()
                continue
            case .unknown: continue
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
        monome?.clearHandlers()
    }
}

var main: Main = Main()

main.run()
