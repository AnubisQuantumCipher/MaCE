import Foundation

public struct RecipientPublicKey: Sendable, Codable, Equatable {
    public let raw: Data
    public init(raw: Data) throws { guard raw.count == 32 else { throw MaceError.badKey("X25519 pub must be 32 bytes") }; self.raw = raw }
    public var bech32: String { (try? Bech32.encode(hrp: "mace", data: raw)) ?? "" }
    public static func parse(_ s: String) throws -> Data {
        guard !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { 
            throw MaceError.badKey("Empty recipient key") 
        }
        let (hrp, data) = try Bech32.decode(s)
        guard hrp == "mace", data.count == 32 else { throw MaceError.badKey("Not a mace recipient or bad length") }
        return data
    }
}

public struct Identity: Codable, Sendable, Equatable {
    public let label: String
    public let publicRaw: Data
    public init(label: String, publicRaw: Data) throws {
        guard publicRaw.count == 32 else { throw MaceError.badKey("X25519 pub must be 32 bytes") }
        self.label = label; self.publicRaw = publicRaw
    }
}


