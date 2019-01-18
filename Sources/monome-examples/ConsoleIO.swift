//
//  ConsoleIO.swift
//  SwiftMonome - monome-examples
//
//  Colin McArdell <colin@colinmcardell.com>
//

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
    func displayCarrot(_ message: String = "") {
        let name = "monome-examples"
        var carrot = "> "
        if message.count != 0 {
            carrot = "\(name) [\(message)] \(carrot)"
        } else {
            carrot = "\(name) \(carrot)"
        }
        writeMessage(carrot, to: .standard, newLineTerminator: false)
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
