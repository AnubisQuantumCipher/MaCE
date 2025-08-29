import Foundation
#if os(Darwin)
import os.log
#endif

/// Advanced logging system for MaCE with multiple levels and structured output
public enum MaceLog {
    
    public enum Level: Int, CaseIterable, Comparable {
        case trace = 0
        case debug = 1
        case info = 2
        case warning = 3
        case error = 4
        case critical = 5
        
        public static func < (lhs: Level, rhs: Level) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
        
        var emoji: String {
            switch self {
            case .trace: return "🔍"
            case .debug: return "🐛"
            case .info: return "ℹ️"
            case .warning: return "⚠️"
            case .error: return "❌"
            case .critical: return "🚨"
            }
        }
        
        var name: String {
            switch self {
            case .trace: return "TRACE"
            case .debug: return "DEBUG"
            case .info: return "INFO"
            case .warning: return "WARN"
            case .error: return "ERROR"
            case .critical: return "CRIT"
            }
        }
    }
    
    // Use nonisolated(unsafe) to avoid MainActor complexity for logging configuration
    nonisolated(unsafe) public static var minimumLevel: Level = .info
    nonisolated(unsafe) public static var enableColors: Bool = true
    nonisolated(unsafe) public static var enableEmojis: Bool = true
    nonisolated(unsafe) public static var enableTimestamps: Bool = true
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
    
    #if os(Darwin)
    private static let osLog = OSLog(subsystem: "org.mace.secure", category: "encryption")
    #endif
    
    /// Log a message at the specified level
    public static func log(_ level: Level, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard level >= minimumLevel else { return }
        
        let filename = URL(fileURLWithPath: file).lastPathComponent
        let location = "\(filename):\(function):\(line)"
        
        var logMessage = ""
        
        // Add timestamp
        if enableTimestamps {
            logMessage += "[\(dateFormatter.string(from: Date()))] "
        }
        
        // Add level indicator
        if enableEmojis {
            logMessage += "\(level.emoji) "
        }
        if enableColors {
            logMessage += colorCode(for: level)
        }
        logMessage += "[\(level.name)]"
        if enableColors {
            logMessage += "\u{001B}[0m" // Reset color
        }
        
        // Add location for debug and trace
        if level <= .debug {
            logMessage += " \(location)"
        }
        
        logMessage += " \(message)"
        
        // Output to appropriate destination
        #if os(Darwin)
        // Use os_log on Darwin platforms for better integration
        switch level {
        case .trace, .debug:
            os_log("%{public}@", log: osLog, type: .debug, logMessage)
        case .info:
            os_log("%{public}@", log: osLog, type: .info, logMessage)
        case .warning:
            os_log("%{public}@", log: osLog, type: .default, logMessage)
        case .error:
            os_log("%{public}@", log: osLog, type: .error, logMessage)
        case .critical:
            os_log("%{public}@", log: osLog, type: .fault, logMessage)
        }
        #endif
        
        // Also output to stderr for visibility
        if level >= .warning {
            FileHandle.standardError.write(Data((logMessage + "\n").utf8))
        } else {
            print(logMessage)
        }
    }
    
    private static func colorCode(for level: Level) -> String {
        switch level {
        case .trace: return "\u{001B}[37m"    // White
        case .debug: return "\u{001B}[36m"    // Cyan
        case .info: return "\u{001B}[32m"     // Green
        case .warning: return "\u{001B}[33m"  // Yellow
        case .error: return "\u{001B}[31m"    // Red
        case .critical: return "\u{001B}[35m" // Magenta
        }
    }
    
    // Convenience methods
    public static func trace(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.trace, message, file: file, function: function, line: line)
    }
    
    public static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.debug, message, file: file, function: function, line: line)
    }
    
    public static func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.info, message, file: file, function: function, line: line)
    }
    
    public static func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.warning, message, file: file, function: function, line: line)
    }
    
    public static func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.error, message, file: file, function: function, line: line)
    }
    
    public static func critical(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.critical, message, file: file, function: function, line: line)
    }
}

// MARK: - Structured logging for cryptographic operations

