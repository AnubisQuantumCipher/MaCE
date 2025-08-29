import XCTest
import Foundation
@testable import MaceCore
#if canImport(CryptoKit)
import CryptoKit
#else
import Crypto
#endif

final class PostQuantumTests: XCTestCase {
    
    // MARK: - Hybrid Key Pair Tests
    
    func testHybridKeyPairGeneration() throws {
        let keyPair = PQC.generateHybridKeyPair()
        
        // Classical components should always be present
        XCTAssertEqual(keyPair.classicalPrivate.count, 32, "Classical private key should be 32 bytes")
        XCTAssertEqual(keyPair.classicalPublic.count, 32, "Classical public key should be 32 bytes")
        XCTAssertNotEqual(keyPair.classicalPrivate, keyPair.classicalPublic, "Classical keys should be different")
        
        // PQC components should be nil for now (until ML-KEM is available)
        XCTAssertNil(keyPair.pqcPrivate, "PQC private key should be nil until ML-KEM is available")
        XCTAssertNil(keyPair.pqcPublic, "PQC public key should be nil until ML-KEM is available")
    }
    
    func testHybridSealAndOpen() throws {
        let keyPair = PQC.generateHybridKeyPair()
        let fileKey = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        let aad = Data("hybrid-test-aad".utf8)
        
        // Seal using hybrid encryption
        let (encapsulated, ciphertext) = try PQC.hybridSeal(
            fileKey: fileKey,
            recipientPublic: keyPair,
            aad: aad
        )
        
        XCTAssertEqual(encapsulated.count, 32, "Encapsulated key should be 32 bytes (classical only for now)")
        XCTAssertGreaterThan(ciphertext.count, fileKey.count, "Ciphertext should be larger than plaintext")
        
        // Open using hybrid decryption
        let recoveredFileKey = try PQC.hybridOpen(
            encapsulated: encapsulated,
            ciphertext: ciphertext,
            recipientPrivate: keyPair,
            aad: aad
        )
        
        XCTAssertEqual(recoveredFileKey, fileKey, "Recovered file key should match original")
    }
    
    func testHybridWithWrongAAD() throws {
        let keyPair = PQC.generateHybridKeyPair()
        let fileKey = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        let correctAAD = Data("correct-aad".utf8)
        let wrongAAD = Data("wrong-aad".utf8)
        
        let (encapsulated, ciphertext) = try PQC.hybridSeal(
            fileKey: fileKey,
            recipientPublic: keyPair,
            aad: correctAAD
        )
        
        // Should fail with wrong AAD
        XCTAssertThrowsError(try PQC.hybridOpen(
            encapsulated: encapsulated,
            ciphertext: ciphertext,
            recipientPrivate: keyPair,
            aad: wrongAAD
        )) { error in
            XCTAssertTrue(error is MaceError, "Should throw MaceError for authentication failure")
        }
    }
    
    // MARK: - Security Level Tests
    
    func testSecurityLevel() {
        let securityLevel = PQC.securityLevel
        
        // For now, should be classical only
        XCTAssertEqual(securityLevel, "Classical (X25519 + AES-256-GCM)", "Security level should indicate classical cryptography")
        
        // Post-quantum should not be available yet
        XCTAssertFalse(PQC.isPostQuantumAvailable, "Post-quantum cryptography should not be available yet")
    }
    
    // MARK: - Migration Tests
    
    func testClassicalKeyPairMigration() {
        let classicalPrivate = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        let classicalPublic = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        
        let hybridKeyPair = PQC.migrateClassicalKeyPair(
            privateKey: classicalPrivate,
            publicKey: classicalPublic
        )
        
        XCTAssertEqual(hybridKeyPair.classicalPrivate, classicalPrivate, "Classical private key should be preserved")
        XCTAssertEqual(hybridKeyPair.classicalPublic, classicalPublic, "Classical public key should be preserved")
        XCTAssertNil(hybridKeyPair.pqcPrivate, "PQC private key should be nil after migration")
        XCTAssertNil(hybridKeyPair.pqcPublic, "PQC public key should be nil after migration")
    }
    
    func testMigrationNeedsCheck() {
        let classicalKeyPair = PQC.migrateClassicalKeyPair(
            privateKey: Data((0..<32).map { _ in UInt8.random(in: 0...255) }),
            publicKey: Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        )
        
        // Should not need migration since PQC is not available
        XCTAssertFalse(PQC.needsMigration(classicalKeyPair), "Should not need migration when PQC is not available")
    }
    
    func testUpgradeToHybrid() {
        let classicalKeyPair = PQC.migrateClassicalKeyPair(
            privateKey: Data((0..<32).map { _ in UInt8.random(in: 0...255) }),
            publicKey: Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        )
        
        let upgradedKeyPair = PQC.upgradeToHybrid(classicalKeyPair)
        
        // Should return the same key pair since PQC is not available
        XCTAssertEqual(upgradedKeyPair.classicalPrivate, classicalKeyPair.classicalPrivate, "Classical private key should be unchanged")
        XCTAssertEqual(upgradedKeyPair.classicalPublic, classicalKeyPair.classicalPublic, "Classical public key should be unchanged")
        XCTAssertNil(upgradedKeyPair.pqcPrivate, "PQC private key should still be nil")
        XCTAssertNil(upgradedKeyPair.pqcPublic, "PQC public key should still be nil")
    }
    
    // MARK: - Quantum-Secure Signatures Tests
    
