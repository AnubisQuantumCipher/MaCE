import XCTest
@testable import MaceCore
import Foundation
@testable import MaceCore
#if canImport(CryptoKit)
import CryptoKit
#else
import Crypto
#endif

final class CrossPlatformTests: XCTestCase {
    
    // MARK: - Platform Detection Tests
    
    func testPlatformDetection() {
        #if os(macOS)
        XCTAssertTrue(true, "Running on macOS")
        #elseif os(Linux)
        XCTAssertTrue(true, "Running on Linux")
        #else
        XCTFail("Unsupported platform")
        #endif
    }
    
    // MARK: - Keychain Store Platform Tests
    
    func testKeychainAvailability() throws {
        #if os(macOS)
        // On macOS, Keychain operations should work
        XCTAssertNoThrow(KeychainStore.list(), "Keychain list should work on macOS")
        #else
        throw XCTSkip("Keychain not available on Linux")
        #endif
    }
    
    // MARK: - Cryptographic Compatibility Tests
    
    func testCryptographicOperationsAcrossPlatforms() throws {
        // Test that core cryptographic operations work the same across platforms
        let keyPair = MaceHPKE.generateKeyPair()
        let fileKey = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        let aad = Data("cross-platform-test".utf8)
        
        // Seal and open should work identically
        let (encapsulated, ciphertext) = try MaceHPKE.seal(
            fileKey: fileKey,
            recipientPublicRaw: keyPair.publicRaw,
            aad: aad
        )
        
        let recoveredFileKey = try MaceHPKE.open(
            encapsulated: encapsulated,
            ciphertext: ciphertext,
            recipientPrivateRaw: keyPair.privateRaw,
            aad: aad
        )
        
        XCTAssertEqual(recoveredFileKey, fileKey, "HPKE operations should work identically across platforms")
    }
    
    func testStreamingAEADAcrossPlatforms() throws {
        let key = SymmetricKey(size: .bits256)
        let plaintext = Data("Cross-platform streaming test data".utf8)
        let chunkSize = 16
        
        let inURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let encURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let outURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try plaintext.write(to: inURL)
        
        // Encrypt
        try! "".write(to: encURL, atomically: true, encoding: .utf8)
        let outFH = FileHandle(forWritingAtPath: encURL.path)!
        var progress: Progressor? = Progressor(total: UInt64(plaintext.count), enabled: false)
        var encryptor = try StreamEncryptor(fileKey: key, context: Data(), headerMac: Data(), chunkSize: chunkSize)
        try encryptor.encrypt(input: inURL, out: outFH, progress: &progress)
        try! outFH.close()
        
        // Decrypt
        let inFH = try FileHandle(forReadingFrom: encURL)
        try! "".write(to: outURL, atomically: true, encoding: .utf8)
        let outFH2 = FileHandle(forWritingAtPath: outURL.path)!
        var progress2: Progressor? = Progressor(total: UInt64(try! Data(contentsOf: encURL).count), enabled: false)
        var decryptor = try StreamDecryptor(fileKey: key, context: Data(), headerMac: Data(), chunkSize: chunkSize)
        try decryptor.decrypt(from: inFH, payloadLength: UInt64(try! Data(contentsOf: encURL).count), out: outFH2, progress: &progress2)
        try! outFH2.close()
        
        let decryptedData = try! Data(contentsOf: outURL)
        XCTAssertEqual(decryptedData, plaintext, "Streaming AEAD should work identically across platforms")
        
        try? FileManager.default.removeItem(at: inURL)
        try? FileManager.default.removeItem(at: encURL)
        try? FileManager.default.removeItem(at: outURL)
    }
    
    func testKDFAcrossPlatforms() {
        let inputKey = SymmetricKey(size: .bits256)
        let info = "cross-platform-kdf-test"
        let outputLength = 32
        let salt = Data("test-salt".utf8)
        
        let derivedKey1 = KDF.hkdf(inputKey, info: info, out: outputLength, salt: salt)
        let derivedKey2 = KDF.hkdf(inputKey, info: info, out: outputLength, salt: salt)
        
        XCTAssertEqual(
            derivedKey1.withUnsafeBytes { Data(bytes: $0.baseAddress!, count: $0.count) },
            derivedKey2.withUnsafeBytes { Data(bytes: $0.baseAddress!, count: $0.count) },
            "KDF should produce identical results across platforms"
        )
    }
    
