// Watches for the space bar and kills the `say` process it is given, so tapping
// the space bar (e.g. to start dictation) cuts Claude off mid-sentence.
// Usage: space-stop <say-pid>. Exits as soon as that process finishes.
// Needs Input Monitoring permission for the terminal app (System Settings >
// Privacy & Security > Input Monitoring); without it the tap can't be created.
import Cocoa

guard CommandLine.arguments.count > 1, let sayPid = Int32(CommandLine.arguments[1]) else { exit(2) }

let eventMask = CGEventMask(1 << CGEventType.keyDown.rawValue)
let callback: CGEventTapCallBack = { _, type, event, _ in
    // Key code 49 is the space bar. Re-read the pid here because C callbacks can't capture it.
    if type == .keyDown, event.getIntegerValueField(.keyboardEventKeycode) == 49,
       let pidArgument = CommandLine.arguments.dropFirst().first, let pid = Int32(pidArgument) {
        kill(pid, SIGTERM)
        exit(0)
    }
    return Unmanaged.passUnretained(event)
}

guard let tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap,
                                  options: .listenOnly, eventsOfInterest: eventMask,
                                  callback: callback, userInfo: nil) else {
    FileHandle.standardError.write(Data("space-stop: no Input Monitoring permission\n".utf8))
    exit(1)
}
CFRunLoopAddSource(CFRunLoopGetCurrent(), CFMachPortCreateRunLoopSource(nil, tap, 0), .commonModes)
CGEvent.tapEnable(tap: tap, enable: true)

// Quit once speech has ended on its own, so helpers never pile up.
Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
    if kill(sayPid, 0) != 0 { exit(0) }
}
CFRunLoopRun()
