import XCTest
@testable import MaceCore
#if canImport(CryptoKit)
import CryptoKit
#else
import Crypto
#endif

final class MaceTests: XCTestCase {

    func testBech32Roundtrip() throws {
        let sk = Curve25519.KeyAgreement.PrivateKey()
        let pub = sk.publicKey.rawRepresentation
        let rp = try RecipientPublicKey(raw: pub)
        let s = rp.bech32
        let parsed = try RecipientPublicKey.parse(s)
        XCTAssertEqual(parsed, pub)
    }

    func testHPKERoundtrip() throws {
        let sk = Curve25519.KeyAgreement.PrivateKey()
        let (priv, pub) = (sk.rawRepresentation, sk.publicKey.rawRepresentation)
        let fileKey = SymmetricKey(size: .bits256)
        let fileKeyData = fileKey.withUnsafeBytes { Data($0) }
        let (eph, ct) = try MaceHPKE.seal(fileKey: fileKeyData, recipientPublicRaw: pub, aad: Data("aad".utf8))
        let dec = try MaceHPKE.open(encapsulated: eph, ciphertext: ct, myPrivateRaw: priv, aad: Data("aad".utf8))
        XCTAssertEqual(dec, fileKeyData)
    }

    func testSensitiveZero() throws {
        var s = SensitiveData(Data([1,2,3,4]))
        s.zero()
        XCTAssertEqual(s.data, Data([0,0,0,0]))
    }

    func testKeychainNotFoundSim() throws {
        XCTAssertThrowsError(try KeychainStore.loadPrivate(label: "this-label-should-not-exist", prompt: "test"))
    }
}

