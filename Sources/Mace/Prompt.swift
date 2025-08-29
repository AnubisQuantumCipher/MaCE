import Foundation
#if os(macOS)
import Darwin
#endif

@discardableResult
public func prompt(_ s: String) -> String {
    print(s, terminator: "")
    return readLine(strippingNewline: true) ?? ""
}

// Hidden input (no echo). Not used for passphrases now, but ready.
public func securePromptHidden(_ s: String) -> String {
    print(s, terminator: "")
    var old = termios(), new = termios()
    tcgetattr(STDIN_FILENO, &old)
    new = old; new.c_lflag &= ~tcflag_t(ECHO)
    tcsetattr(STDIN_FILENO, TCSANOW, &new)
    let line = readLine(strippingNewline: true) ?? ""
    tcsetattr(STDIN_FILENO, TCSANOW, &old)
    print()
    return line
}


