import Foundation

@inline(__always)
private func normalizeBech32(_ s: String) -> String {
    // Trim whitespace/newlines, strip surrounding quotes, collapse inner spaces, lowercase
    var t = s.trimmingCharacters(in: .whitespacesAndNewlines)
    if t.hasPrefix("\"") && t.hasSuffix("\"") && t.count >= 2 {
        t.removeFirst(); t.removeLast()
    }
    // Remove internal spaces that might sneak in from copy/paste
    t = t.replacingOccurrences(of: " ", with: "")
    return t.lowercased()
}

private func hasMixedCase(_ s: String) -> Bool {
    let hasLower = s.rangeOfCharacter(from: .lowercaseLetters) != nil
    let hasUpper = s.rangeOfCharacter(from: .uppercaseLetters) != nil
    return hasLower && hasUpper
}

enum Bech32 {
    private static let charset = Array("qpzry9x8gf2tvdw0s3jn54khce6mua7l")
    private static let charmap: [Character: Int] = {
        var m: [Character: Int] = [:]; for (i, c) in charset.enumerated() { m[c] = i }; return m
    }()
    private static func polymod(_ values: [UInt8]) -> UInt32 {
        var chk: UInt32 = 1; let GEN: [UInt32] = [0x3b6a57b2,0x26508e6d,0x1ea119fa,0x3d4233dd,0x2a1462b3]
        for v in values {
            let b = (chk >> 25) & 0xff
            chk = (chk & 0x1ffffff) << 5 ^ UInt32(v)
            for i in 0..<5 { if ((b >> i) & 1) != 0 { chk ^= GEN[i] } }
        }
        return chk
    }
    private static func hrpExpand(_ hrp: String) -> [UInt8] {
        let h = Array(hrp.utf8); var out: [UInt8] = []
        for b in h { out.append(b >> 5) }; out.append(0); for b in h { out.append(b & 31) }
        return out
    }
    private static func verifyChecksum(hrp: String, data: [UInt8]) -> Bool { polymod(hrpExpand(hrp) + data) == 0x2bc830a3 }
    private static func createChecksum(hrp: String, data: [UInt8]) -> [UInt8] {
        let v = hrpExpand(hrp) + data + [0,0,0,0,0,0]; let mod = polymod(v) ^ 0x2bc830a3
        return (0..<6).map { UInt8((mod >> (5 * (5 - $0))) & 31) }
    }
    private static func convertBits(_ data: [UInt8], from: Int, to: Int, pad: Bool) -> [UInt8]? {
        var acc = 0, bits = 0; let maxv = (1 << to) - 1; var out: [UInt8] = []
        for v in data {
            if v >> from != 0 { return nil }
            acc = (acc << from) | Int(v); bits += from
            while bits >= to { bits -= to; out.append(UInt8((acc >> bits) & maxv)) }
        }
        if pad { if bits > 0 { out.append(UInt8((acc << (to - bits)) & maxv)) } }
        else if bits >= from || ((acc << (to - bits)) & maxv) != 0 { return nil }
        return out
    }
    static func encode(hrp: String, data: Data) throws -> String {
        guard let five = convertBits(Array(data), from: 8, to: 5, pad: true) else { throw MaceError.misuse("bech32 convert") }
        let checksum = createChecksum(hrp: hrp, data: five); let tail = (five + checksum).map { charset[Int($0)] }
        return hrp + "1" + String(tail)
    }
    static func decode(_ s: String) throws -> (hrp: String, data: Data) {
        let sOriginal = s
        let s = normalizeBech32(sOriginal)
        
        // Quick fix: reject empty strings immediately
        guard !s.isEmpty else { throw MaceError.parse("empty string") }
        
        guard !hasMixedCase(sOriginal) else { throw MaceError.parse("mixed case") }
        
        // Bech32 requires the *last* '1' to be the separator
        guard let pos = s.lastIndex(of: "1") else { throw MaceError.parse("no sep") }
        let hrp = String(s[..<pos])
        let rest = s[s.index(after: pos)...]
        
        guard !hrp.isEmpty else { throw MaceError.parse("invalid hrp") }
        guard rest.count >= 6 else { throw MaceError.parse("invalid data") }
        
        // Optional strict HRP check for MaCE keys
        if hrp != "mace" {
            throw MaceError.parse("hrp mismatch: expected mace, got \(hrp)")
        }
        
        var values: [UInt8] = []
        for ch in rest { 
            guard let v = charmap[ch] else { throw MaceError.parse("invalid char") }
            values.append(UInt8(v)) 
        }
        guard values.count >= 6, verifyChecksum(hrp: hrp, data: values) else { throw MaceError.parse("checksum") }
        let payload = Array(values[..<(values.count - 6)])
        guard let eight = convertBits(payload, from: 5, to: 8, pad: false) else { throw MaceError.parse("convert bits failed") }
        return (hrp, Data(eight))
    }
}

