import SwiftMonome

print("Initializing Monome...")
var monome = Monome()
print("Monome Initialized")

while(true) {
    monome.eventHandleNext()
}
