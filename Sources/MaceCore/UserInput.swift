import Foundation
#if os(Darwin)
import Darwin
#else
import Glibc
#endif

/// User input utilities for MaCE
public enum UserInput {
    
    /// Prompt the user for input with a message
    @discardableResult
    public static func prompt(_ message: String) -> String {
        print(message, terminator: "")
        return readLine(strippingNewline: true) ?? ""
    }
    
    /// Prompt the user for secure input (hidden, no echo)
    /// Useful for passwords and sensitive data
    public static func securePrompt(_ message: String) -> String {
        print(message, terminator: "")
        
        var old = termios()
        var new = termios()
        
        tcgetattr(STDIN_FILENO, &old)
        new = old
        new.c_lflag &= ~tcflag_t(ECHO)
        tcsetattr(STDIN_FILENO, TCSANOW, &new)
        
        let line = readLine(strippingNewline: true) ?? ""
        
        tcsetattr(STDIN_FILENO, TCSANOW, &old)
        print() // Print newline
        
        return line
    }
    
    /// Prompt for yes/no confirmation
    public static func confirmPrompt(_ message: String, defaultYes: Bool = false) -> Bool {
        let suffix = defaultYes ? " (Y/n): " : " (y/N): "
        let response = prompt(message + suffix).lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        if response.isEmpty {
            return defaultYes
        }
        
        return response.starts(with: "y")
    }
    
    /// Prompt for a choice from multiple options
    public static func choicePrompt(_ message: String, options: [String]) -> Int? {
        print(message)
        for (index, option) in options.enumerated() {
            print("  \(index + 1). \(option)")
        }
        
        let response = prompt("Enter choice (1-\(options.count)): ")
        
        if let choice = Int(response), choice >= 1 && choice <= options.count {
            return choice - 1
        }
        
        return nil
    }
    
    /// Prompt for file path with validation
    public static func filePathPrompt(_ message: String, mustExist: Bool = false) -> String? {
        let path = prompt(message)
        
        if mustExist && !FileManager.default.fileExists(atPath: path) {
            print("Error: File does not exist at path: \(path)")
            return nil
        }
        
        return path.isEmpty ? nil : path
    }
}

