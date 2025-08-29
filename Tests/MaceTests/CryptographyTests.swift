import XCTest
import Foundation
@testable import MaceCore
#if canImport(CryptoKit)
import CryptoKit
#else
import Crypto
#endif

final class CryptographyTests: XCTestCase {
    
    // MARK: - HPKE Tests
    
    func testHPKEKeyGeneration() throws {
        let keyPair = MaceHPKE.generateKeyPair()
        
        XCTAssertEqual(keyPair.privateRaw.count, 32, "Private key should be 32 bytes")
        XCTAssertEqual(keyPair.publicRaw.count, 32, "Public key should be 32 bytes")
        XCTAssertNotEqual(keyPair.privateRaw, keyPair.publicRaw, "Private and public keys should be different")
    }
    
    func testHPKESealAndOpen() throws {
        let keyPair = MaceHPKE.generateKeyPair()
        let fileKey = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        let aad = Data("test-aad".utf8)
        
        // Seal the file key
        let (encapsulated, ciphertext) = try MaceHPKE.seal(
            fileKey: fileKey,
            recipientPublicRaw: keyPair.publicRaw,
            aad: aad
        )
        
        XCTAssertEqual(encapsulated.count, 32, "Encapsulated key should be 32 bytes")
        XCTAssertGreaterThan(ciphertext.count, fileKey.count, "Ciphertext should be larger than plaintext due to authentication tag")
        
        // Open the file key
        let recoveredFileKey = try MaceHPKE.open(
            encapsulated: encapsulated,
            ciphertext: ciphertext,
            recipientPrivateRaw: keyPair.privateRaw,
            aad: aad
        )
        
        XCTAssertEqual(recoveredFileKey, fileKey, "Recovered file key should match original")
    }
    
    func testHPKEWithWrongAAD() throws {
        let keyPair = MaceHPKE.generateKeyPair()
        let fileKey = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        let correctAAD = Data("correct-aad".utf8)
        let wrongAAD = Data("wrong-aad".utf8)
        
        let (encapsulated, ciphertext) = try MaceHPKE.seal(
            fileKey: fileKey,
            recipientPublicRaw: keyPair.publicRaw,
            aad: correctAAD
        )
        
        // Should fail with wrong AAD
        XCTAssertThrowsError(try MaceHPKE.open(
            encapsulated: encapsulated,
            ciphertext: ciphertext,
            recipientPrivateRaw: keyPair.privateRaw,
            aad: wrongAAD
        )) { error in
            XCTAssertTrue(error is MaceError, "Should throw MaceError for authentication failure")
        }
    }
    
    // MARK: - KDF Tests
    
    func testHKDF() throws {
        let inputKey = SymmetricKey(size: .bits256)
        let info = "test-info"
        let outputLength = 32
        let salt = Data("test-salt".utf8)
        
        let derivedKey1 = KDF.hkdf(inputKey, info: info, out: outputLength, salt: salt)
        let derivedKey2 = KDF.hkdf(inputKey, info: info, out: outputLength, salt: salt)
        
        // Same inputs should produce same output
        XCTAssertEqual(
            derivedKey1.withUnsafeBytes { Data($0) },
            derivedKey2.withUnsafeBytes { Data($0) },
            "HKDF should be deterministic"
        )
        
        // Different info should produce different output
        let derivedKey3 = KDF.hkdf(inputKey, info: "different-info", out: outputLength, salt: salt)
        XCTAssertNotEqual(
            derivedKey1.withUnsafeBytes { Data($0) },
            derivedKey3.withUnsafeBytes { Data($0) },
            "Different info should produce different keys"
        )
    }
    
    // MARK: - Streaming AEAD Tests
    