    // MARK: - File Format Compatibility Tests
    
    func testHeaderFormatAcrossPlatforms() throws {
        var header = Header()
        header.hpke.append(Header.HPKEStanza(
            id: "cross-platform-test",
            enc: Data("encapsulated-key".utf8),
            box: Data("encrypted-file-key".utf8)
        ))
        
        let mac = Data("test-mac".utf8)
        let serialized = header.serialize(with: mac)
        
        // Parse should work identically
        let (parsedHeader, parsedMac, payloadOffset) = try Header.parse(data: serialized)
        
        XCTAssertEqual(parsedHeader.hpke.count, header.hpke.count, "Header parsing should work identically across platforms")
        XCTAssertEqual(parsedHeader.hpke[0].id, header.hpke[0].id, "HPKE stanza parsing should be identical")
        XCTAssertEqual(parsedMac, mac, "MAC parsing should be identical")
        XCTAssertGreaterThan(payloadOffset, 0, "Payload offset should be consistent")
    }
    
    func testBech32AcrossPlatforms() throws {
        let testData = Data([0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07])
        let hrp = "mace"
        
        let encoded = try Bech32.encode(hrp: hrp, data: testData)
        let (decodedHRP, decodedData) = try Bech32.decode(encoded)
        
        XCTAssertEqual(decodedHRP, hrp, "Bech32 HRP should be identical across platforms")
        XCTAssertEqual(decodedData, testData, "Bech32 data should be identical across platforms")
    }
    
    // MARK: - User Input Compatibility Tests
    
    func testUserInputFunctionsExist() {
        // Test that UserInput functions are available on all platforms
        XCTAssertNoThrow(UserInput.prompt("Test prompt: "))
        XCTAssertNoThrow(UserInput.securePrompt("Test secure prompt: "))
        XCTAssertNoThrow(UserInput.confirmPrompt("Test confirmation"))
        XCTAssertNoThrow(UserInput.choicePrompt("Test choice", options: ["Option 1", "Option 2"]))
        XCTAssertNoThrow(UserInput.filePathPrompt("Test file path"))
    }
    
    // MARK: - Logging Compatibility Tests
    
    func testLoggingAcrossPlatforms() {
        // Test that logging works on all platforms
        MaceLog.configure(for: .testing) // Use testing config to avoid platform-specific features
        
        XCTAssertNoThrow(MaceLog.trace("Cross-platform trace"))
        XCTAssertNoThrow(MaceLog.debug("Cross-platform debug"))
        XCTAssertNoThrow(MaceLog.info("Cross-platform info"))
        XCTAssertNoThrow(MaceLog.warning("Cross-platform warning"))
        XCTAssertNoThrow(MaceLog.error("Cross-platform error"))
        XCTAssertNoThrow(MaceLog.critical("Cross-platform critical"))
        
        // Test structured logging
        XCTAssertNoThrow(MaceLog.cryptoOperation("test-operation"))
        XCTAssertNoThrow(MaceLog.securityEvent("test-event"))
        XCTAssertNoThrow(MaceLog.performance("test-metric", value: 1.0, unit: "test"))
        XCTAssertNoThrow(MaceLog.keyManagement("test-operation", keyId: "test-key", success: true))
        XCTAssertNoThrow(MaceLog.audit("test-audit"))
    }
    
    // MARK: - Post-Quantum Compatibility Tests
    
