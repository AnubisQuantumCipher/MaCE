import Foundation
import MaceCore

enum Log {
    nonisolated(unsafe) static var quiet  = false
    nonisolated(unsafe) static var useColor = true
    nonisolated(unsafe) static var verbose = false

    static func info(_ s: String)  { 
        if !quiet { 
            MaceLog.info(s)
        } 
    }
    
    static func ok(_ s: String)    { 
        if quiet { return }
        let message = "[✓] \(s)"
        if useColor {
            print(color(message, "32"))
        } else {
            MaceLog.info(message)
        }
    }
    
    static func warn(_ s: String)  { 
        if quiet { return }
        let message = "[!] \(s)"
        if useColor {
            FileHandle.standardError.write(Data((color(message, "33") + "\n").utf8))
        } else {
            MaceLog.warning(s)
        }
    }
    
    static func err(_ s: String)   { 
        let message = "[✗] \(s)"
        if useColor {
            FileHandle.standardError.write(Data((color(message, "31") + "\n").utf8))
        } else {
            MaceLog.error(s)
        }
    }
    
    static func debug(_ s: String) { 
        if verbose && !quiet { 
            if useColor {
                FileHandle.standardError.write(Data((color("[d] \(s)", "34") + "\n").utf8))
            } else {
                MaceLog.debug(s)
            }
        } 
    }

    private static func color(_ s: String, _ code: String) -> String {
        useColor ? "\u{001B}[\(code)m\(s)\u{001B}[0m" : s
    }
    
    /// Configure logging system
    static func configure(quiet: Bool = false, verbose: Bool = false, useColor: Bool = true) {
        self.quiet = quiet
        self.verbose = verbose
        self.useColor = useColor
        
        // Configure the advanced logging system
        if quiet {
            MaceLog.minimumLevel = .error
        } else if verbose {
            MaceLog.minimumLevel = .debug
        } else {
            MaceLog.minimumLevel = .info
        }
        
        MaceLog.enableColors = useColor
    }
}


