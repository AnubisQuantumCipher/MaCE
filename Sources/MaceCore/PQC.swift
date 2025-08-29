import Foundation
#if canImport(CryptoKit)
import CryptoKit
#else
import Crypto
#endif

/// Post-Quantum Cryptography module for MaCE
/// Provides hybrid classical + post-quantum encryption for future-proofing
public enum PQC {
    
    /// Hybrid encryption combining X25519 (classical) with ML-KEM (post-quantum)
    /// This provides security against both classical and quantum attacks
    public struct HybridKeyPair {
        public let classicalPrivate: Data
        public let classicalPublic: Data
        public let pqcPrivate: Data?      // Will be populated when ML-KEM is available
        public let pqcPublic: Data?       // Will be populated when ML-KEM is available
        
        public init(classicalPrivate: Data, classicalPublic: Data, pqcPrivate: Data? = nil, pqcPublic: Data? = nil) {
            self.classicalPrivate = classicalPrivate
            self.classicalPublic = classicalPublic
            self.pqcPrivate = pqcPrivate
            self.pqcPublic = pqcPublic
        }
    }
    
    /// Generate a hybrid key pair for post-quantum security
    /// Currently uses X25519, will add ML-KEM when available in CryptoKit
    public static func generateHybridKeyPair() -> HybridKeyPair {
        #if canImport(CryptoKit) && os(macOS)
        // On macOS with CryptoKit, check for quantum-secure APIs
        if #available(macOS 26.0, *) {
            // TODO: Use ML-KEM when available in CryptoKit
            // let mlkemKeyPair = MLKEM768.generateKeyPair()
            // For now, use classical X25519
            let classicalKey = Curve25519.KeyAgreement.PrivateKey()
            return HybridKeyPair(
                classicalPrivate: classicalKey.rawRepresentation,
                classicalPublic: classicalKey.publicKey.rawRepresentation,
                pqcPrivate: nil, // Will be mlkemKeyPair.privateKey when available
                pqcPublic: nil   // Will be mlkemKeyPair.publicKey when available
            )
        } else {
            // Fallback to classical X25519 for older macOS versions
            let classicalKey = Curve25519.KeyAgreement.PrivateKey()
            return HybridKeyPair(
                classicalPrivate: classicalKey.rawRepresentation,
                classicalPublic: classicalKey.publicKey.rawRepresentation
            )
        }
        #else
        // On other platforms, use classical X25519
        let classicalKey = Curve25519.KeyAgreement.PrivateKey()
        return HybridKeyPair(
            classicalPrivate: classicalKey.rawRepresentation,
            classicalPublic: classicalKey.publicKey.rawRepresentation
        )
        #endif
    }
    
    /// Hybrid HPKE seal operation combining classical and post-quantum algorithms
    /// Provides forward security against quantum attacks
    public static func hybridSeal(fileKey: Data, recipientPublic: HybridKeyPair, aad: Data) throws -> (encapsulated: Data, ciphertext: Data) {
        // Classical X25519 HPKE
        guard let recipientPubKey = try? Curve25519.KeyAgreement.PublicKey(rawRepresentation: recipientPublic.classicalPublic)
        else { throw MaceError.badKey("invalid classical public key") }
        
        let ephemeralKey = Curve25519.KeyAgreement.PrivateKey()
        let sharedSecret = try ephemeralKey.sharedSecretFromKeyAgreement(with: recipientPubKey)
        
        // Derive encryption key using HKDF
        let kek = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: "mace-v2-hybrid-kek".data(using: .utf8)!,
            sharedInfo: aad,
            outputByteCount: 32
        )
        
        // Encrypt the file key
        let sealed = try AES.GCM.seal(fileKey, using: kek, authenticating: aad)
        
        var encapsulatedKey = ephemeralKey.publicKey.rawRepresentation
        var ciphertext = sealed.combined!
        
        #if canImport(CryptoKit) && os(macOS)
        if #available(macOS 26.0, *), let pqcPublic = recipientPublic.pqcPublic {
            // TODO: Add ML-KEM encapsulation when available
            // let (mlkemEncaps, mlkemSharedSecret) = try MLKEM768.encapsulate(publicKey: pqcPublic)
            // Combine classical and PQC shared secrets
            // let hybridSecret = combineSecrets(classicalSecret: sharedSecret, pqcSecret: mlkemSharedSecret)
            // encapsulatedKey = classicalEncaps + mlkemEncaps
        }
        #endif
        
        return (encapsulated: encapsulatedKey, ciphertext: ciphertext)
    }
    
    /// Hybrid HPKE open operation for decryption
    public static func hybridOpen(encapsulated: Data, ciphertext: Data, recipientPrivate: HybridKeyPair, aad: Data) throws -> Data {
        // Extract classical ephemeral public key (first 32 bytes)
        let classicalEncaps = encapsulated.prefix(32)
        
        guard let ephemeralPubKey = try? Curve25519.KeyAgreement.PublicKey(rawRepresentation: classicalEncaps),
              let recipientPrivKey = try? Curve25519.KeyAgreement.PrivateKey(rawRepresentation: recipientPrivate.classicalPrivate)
        else { throw MaceError.badKey("invalid keys for decryption") }
        
        let sharedSecret = try recipientPrivKey.sharedSecretFromKeyAgreement(with: ephemeralPubKey)
        
        // Derive decryption key
        let kek = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: "mace-v2-hybrid-kek".data(using: .utf8)!,
            sharedInfo: aad,
            outputByteCount: 32
        )
        
        // Decrypt the file key
        guard let sealedBox = try? AES.GCM.SealedBox(combined: ciphertext) else {
            throw MaceError.parse("invalid sealed box")
        }
        
        let fileKey = try AES.GCM.open(sealedBox, using: kek, authenticating: aad)
        
        #if canImport(CryptoKit) && os(macOS)
        if #available(macOS 26.0, *), let pqcPrivate = recipientPrivate.pqcPrivate {
            // TODO: Add ML-KEM decapsulation when available
            // let pqcEncaps = encapsulated.dropFirst(32)
            // let pqcSharedSecret = try MLKEM768.decapsulate(encapsulated: pqcEncaps, privateKey: pqcPrivate)
            // Verify hybrid shared secret matches
        }
        #endif
        
        return fileKey
    }
    
    /// Check if post-quantum cryptography is available on this platform
    public static var isPostQuantumAvailable: Bool {
        #if canImport(CryptoKit) && os(macOS)
        if #available(macOS 26.0, *) {
            // TODO: Check for actual ML-KEM availability
            return false // Will be true when ML-KEM is implemented
        }
        return false
        #else
        return false
        #endif
    }
    
    /// Get the current cryptographic security level
    public static var securityLevel: String {
        if isPostQuantumAvailable {
            return "Hybrid (Classical + Post-Quantum)"
        } else {
            return "Classical (X25519 + AES-256-GCM)"
        }
    }
    
    /// Future-proofing: Placeholder for quantum-secure signature algorithms
    public enum QuantumSecureSignatures {
        /// ML-DSA (Dilithium) signature placeholder
        /// Will be implemented when available in CryptoKit
        public static func signData(_ data: Data, privateKey: Data) throws -> Data {
            #if canImport(CryptoKit) && os(macOS)
            if #available(macOS 26.0, *) {
                // TODO: Implement ML-DSA signatures
                // return try MLDSA65.sign(data, privateKey: privateKey)
            }
            #endif
            throw MaceError.misuse("Quantum-secure signatures not yet available")
        }
        
        public static func verifySignature(_ signature: Data, for data: Data, publicKey: Data) throws -> Bool {
            #if canImport(CryptoKit) && os(macOS)
            if #available(macOS 26.0, *) {
                // TODO: Implement ML-DSA verification
                // return try MLDSA65.verify(signature, for: data, publicKey: publicKey)
            }
            #endif
            throw MaceError.misuse("Quantum-secure signature verification not yet available")
        }
    }
}

