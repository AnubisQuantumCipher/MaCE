import Foundation
#if canImport(CryptoKit)
import CryptoKit
#else
import Crypto
#endif

public enum KDF {
    // HKDF with context salt (non-empty where we need binding)
    public static func hkdf(_ ikm: SymmetricKey, info: String, out: Int, salt: Data = Data()) -> SymmetricKey {
        HKDF<SHA256>.deriveKey(inputKeyMaterial: ikm, salt: salt, info: Data(info.utf8), outputByteCount: out)
    }
}


