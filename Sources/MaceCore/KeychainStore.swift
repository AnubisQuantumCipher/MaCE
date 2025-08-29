import Foundation
#if os(macOS) || os(iOS)
import Security
#endif

public enum KeychainStore {
    private static let service = "org.mace.secure.keys"

    public static func storePrivate(label: String, privateRaw: Data,
                                    when: String = "kSecAttrAccessibleWhenUnlockedThisDeviceOnly",
                                    requireBiometry: Bool = true) throws {
        #if os(macOS) || os(iOS)
        let whenAttr: CFString = when == "kSecAttrAccessibleWhenUnlockedThisDeviceOnly" ? 
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly : kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        guard privateRaw.count == 32 else { throw MaceError.badKey("private key must be 32 bytes") }
        var q: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: label,
            kSecAttrAccessible: whenAttr,
            kSecValueData: privateRaw
        ]
        if requireBiometry {
            var e: Unmanaged<CFError>?
            let flags: SecAccessControlCreateFlags = [.biometryCurrentSet, .userPresence]
            guard let ac = SecAccessControlCreateWithFlags(nil, whenAttr, flags, &e) else {
                throw MaceError.misuse("AccessControl failed")
            }
            q[kSecAttrAccessControl] = ac
        }
        SecItemDelete(q as CFDictionary)
        let s = SecItemAdd(q as CFDictionary, nil)
        guard s == errSecSuccess else { throw MaceError.misuse("Keychain add failed: \(s)") }
        #else
        throw MaceError.misuse("Keychain not available on this platform")
        #endif
    }

    public static func loadPrivate(label: String, prompt: String = "Unlock Mace key") throws -> Data {
        #if os(macOS) || os(iOS)
        let q: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: label,
            kSecReturnData: true,
            kSecUseOperationPrompt: prompt
        ]
        var out: CFTypeRef?
        let s = SecItemCopyMatching(q as CFDictionary, &out)
        guard s == errSecSuccess, let d = out as? Data else { throw MaceError.notFound }
        return d
        #else
        throw MaceError.misuse("Keychain not available on this platform")
        #endif
    }

    public static func storePublic(identity: Identity) throws {
        #if os(macOS) || os(iOS)
        let data = try JSONEncoder().encode(identity)
        let q: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: "pub:\(identity.label)",
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecValueData: data
        ]
        SecItemDelete(q as CFDictionary)
        let s = SecItemAdd(q as CFDictionary, nil)
        guard s == errSecSuccess else { throw MaceError.misuse("Keychain add pub failed: \(s)") }
        #else
        throw MaceError.misuse("Keychain not available on this platform")
        #endif
    }

    public static func loadPublic(label: String) throws -> Identity {
        #if os(macOS) || os(iOS)
        let q: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: "pub:\(label)",
            kSecReturnData: true
        ]
        var out: CFTypeRef?
        let s = SecItemCopyMatching(q as CFDictionary, &out)
        guard s == errSecSuccess, let data = out as? Data else { throw MaceError.notFound }
        return try JSONDecoder().decode(Identity.self, from: data)
        #else
        throw MaceError.misuse("Keychain not available on this platform")
        #endif
    }

    public static func list() -> [String] {
        #if os(macOS) || os(iOS)
        let q: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecReturnAttributes: true,
            kSecMatchLimit: kSecMatchLimitAll
        ]
        var out: CFTypeRef?
        let s = SecItemCopyMatching(q as CFDictionary, &out)
        guard s == errSecSuccess, let arr = out as? [[CFString: Any]] else { return [] }
        // hide pub:* rows from output
        return arr.compactMap { ($0[kSecAttrAccount] as? String).flatMap { $0.hasPrefix("pub:") ? nil : $0 } }
        #else
        return []
        #endif
    }
}