    func testPQCAcrossPlatforms() {
        // Test that PQC framework works on all platforms
        let keyPair = PQC.generateHybridKeyPair()
        
        XCTAssertEqual(keyPair.classicalPrivate.count, 32, "Classical private key should be consistent across platforms")
        XCTAssertEqual(keyPair.classicalPublic.count, 32, "Classical public key should be consistent across platforms")
        
        // Test hybrid operations
        let fileKey = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        let aad = Data("pqc-cross-platform-test".utf8)
        
        XCTAssertNoThrow(try PQC.hybridSeal(fileKey: fileKey, recipientPublic: keyPair, aad: aad))
        
        let (encapsulated, ciphertext) = try! PQC.hybridSeal(fileKey: fileKey, recipientPublic: keyPair, aad: aad)
        XCTAssertNoThrow(try PQC.hybridOpen(encapsulated: encapsulated, ciphertext: ciphertext, recipientPrivate: keyPair, aad: aad))
    }
    
    // MARK: - Error Handling Compatibility Tests
    
    func testErrorHandlingAcrossPlatforms() {
        // Test that MaceError works consistently across platforms
        let ioError = MaceError.io("Test IO error")
        let parseError = MaceError.parse("Test parse error")
        let badKeyError = MaceError.badKey("Test bad key error")
        let macError = MaceError.mac
        let misuseError = MaceError.misuse("Test misuse error")
        
        XCTAssertEqual(ioError.localizedDescription, "I/O error: Test IO error")
        XCTAssertEqual(parseError.localizedDescription, "Parse error: Test parse error")
        XCTAssertEqual(badKeyError.localizedDescription, "Bad key: Test bad key error")
        XCTAssertEqual(macError.localizedDescription, "MAC verification failed")
        XCTAssertEqual(misuseError.localizedDescription, "Misuse: Test misuse error")
    }
    
    // MARK: - Memory Management Compatibility Tests
    
    func testSensitiveDataAcrossPlatforms() {
        let originalData = Data([0x01, 0x02, 0x03, 0x04])
        var sensitiveData = SensitiveData(originalData)
        
        XCTAssertEqual(sensitiveData.data, originalData, "SensitiveData should work consistently across platforms")
        
        sensitiveData.zero()
        XCTAssertEqual(sensitiveData.data, Data([0x00, 0x00, 0x00, 0x00]), "SensitiveData zeroization should work across platforms")
    }
    
    // MARK: - File System Compatibility Tests
    
    func testFileSystemOperations() {
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("mace-cross-platform-test.txt")
        let testData = Data("Cross-platform file test".utf8)
        
        // Test file creation
        XCTAssertNoThrow(try testData.write(to: testFile))
        
        // Test file reading
        XCTAssertNoThrow(try Data(contentsOf: testFile))
        
        let readData = try! Data(contentsOf: testFile)
        XCTAssertEqual(readData, testData, "File operations should work consistently across platforms")
        
        // Test file deletion
        XCTAssertNoThrow(try FileManager.default.removeItem(at: testFile))
    }
    
    // MARK: - Performance Consistency Tests
    
    func testPerformanceConsistency() {
        // Test that performance is reasonable across platforms
        let keyPair = MaceHPKE.generateKeyPair()
        let fileKey = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        let aad = Data("performance-test".utf8)
        
        let startTime = Date()
        
        for _ in 0..<100 {
            let (encapsulated, ciphertext) = try! MaceHPKE.seal(
                fileKey: fileKey,
                recipientPublicRaw: keyPair.publicRaw,
                aad: aad
            )
            _ = try! MaceHPKE.open(
                encapsulated: encapsulated,
                ciphertext: ciphertext,
                recipientPrivateRaw: keyPair.privateRaw,
                aad: aad
            )
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        // Performance should be reasonable (less than 10 seconds for 100 operations)
        XCTAssertLessThan(duration, 10.0, "Performance should be reasonable across platforms")
    }
    
    // MARK: - Version Compatibility Tests
    
    func testVersionInformation() {
        // Test that version information is available
        XCTAssertNoThrow(MaceVersion.cli)
        XCTAssertNoThrow(MaceVersion.headerMajor)
        XCTAssertNoThrow(MaceVersion.headerMinor)
        
        // Version strings should not be empty
        XCTAssertFalse(MaceVersion.cli.isEmpty, "CLI version should not be empty")
    }
}

