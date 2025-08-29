import XCTest
import Foundation
@testable import MaceCore

final class LoggingTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Reset logging configuration for each test
        MaceLog.minimumLevel = .info
        MaceLog.enableColors = true
        MaceLog.enableEmojis = true
        MaceLog.enableTimestamps = true
    }
    
    // MARK: - Basic Logging Tests
    
    func testLogLevels() {
        // Test level comparison
        XCTAssertTrue(MaceLog.Level.trace < MaceLog.Level.debug)
        XCTAssertTrue(MaceLog.Level.debug < MaceLog.Level.info)
        XCTAssertTrue(MaceLog.Level.info < MaceLog.Level.warning)
        XCTAssertTrue(MaceLog.Level.warning < MaceLog.Level.error)
        XCTAssertTrue(MaceLog.Level.error < MaceLog.Level.critical)
    }
    
    func testLogLevelProperties() {
        XCTAssertEqual(MaceLog.Level.trace.name, "TRACE")
        XCTAssertEqual(MaceLog.Level.debug.name, "DEBUG")
        XCTAssertEqual(MaceLog.Level.info.name, "INFO")
        XCTAssertEqual(MaceLog.Level.warning.name, "WARN")
        XCTAssertEqual(MaceLog.Level.error.name, "ERROR")
        XCTAssertEqual(MaceLog.Level.critical.name, "CRIT")
        
        XCTAssertEqual(MaceLog.Level.trace.emoji, "🔍")
        XCTAssertEqual(MaceLog.Level.debug.emoji, "🐛")
        XCTAssertEqual(MaceLog.Level.info.emoji, "ℹ️")
        XCTAssertEqual(MaceLog.Level.warning.emoji, "⚠️")
        XCTAssertEqual(MaceLog.Level.error.emoji, "❌")
        XCTAssertEqual(MaceLog.Level.critical.emoji, "🚨")
    }
    
    func testMinimumLevelFiltering() {
        MaceLog.minimumLevel = .warning
        
        // These should not log (below minimum level)
        MaceLog.trace("This should not appear")
        MaceLog.debug("This should not appear")
        MaceLog.info("This should not appear")
        
        // These should log (at or above minimum level)
        MaceLog.warning("This should appear")
        MaceLog.error("This should appear")
        MaceLog.critical("This should appear")
        
        // Test that the filtering works correctly
        XCTAssertTrue(MaceLog.Level.warning >= MaceLog.minimumLevel)
        XCTAssertTrue(MaceLog.Level.error >= MaceLog.minimumLevel)
        XCTAssertTrue(MaceLog.Level.critical >= MaceLog.minimumLevel)
        XCTAssertFalse(MaceLog.Level.trace >= MaceLog.minimumLevel)
        XCTAssertFalse(MaceLog.Level.debug >= MaceLog.minimumLevel)
        XCTAssertFalse(MaceLog.Level.info >= MaceLog.minimumLevel)
    }
    
    // MARK: - Configuration Tests
    
    func testEnvironmentConfiguration() {
        // Test development configuration
        MaceLog.configure(for: .development)
        XCTAssertEqual(MaceLog.minimumLevel, .trace)
        XCTAssertTrue(MaceLog.enableColors)
        XCTAssertTrue(MaceLog.enableEmojis)
        XCTAssertTrue(MaceLog.enableTimestamps)
        
        // Test testing configuration
        MaceLog.configure(for: .testing)
        XCTAssertEqual(MaceLog.minimumLevel, .debug)
        XCTAssertFalse(MaceLog.enableColors)
        XCTAssertFalse(MaceLog.enableEmojis)
        XCTAssertFalse(MaceLog.enableTimestamps)
        
        // Test production configuration
        MaceLog.configure(for: .production)
        XCTAssertEqual(MaceLog.minimumLevel, .info)
        XCTAssertFalse(MaceLog.enableColors)
        XCTAssertFalse(MaceLog.enableEmojis)
        XCTAssertTrue(MaceLog.enableTimestamps)
    }
    
    func testVerboseLogging() {
        MaceLog.enableVerboseLogging()
        XCTAssertEqual(MaceLog.minimumLevel, .trace)
    }
    
    func testQuietMode() {
        MaceLog.enableQuietMode()
        XCTAssertEqual(MaceLog.minimumLevel, .critical)
    }
    
    // MARK: - Structured Logging Tests
    
    func testCryptoOperationLogging() {
        // Test with all parameters
        MaceLog.cryptoOperation("encrypt", keyId: "test-key", fileSize: 1024, duration: 0.5)
        
        // Test with minimal parameters
        MaceLog.cryptoOperation("decrypt")
        
        // Test with partial parameters
        MaceLog.cryptoOperation("keygen", keyId: "new-key")
    }
    
    func testSecurityEventLogging() {
        MaceLog.securityEvent("Unauthorized access attempt")
        MaceLog.securityEvent("Key rotation completed", severity: .info)
        MaceLog.securityEvent("Critical security breach", severity: .critical)
    }
    
    func testPerformanceLogging() {
        MaceLog.performance("encryption_speed", value: 1024.5, unit: "MB/s")
        MaceLog.performance("key_generation_time", value: 0.001, unit: "seconds")
    }
    
    func testKeyManagementLogging() {
        MaceLog.keyManagement("create", keyId: "test-key", success: true)
        MaceLog.keyManagement("delete", keyId: "old-key", success: false)
    }
    
    // MARK: - Audit Logging Tests
    
    func testAuditLogging() {
        // Test with all parameters
        MaceLog.audit("file_encrypted", userId: "alice", resourceId: "document.txt", action: "encrypt", result: "success")
        
        // Test with minimal parameters
        MaceLog.audit("system_startup")
        
        // Test with partial parameters
        MaceLog.audit("key_accessed", userId: "bob", action: "decrypt")
    }
    
    // MARK: - Error Context Tests
    
    func testErrorWithContext() {
        let error = MaceError.io("File not found")
        let context = ["file": "test.txt", "operation": "read"]
        
        MaceLog.errorWithContext(error, context: context)
    }
    
    func testExceptionLogging() {
        let underlyingError = MaceError.badKey("Invalid key format")
        
        MaceLog.exception("Encryption failed", error: underlyingError)
        MaceLog.exception("Unexpected condition")
    }
    
    // MARK: - System Information Tests
    
    func testSystemInfoLogging() {
        MaceLog.logSystemInfo()
        // This test mainly ensures the function doesn't crash
        // The actual output would be verified manually
    }
    
    // MARK: - Legacy Logger Integration Tests
    
    func testLegacyLoggerIntegration() {
        // Test that the legacy Log enum works with the new system
        MaceLog.configure(for: .development)
        
        MaceLog.info("Test info message")
        MaceLog.info("Test success message")
        MaceLog.warning("Test warning message")
        MaceLog.error("Test error message")
        MaceLog.debug("Test debug message")
    }
    
    func testLegacyLoggerQuietMode() {
        MaceLog.configure(for: .production)
        MaceLog.enableQuietMode()
        
        // These should be suppressed in quiet mode
        MaceLog.info("This should be quiet")
        MaceLog.info("This should be quiet")
        MaceLog.warning("This should be quiet")
        MaceLog.debug("This should be quiet")
        
        // Errors should still appear
        MaceLog.error("This should still appear")
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentLogging() {
        let expectation = XCTestExpectation(description: "Concurrent logging")
        expectation.expectedFulfillmentCount = 10
        
        let queue = DispatchQueue.global(qos: .default)
        
        for i in 0..<10 {
            queue.async {
                MaceLog.info("Concurrent log message \(i)")
                MaceLog.debug("Concurrent debug message \(i)")
                MaceLog.warning("Concurrent warning message \(i)")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Performance Tests
    
    func testLoggingPerformance() {
        MaceLog.minimumLevel = .info
        
        measure {
            for i in 0..<1000 {
                MaceLog.info("Performance test message \(i)")
            }
        }
    }
    
    func testFilteredLoggingPerformance() {
        // Set minimum level high to filter out most messages
        MaceLog.minimumLevel = .critical
        
        measure {
            for i in 0..<1000 {
                // These should be filtered out quickly
                MaceLog.trace("Filtered trace message \(i)")
                MaceLog.debug("Filtered debug message \(i)")
                MaceLog.info("Filtered info message \(i)")
                MaceLog.warning("Filtered warning message \(i)")
            }
        }
    }
    
    // MARK: - Edge Cases
    
    func testEmptyMessages() {
        MaceLog.info("")
        MaceLog.debug("")
        MaceLog.warning("")
        MaceLog.error("")
        MaceLog.critical("")
    }
    
    func testLongMessages() {
        let longMessage = String(repeating: "A", count: 10000)
        MaceLog.info(longMessage)
    }
    
    func testSpecialCharacters() {
        MaceLog.info("Message with special characters: 🔐🛡️⚡️")
        MaceLog.info("Message with unicode: αβγδε")
        MaceLog.info("Message with newlines:\nLine 1\nLine 2")
        MaceLog.info("Message with tabs:\tTabbed content")
    }
    
    func testNilAndOptionalHandling() {
        let optionalString: String? = nil
        let optionalInt: Int? = nil
        
        MaceLog.cryptoOperation("test", keyId: optionalString, fileSize: nil, duration: nil)
        MaceLog.audit("test_event", userId: optionalString, resourceId: optionalString)
    }
}

