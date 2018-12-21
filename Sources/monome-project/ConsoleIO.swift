#if os(Linux)
import Glibc
#else
import Darwin
#endif

class ConsoleIO {
    enum OutputType {
        case standard
        case error
    }
    func displayCarrot(_ prompt: String = "") {
        var message = "> "
        if prompt.count != 0 {
            message = "\(prompt) \(message)"
        }
        writeMessage(message, to: .standard, newLineTerminator: false)
    }
    func writeMessage(_ message: Any, to: OutputType = .standard, newLineTerminator: Bool = true) {
        switch to {
        case .standard:
            if newLineTerminator {
                print(message)
            } else {
                print(message, separator: " ", terminator: "")
            }
        default:
            if newLineTerminator {
                fputs("Error: \(message)\n", stderr)
            } else {
                fputs("Error: \(message)", stderr)
            }

        }
    }
    func getInput(_ strippingNewLine: Bool = true) -> String? {
        return readLine(strippingNewline: strippingNewLine)
    }
}