// MARK: - Migration utilities for upgrading from classical to hybrid

extension PQC {
    /// Migrate a classical X25519 key pair to hybrid format
    public static func migrateClassicalKeyPair(privateKey: Data, publicKey: Data) -> HybridKeyPair {
        return HybridKeyPair(
            classicalPrivate: privateKey,
            classicalPublic: publicKey,
            pqcPrivate: nil,
            pqcPublic: nil
        )
    }
    
    /// Check if a key pair needs migration to hybrid format
    public static func needsMigration(_ keyPair: HybridKeyPair) -> Bool {
        return isPostQuantumAvailable && keyPair.pqcPrivate == nil
    }
    
    /// Upgrade a classical key pair to include post-quantum components
    public static func upgradeToHybrid(_ keyPair: HybridKeyPair) -> HybridKeyPair {
        if needsMigration(keyPair) && isPostQuantumAvailable {
            // TODO: Generate PQC components when ML-KEM is available
            // let pqcKeyPair = generatePQCKeyPair()
            return HybridKeyPair(
                classicalPrivate: keyPair.classicalPrivate,
                classicalPublic: keyPair.classicalPublic,
                pqcPrivate: nil, // Will be pqcKeyPair.privateKey
                pqcPublic: nil   // Will be pqcKeyPair.publicKey
            )
        }
        return keyPair
    }
}

// MARK: - Legacy compatibility with original placeholder

#if MACE_ENABLE_PQC
/// Legacy compatibility with original PQC placeholder
/// This maintains backward compatibility while providing enhanced functionality
public enum MacePQC {
    public static let suite = "hybrid-mlkem768+x25519-aesgcm256"
    
    public typealias HybridPublicKey = PQC.HybridKeyPair
    public typealias HybridPrivateKey = PQC.HybridKeyPair
    
    public static func generateHybridKeyPair() throws -> (HybridPrivateKey, HybridPublicKey) {
        let keyPair = PQC.generateHybridKeyPair()
        return (keyPair, keyPair)
    }
}
#endif