extension MaceLog {
    /// Log cryptographic operations with structured data
    public static func cryptoOperation(_ operation: String, keyId: String? = nil, fileSize: UInt64? = nil, duration: TimeInterval? = nil) {
        var message = "Crypto operation: \(operation)"
        
        if let keyId = keyId {
            message += ", keyId: \(keyId)"
        }
        
        if let fileSize = fileSize {
            message += ", fileSize: \(ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .binary))"
        }
        
        if let duration = duration {
            message += ", duration: \(String(format: "%.3f", duration))s"
        }
        
        info(message)
    }
    
    /// Log security events
    public static func securityEvent(_ event: String, severity: Level = .warning) {
        log(severity, "Security event: \(event)")
    }
    
    /// Log performance metrics
    public static func performance(_ metric: String, value: Double, unit: String) {
        debug("Performance: \(metric) = \(String(format: "%.3f", value)) \(unit)")
    }
    
    /// Log key management operations
    public static func keyManagement(_ operation: String, keyId: String, success: Bool) {
        let status = success ? "SUCCESS" : "FAILED"
        let level: Level = success ? .info : .error
        log(level, "Key management: \(operation) for \(keyId) - \(status)")
    }
}

// MARK: - Audit logging for compliance

extension MaceLog {
    /// Audit log for compliance and security monitoring
    public static func audit(_ event: String, userId: String? = nil, resourceId: String? = nil, action: String? = nil, result: String? = nil) {
        var auditData: [String: String] = [:]
        auditData["event"] = event
        
        if let userId = userId { auditData["userId"] = userId }
        if let resourceId = resourceId { auditData["resourceId"] = resourceId }
        if let action = action { auditData["action"] = action }
        if let result = result { auditData["result"] = result }
        
        let auditMessage = auditData.map { "\($0.key)=\($0.value)" }.joined(separator: " ")
        
        // Audit logs are always at INFO level and go to a separate channel
        log(.info, "AUDIT: \(auditMessage)")
        
        // TODO: In production, also send to centralized audit system
        // auditLogger.send(auditData)
    }
}

// MARK: - Error context tracking

extension MaceLog {
    /// Enhanced error logging with context
    public static func errorWithContext(_ error: Error, context: [String: Any] = [:], file: String = #file, function: String = #function, line: Int = #line) {
        var message = "Error: \(error.localizedDescription)"
        
        if !context.isEmpty {
            let contextString = context.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            message += " | Context: \(contextString)"
        }
        
        log(.error, message, file: file, function: function, line: line)
    }
    
    /// Log exceptions with stack trace information
    public static func exception(_ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        var logMessage = "Exception: \(message)"
        
        if let error = error {
            logMessage += " | Underlying error: \(error.localizedDescription)"
        }
        
        log(.critical, logMessage, file: file, function: function, line: line)
    }
}

// MARK: - Configuration and utilities

extension MaceLog {
    /// Configure logging based on environment
    public static func configure(for environment: Environment) {
        switch environment {
        case .development:
            minimumLevel = .trace
            enableColors = true
            enableEmojis = true
            enableTimestamps = true
        case .testing:
            minimumLevel = .debug
            enableColors = false
            enableEmojis = false
            enableTimestamps = false
        case .production:
            minimumLevel = .info
            enableColors = false
            enableEmojis = false
            enableTimestamps = true
        }
    }
    
    public enum Environment {
        case development
        case testing
        case production
    }
    
    /// Enable verbose logging for debugging
    public static func enableVerboseLogging() {
        minimumLevel = .trace
        info("Verbose logging enabled")
    }
    
    /// Disable all logging except critical errors
    public static func enableQuietMode() {
        minimumLevel = .critical
    }
    
    /// Log system information for debugging
    public static func logSystemInfo() {
        #if os(macOS)
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        info("System: macOS \(osVersion)")
        #elseif os(Linux)
        info("System: Linux")
        #endif
        
        info("Swift version: Swift 6.1.2")
        info("MaCE version: \(MaceVersion.cli)")
        info("Crypto security level: \(PQC.securityLevel)")
    }
}

// Back-compat for older test code that still references `Log`
@available(*, deprecated, renamed: "MaceLog")
public typealias Log = MaceLog

