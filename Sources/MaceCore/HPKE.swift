import Foundation
#if canImport(CryptoKit)
import CryptoKit
#else
import Crypto
#endif

@available(macOS 13.0, *)
public enum MaceHPKE {
    public static func generateKeyPair() -> (privateRaw: Data, publicRaw: Data) {
        let sk = Curve25519.KeyAgreement.PrivateKey()
        return (sk.rawRepresentation, sk.publicKey.rawRepresentation)
    }

    public static func seal(fileKey: Data, recipientPublicRaw: Data, aad: Data) throws -> (encapsulated: Data, ciphertext: Data) {
        guard let recipientPub = try? Curve25519.KeyAgreement.PublicKey(rawRepresentation: recipientPublicRaw)
        else { throw MaceError.badKey("recipient pub invalid") }
        let eph = Curve25519.KeyAgreement.PrivateKey()
        let secret = try eph.sharedSecretFromKeyAgreement(with: recipientPub)
        let kek = secret.hkdfDerivedSymmetricKey(using: SHA256.self,
                                                 salt: "mace-v1-key-wrap".data(using: .utf8)!,
                                                 sharedInfo: aad,
                                                 outputByteCount: 32)
        let sealed = try AES.GCM.seal(fileKey, using: kek, authenticating: aad)
        guard let combined = sealed.combined else { throw MaceError.crypto("GCM combined nil") }
        return (eph.publicKey.rawRepresentation, combined)
    }

    public static func open(encapsulated: Data, ciphertext: Data, myPrivateRaw: Data, aad: Data) throws -> Data {
        guard let sk = try? Curve25519.KeyAgreement.PrivateKey(rawRepresentation: myPrivateRaw)
        else { throw MaceError.badKey("private key invalid") }
        guard let ephPub = try? Curve25519.KeyAgreement.PublicKey(rawRepresentation: encapsulated)
        else { throw MaceError.badKey("encapsulated eph key invalid") }
        let secret = try sk.sharedSecretFromKeyAgreement(with: ephPub)
        let kek = secret.hkdfDerivedSymmetricKey(using: SHA256.self,
                                                 salt: "mace-v1-key-wrap".data(using: .utf8)!,
                                                 sharedInfo: aad,
                                                 outputByteCount: 32)
        let box = try AES.GCM.SealedBox(combined: ciphertext)
        return try AES.GCM.open(box, using: kek, authenticating: aad)
    }

    // Compatibility overload
    @_disfavoredOverload
    public static func open(encapsulated: Data, ciphertext: Data, recipientPrivateRaw: Data, aad: Data) throws -> Data {
        return try open(encapsulated: encapsulated, ciphertext: ciphertext, myPrivateRaw: recipientPrivateRaw, aad: aad)
    }
}