    func testStreamingEncryptionDecryption() throws {
        let key = SymmetricKey(size: .bits256)
        let plaintext = Data("Hello, World! This is a test message for streaming encryption.".utf8)
        let chunkSize = 16
        
        let inURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let encURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let outURL = try TestFS.tempDir().appendingPathComponent("decrypted.bin")
        try plaintext.write(to: inURL)
        
        // Encrypt
        try TestFS.ensureEmptyFile(at: encURL)
        let outFH = try FileHandle(forWritingTo: encURL)
        var progress: Progressor? = Progressor(total: UInt64(plaintext.count), enabled: false)
        var encryptor = try StreamEncryptor(fileKey: key, context: Data(), headerMac: Data(), chunkSize: chunkSize)
        try encryptor.encrypt(input: inURL, out: outFH, progress: &progress)
        try! outFH.close()
        
        // Decrypt
        let inFH = try FileHandle(forReadingFrom: encURL)
        try TestFS.ensureEmptyFile(at: outURL)
        let outFH2 = try FileHandle(forWritingTo: outURL)
        var progress2: Progressor? = Progressor(total: UInt64(try! Data(contentsOf: encURL).count), enabled: false)
        var decryptor = try StreamDecryptor(fileKey: key, context: Data(), headerMac: Data(), chunkSize: chunkSize)
        try decryptor.decrypt(from: inFH, payloadLength: UInt64(try! Data(contentsOf: encURL).count), out: outFH2, progress: &progress2)
        try! outFH2.close()
        
        let decryptedData = try! Data(contentsOf: outURL)
        XCTAssertEqual(decryptedData, plaintext, "Decrypted data should match original plaintext")
        
        try? FileManager.default.removeItem(at: inURL)
        try? FileManager.default.removeItem(at: encURL)
        try? FileManager.default.removeItem(at: outURL)
    }
    
    func testStreamingWithTamperedData() throws {
        let key = SymmetricKey(size: .bits256)
        let plaintext = Data("Test message".utf8)
        let chunkSize = 8
        
        let inURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let encURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try plaintext.write(to: inURL)
        
        // Encrypt
        try TestFS.ensureEmptyFile(at: encURL)
        let outFH = try FileHandle(forWritingTo: encURL)
        var progress: Progressor? = Progressor(total: UInt64(plaintext.count), enabled: false)
        var encryptor = try StreamEncryptor(fileKey: key, context: Data(), headerMac: Data(), chunkSize: chunkSize)
        try encryptor.encrypt(input: inURL, out: outFH, progress: &progress)
        try! outFH.close()
        
        // Tamper with the encrypted data
        var tamperedData = try! Data(contentsOf: encURL)
        tamperedData[0] ^= 0x01 // Flip one bit
        let tamperedURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try! tamperedData.write(to: tamperedURL)
        
        // Decrypt should fail
        let inFH = try FileHandle(forReadingFrom: tamperedURL)
        try TestFS.ensureEmptyFile(at: outURL)
        let outFH2 = try FileHandle(forWritingTo: outURL)
        var progress2: Progressor? = Progressor(total: UInt64(tamperedData.count), enabled: false)
        var decryptor = try StreamDecryptor(fileKey: key, context: Data(), headerMac: Data(), chunkSize: chunkSize)
        XCTAssertThrowsError(try decryptor.decrypt(from: inFH, payloadLength: UInt64(tamperedData.count), out: outFH2, progress: &progress2)) { error in
            XCTAssertTrue(error is MaceError, "Should throw MaceError for authentication failure")
        }
        
        try? FileManager.default.removeItem(at: inURL)
        try? FileManager.default.removeItem(at: encURL)
        try? FileManager.default.removeItem(at: tamperedURL)
        try? FileManager.default.removeItem(at: outURL)
    }
    
    // MARK: - Format Tests
    
