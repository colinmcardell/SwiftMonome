//
//  Monome.swift
//  SwiftMonome - monome-examples
//
//  Colin McArdell <colin@colinmcardell.com>
//

import SwiftMonome
import Foundation


// MARK: - Extension to Monome adding the ability to clear all event handling closures in one function call
extension Monome {

    func clearEventHandlers() {
        arcEventHandler = nil
        gridEventHandler = nil
        tiltEventHandler = nil
    }
}


/// EventScheduler that periodically calls an instance of the Monome classes eventHandleNext() func
class MonomeEventScheduler: EventScheduler {

    let monome: Monome

    init(monome: Monome) {
        self.monome = monome
        super.init(.highPriority)

        self.eventHandler = { [weak self] in
            self?.monome.eventHandleNext()
        }
    }
}