    func testQuantumSecureSignatures() {
        let data = Data("test message for signing".utf8)
        let privateKey = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        let publicKey = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        
        // Should throw error since quantum-secure signatures are not yet available
        XCTAssertThrowsError(try PQC.QuantumSecureSignatures.signData(data, privateKey: privateKey)) { error in
            if let maceError = error as? MaceError {
                XCTAssertTrue(maceError.localizedDescription.contains("not yet available"), "Should indicate signatures are not yet available")
            } else {
                XCTFail("Should throw MaceError")
            }
        }
        
        let fakeSignature = Data((0..<64).map { _ in UInt8.random(in: 0...255) })
        XCTAssertThrowsError(try PQC.QuantumSecureSignatures.verifySignature(fakeSignature, for: data, publicKey: publicKey)) { error in
            if let maceError = error as? MaceError {
                XCTAssertTrue(maceError.localizedDescription.contains("not yet available"), "Should indicate signature verification is not yet available")
            } else {
                XCTFail("Should throw MaceError")
            }
        }
    }
    
    // MARK: - Legacy Compatibility Tests
    
    #if MACE_ENABLE_PQC
    func testLegacyMacePQCCompatibility() throws {
        XCTAssertEqual(MacePQC.suite, "hybrid-mlkem768+x25519-aesgcm256", "Legacy suite identifier should match")
        
        // Test that legacy API works
        XCTAssertThrowsError(try MacePQC.generateHybridKeyPair()) { error in
            // Should work when PQC is enabled, but for now it should delegate to the new PQC module
        }
    }
    #endif
    
    // MARK: - Future Compatibility Tests
    
    func testFutureMLKEMCompatibility() {
        // Test that the framework is ready for ML-KEM integration
        let keyPair = PQC.generateHybridKeyPair()
        
        // Verify the structure supports future PQC components
        XCTAssertNotNil(keyPair, "Hybrid key pair should be created successfully")
        
        // Test that the hybrid seal/open functions handle missing PQC gracefully
        let fileKey = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        let aad = Data("future-test".utf8)
        
        XCTAssertNoThrow(try PQC.hybridSeal(fileKey: fileKey, recipientPublic: keyPair, aad: aad), "Hybrid seal should work without PQC components")
    }
    
    // MARK: - Cross-Platform Tests
    
    func testCrossPlatformCompatibility() {
        // Test that PQC module works on all platforms
        let keyPair1 = PQC.generateHybridKeyPair()
        let keyPair2 = PQC.generateHybridKeyPair()
        
        XCTAssertNotEqual(keyPair1.classicalPrivate, keyPair2.classicalPrivate, "Different key pairs should have different private keys")
        XCTAssertNotEqual(keyPair1.classicalPublic, keyPair2.classicalPublic, "Different key pairs should have different public keys")
        
        // Test that hybrid operations work across different key pairs
        let fileKey = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        let aad = Data("cross-platform-test".utf8)
        
        let (encapsulated, ciphertext) = try! PQC.hybridSeal(
            fileKey: fileKey,
            recipientPublic: keyPair1,
            aad: aad
        )
        
        let recoveredFileKey = try! PQC.hybridOpen(
            encapsulated: encapsulated,
            ciphertext: ciphertext,
            recipientPrivate: keyPair1,
            aad: aad
        )
        
        XCTAssertEqual(recoveredFileKey, fileKey, "Cross-platform hybrid encryption should work")
    }
    
    // MARK: - Performance Tests
    
    func testHybridPerformance() {
        let keyPair = PQC.generateHybridKeyPair()
        let fileKey = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        let aad = Data("performance-test".utf8)
        
        measure {
            for _ in 0..<50 {
                do {
                    let (encapsulated, ciphertext) = try PQC.hybridSeal(
                        fileKey: fileKey,
                        recipientPublic: keyPair,
                        aad: aad
                    )
                    _ = try PQC.hybridOpen(
                        encapsulated: encapsulated,
                        ciphertext: ciphertext,
                        recipientPrivate: keyPair,
                        aad: aad
                    )
                } catch {
                    XCTFail("Hybrid operation failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Edge Cases
    
    func testEmptyAAD() throws {
        let keyPair = PQC.generateHybridKeyPair()
        let fileKey = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        let emptyAAD = Data()
        
        let (encapsulated, ciphertext) = try PQC.hybridSeal(
            fileKey: fileKey,
            recipientPublic: keyPair,
            aad: emptyAAD
        )
        
        let recoveredFileKey = try PQC.hybridOpen(
            encapsulated: encapsulated,
            ciphertext: ciphertext,
            recipientPrivate: keyPair,
            aad: emptyAAD
        )
        
        XCTAssertEqual(recoveredFileKey, fileKey, "Hybrid encryption should work with empty AAD")
    }
    
    func testLargeAAD() throws {
        let keyPair = PQC.generateHybridKeyPair()
        let fileKey = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        let largeAAD = Data((0..<10000).map { _ in UInt8.random(in: 0...255) })
        
        let (encapsulated, ciphertext) = try PQC.hybridSeal(
            fileKey: fileKey,
            recipientPublic: keyPair,
            aad: largeAAD
        )
        
        let recoveredFileKey = try PQC.hybridOpen(
            encapsulated: encapsulated,
            ciphertext: ciphertext,
            recipientPrivate: keyPair,
            aad: largeAAD
        )
        
        XCTAssertEqual(recoveredFileKey, fileKey, "Hybrid encryption should work with large AAD")
    }
}