    func testHeaderSerialization() throws {
        var header = Header()
        header.hpke.append(Header.HPKEStanza(
            id: "test-id",
            enc: Data("encapsulated".utf8),
            box: Data("ciphertext".utf8)
        ))
        
        let mac = Data("test-mac".utf8)
        let serialized = header.serialize(with: mac)
        
        XCTAssertTrue(serialized.count > 0, "Serialized header should not be empty")
        
        // Test deserialization
        let (parsedHeader, parsedMac, payloadOffset) = try Header.parse(data: serialized)
        
        XCTAssertEqual(parsedHeader.hpke.count, header.hpke.count, "Parsed header should have same number of HPKE stanzas")
        XCTAssertEqual(parsedHeader.hpke[0].id, header.hpke[0].id, "HPKE stanza ID should match")
        XCTAssertEqual(parsedMac, mac, "Parsed MAC should match original")
        XCTAssertGreaterThan(payloadOffset, 0, "Payload offset should be positive")
    }
    
    func testHeaderWithoutMAC() throws {
        var header = Header()
        header.hpke.append(Header.HPKEStanza(
            id: "test-id",
            enc: Data("encapsulated".utf8),
            box: Data("ciphertext".utf8)
        ))
        
        let serialized = header.serialize(with: nil)
        
        XCTAssertTrue(serialized.count > 0, "Serialized header should not be empty")
        
        // Test deserialization
        let (parsedHeader, parsedMac, payloadOffset) = try Header.parse(data: serialized)
        
        XCTAssertEqual(parsedHeader.hpke.count, header.hpke.count, "Parsed header should have same number of HPKE stanzas")
        XCTAssertNil(parsedMac, "Parsed MAC should be nil when not provided")
        XCTAssertGreaterThan(payloadOffset, 0, "Payload offset should be positive")
    }
    
    // MARK: - Bech32 Tests
    
    func testBech32Encoding() throws {
        let testData = Data([0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07])
        let encoded = try Bech32.encode(hrp: "test", data: testData)
        
        XCTAssertTrue(encoded.hasPrefix("test1"), "Encoded string should start with HRP and separator")
        XCTAssertTrue(encoded.count > 10, "Encoded string should be reasonably long")
        
        // Test round-trip
        let (decodedHRP, decodedData) = try Bech32.decode(encoded)
        
        XCTAssertEqual(decodedHRP, "test", "Decoded HRP should match original")
        XCTAssertEqual(decodedData, testData, "Decoded data should match original")
    }
    
    func testBech32InvalidInput() throws {
        // Test invalid characters
        XCTAssertThrowsError(try Bech32.decode("test1invalid_character")) { error in
            XCTAssertTrue(error is MaceError, "Should throw MaceError for invalid characters")
        }
        
        // Test invalid checksum
        XCTAssertThrowsError(try Bech32.decode("test1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq")) { error in
            XCTAssertTrue(error is MaceError, "Should throw MaceError for invalid checksum")
        }
    }
    
    // MARK: - Identity Tests
    
    func testIdentityCreation() throws {
        let label = "test@example.com"
        let publicKey = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        
        let identity = try Identity(label: label, publicRaw: publicKey)
        
        XCTAssertEqual(identity.label, label, "Identity label should match")
        XCTAssertEqual(identity.publicRaw, publicKey, "Identity public key should match")
        XCTAssertTrue(try Bech32.encode(hrp: "mace", data: identity.publicRaw).hasPrefix("mace1"), "Bech32 encoding should start with 'mace1'")
    }
    
    func testRecipientPublicKey() throws {
        let publicKey = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        
        let recipient = try RecipientPublicKey(raw: publicKey)
        
        XCTAssertEqual(recipient.raw, publicKey, "Recipient public key should match")
        XCTAssertTrue(recipient.bech32.hasPrefix("mace1"), "Bech32 encoding should start with 'mace1'")
        
        // Test round-trip through bech32
        let parsedRecipient = try RecipientPublicKey.parse(recipient.bech32)
        XCTAssertEqual(parsedRecipient, publicKey, "Parsed recipient key should match original")
    }
    
    // MARK: - Sensitive Data Tests
    
    func testSensitiveDataZeroization() throws {
        let originalData = Data([0x01, 0x02, 0x03, 0x04])
        var sensitiveData = SensitiveData(originalData)
        
        XCTAssertEqual(sensitiveData.data, originalData, "Sensitive data should initially match original")
        
        sensitiveData.zero()
        
        XCTAssertEqual(sensitiveData.data, Data([0x00, 0x00, 0x00, 0x00]), "Sensitive data should be zeroed")
    }
    
    // MARK: - Error Handling Tests
    
    func testMaceErrorTypes() {
        let ioError = MaceError.io("Test IO error")
        let parseError = MaceError.parse("Test parse error")
        let badKeyError = MaceError.badKey("Test bad key error")
        let macError = MaceError.mac
        let misuseError = MaceError.misuse("Test misuse error")
        
        XCTAssertEqual(ioError.description, "I/O error: Test IO error")
        XCTAssertEqual(parseError.description, "Parse error: Test parse error")
        XCTAssertEqual(badKeyError.description, "Bad key: Test bad key error")
        XCTAssertEqual(macError.description, "MAC verification failed")
        XCTAssertEqual(misuseError.description, "Misuse: Test misuse error")
    }
    
    // MARK: - Performance Tests
    
    func testHPKEPerformance() throws {
        let keyPair = MaceHPKE.generateKeyPair()
        let fileKey = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        let aad = Data("performance-test".utf8)
        
        measure {
            for _ in 0..<100 {
                do {
                    let (encapsulated, ciphertext) = try MaceHPKE.seal(
                        fileKey: fileKey,
                        recipientPublicRaw: keyPair.publicRaw,
                        aad: aad
                    )
                    _ = try MaceHPKE.open(
                        encapsulated: encapsulated,
                        ciphertext: ciphertext,
                        recipientPrivateRaw: keyPair.privateRaw,
                        aad: aad
                    )
                } catch {
                    XCTFail("HPKE operation failed: \(error)")
                }
            }
        }
    }
    
    func testStreamingPerformance() throws {
        let key = SymmetricKey(size: .bits256)
        let largeData = Data((0..<10000).map { _ in UInt8.random(in: 0...255) })
        let chunkSize = 1024
        
        let inURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let encURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let outURL = try TestFS.tempDir().appendingPathComponent("decrypted.bin")
        try largeData.write(to: inURL)
        
        measure {
            do {
                // Encrypt
                try TestFS.ensureEmptyFile(at: encURL)
        let outFH = try FileHandle(forWritingTo: encURL)
                var progress: Progressor? = Progressor(total: UInt64(largeData.count), enabled: false)
                var encryptor = try StreamEncryptor(fileKey: key, context: Data(), headerMac: Data(), chunkSize: chunkSize)
                try encryptor.encrypt(input: inURL, out: outFH, progress: &progress)
                try! outFH.close()
                
                // Decrypt
                let inFH = try FileHandle(forReadingFrom: encURL)
                try TestFS.ensureEmptyFile(at: outURL)
        let outFH2 = try FileHandle(forWritingTo: outURL)
                var progress2: Progressor? = Progressor(total: UInt64(try! Data(contentsOf: encURL).count), enabled: false)
                var decryptor = try StreamDecryptor(fileKey: key, context: Data(), headerMac: Data(), chunkSize: chunkSize)
                try decryptor.decrypt(from: inFH, payloadLength: UInt64(try! Data(contentsOf: encURL).count), out: outFH2, progress: &progress2)
                try! outFH2.close()
                
                let decryptedData = try! Data(contentsOf: outURL)
                XCTAssertEqual(decryptedData.count, largeData.count, "Decrypted data size should match original")
            } catch {
                XCTFail("Streaming operation failed: \(error)")
            }
        }
        
        try? FileManager.default.removeItem(at: inURL)
        try? FileManager.default.removeItem(at: encURL)
        try? FileManager.default.removeItem(at: outURL)
    }
}

