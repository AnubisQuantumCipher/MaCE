import Foundation
#if os(Darwin)
import Darwin
#else
import Glibc
#endif
#if canImport(CryptoKit)
import CryptoKit
#else
import Crypto
#endif

enum MaceVersion {
    // bump when format or feature set changes in a breaking way
    static let cli = "3.2.0"
    // header format major.minor (major mismatch => hard error)
    static let headerMajor = 1
    static let headerMinor = 0
}

public struct Header {
    public struct HPKEStanza: Codable {
        public let id: String // base64 label or "-" for raw recipient
        public let enc: Data  // ephemeral pub (32 bytes) base64
        public let box: Data  // AES-GCM-wrapped file key (combined) base64
        
        public init(id: String, enc: Data, box: Data) {
            self.id = id
            self.enc = enc
            self.box = box
        }
    }

    public var hpke: [HPKEStanza] = []
    public var context: Data // 16-byte random salt for HKDF
    public var chunkSize: Int  // NEW: Store chunk size in header

    public static let versionLine = "mace/v1"
    // Format: -> params aesgcm256 x25519 <chunkSize> stream-v1

    public init(context: Data = Data((0..<16).map { _ in UInt8.random(in: 0...255) }),
                chunkSize: Int = 65536) {
        self.context = context
        self.chunkSize = chunkSize
    }
    
    public init(hpke: [HPKEStanza], context: Data, chunkSize: Int = 65536) {
        self.hpke = hpke
        self.context = context
        self.chunkSize = chunkSize
    }

    public func serialize(with mac: Data?) -> Data {
        var s = "\(Self.versionLine)\n"
        s += "-> params aesgcm256 x25519 \(chunkSize) stream-v1\n"  // CHANGED: Dynamic chunk size
        s += "-> context \(context.base64EncodedString())\n"
        for st in hpke {
            s += "-> x25519 \(st.id) \(st.enc.base64EncodedString()) \(st.box.base64EncodedString())\n"
        }
        if let mac = mac {
            s += "--- \(mac.base64EncodedString())\n"
        }
        return Data(s.utf8)
    }

    // Incremental reader: returns headerWithoutMac, mac, payloadOffset, payloadLength
    public static func read(from url: URL) throws -> (Data, Data, UInt64, UInt64) {
        let fh = try FileHandle(forReadingFrom: url)
        defer { try? fh.close() }

        var header = Data()
        var macLineB64: String?
        while true {
            guard let line = try fh.readLine() else { throw MaceError.parse("unexpected EOF while reading header") }
            if line.hasPrefix("--- ") {
                macLineB64 = String(line.dropFirst(4)).trimmingCharacters(in: .whitespacesAndNewlines)
                break
            }
            header.append(contentsOf: line.utf8); header.append(0x0A)
        }
        guard let macB64 = macLineB64, let mac = Data(base64Encoded: macB64) else { throw MaceError.parse("bad MAC line") }

        // current offset (end of MAC line, which we consumed with readLine)
        let payloadOffset = fh.currentOffset

        let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
        let total = UInt64((attrs[.size] as? NSNumber)?.uint64Value ?? 0)
        let payloadLen = total - payloadOffset

        // Quick validation
        let lines = String(decoding: header, as: UTF8.self).split(separator: "\n").map(String.init)
        guard lines.first == versionLine else { throw MaceError.parse("bad version") }
        guard lines.dropFirst().first?.hasPrefix("-> params ") == true else { throw MaceError.parse("bad params") }
        // Check for context line
        guard lines.contains(where: { $0.hasPrefix("-> context ") }) else { throw MaceError.parse("missing context line") }

        return (header, mac, payloadOffset, payloadLen)
    }

    public static func parse(data: Data) throws -> (Header, Data?, UInt64) {
        let string = String(decoding: data, as: UTF8.self)
        let lines = string.components(separatedBy: "\n")
        
        var headerLines: [String] = []
        var macLine: String? = nil
        
        for line in lines {
            if line.hasPrefix("--- ") {
                macLine = String(line.dropFirst(4))
                break
            }
            headerLines.append(line)
        }
        
        let headerData = Data(headerLines.joined(separator: "\n").utf8)
        let header = try parseHeaderBytes(headerData)
        
        let macData = macLine.flatMap { Data(base64Encoded: $0.trimmingCharacters(in: .whitespacesAndNewlines)) }
        
        let payloadOffset = UInt64(headerData.count + (macLine?.utf8.count ?? 0) + 1)
        
        return (header, macData, payloadOffset)
    }
    
    public static func parseHeaderBytes(_ header: Data) throws -> Header {
        let lines = String(decoding: header, as: UTF8.self).split(separator: "\n").map(String.init)
        guard lines.count >= 3 else { throw MaceError.parse("truncated header") }

        let versionString = lines[0]
        let paramsString = lines[1]
        let contextString = lines[2]

        // Version check
        guard versionString.hasPrefix("mace/v") else { throw MaceError.parse("bad version line") }
        let versionPart = String(versionString.dropFirst("mace/v".count))
        
        let major: Int
        let minor: Int
        
        if versionPart.contains(".") {
            // Format: mace/v1.0
            let versionParts = versionPart.split(separator: ".").map(String.init)
            guard versionParts.count == 2, let maj = Int(versionParts[0]), let min = Int(versionParts[1]) else {
                throw MaceError.parse("malformed version string")
            }
            major = maj
            minor = min
        } else {
            // Format: mace/v1 (assume minor = 0)
            guard let maj = Int(versionPart) else {
                throw MaceError.parse("malformed version string")
            }
            major = maj
            minor = 0
        }
        
        guard major == MaceVersion.headerMajor else {
            throw MaceError.parse("Unsupported header version: \(major).\(minor). Expected \(MaceVersion.headerMajor).X")
        }

        // Parse params line to extract chunk size
        guard paramsString.hasPrefix("-> params ") else { throw MaceError.parse("bad params line") }
        let parts = paramsString.split(separator: " ").map(String.init)
        guard parts.count >= 6 else { throw MaceError.parse("params parts") }
        guard parts[2] == "aesgcm256", parts[3] == "x25519" else { throw MaceError.parse("suite mismatch") }
        guard let parsedChunk = Int(parts[4]), parsedChunk >= 4096, parsedChunk <= 8_388_608, parsedChunk % 4096 == 0
        else { throw MaceError.parse("invalid chunk size") }

        guard contextString.hasPrefix("-> context ") else { throw MaceError.parse("missing context line") }
        let contextB64 = String(contextString.dropFirst("-> context ".count))
        guard let contextData = Data(base64Encoded: contextB64) else { throw MaceError.parse("malformed context") }
        guard contextData.count == 16 else { throw MaceError.parse("context must be 16 bytes") }

        var out = Header(hpke: [], context: contextData, chunkSize: parsedChunk)
        for line in lines.dropFirst(3) { // Skip version, params, and context lines
            guard line.hasPrefix("-> x25519 ") else { throw MaceError.parse("unknown stanza") }
            let parts = line.dropFirst("-> x25519 ".count).split(separator: " ")
            guard parts.count == 3,
                  let enc = Data(base64Encoded: String(parts[1])),
                  let box = Data(base64Encoded: String(parts[2])) else { throw MaceError.parse("x25519 stanza") }
            out.hpke.append(Header.HPKEStanza(id: String(parts[0]), enc: enc, box: box))
        }
        return out
    }

    public var versionMajor: Int {
        let versionString = String(decoding: serialize(with: nil), as: UTF8.self).split(separator: "\n")[0]
        let versionPart = String(versionString.dropFirst("mace/v".count))
        
        if versionPart.contains(".") {
            let versionParts = versionPart.split(separator: ".").map(String.init)
            return Int(versionParts[0]) ?? 1
        } else {
            return Int(versionPart) ?? 1
        }
    }
    
    public var versionMinor: Int {
        let versionString = String(decoding: serialize(with: nil), as: UTF8.self).split(separator: "\n")[0]
        let versionPart = String(versionString.dropFirst("mace/v".count))
        
        if versionPart.contains(".") {
            let versionParts = versionPart.split(separator: ".").map(String.init)
            return Int(versionParts[1]) ?? 0
        } else {
            return 0
        }
    }
}

extension FileHandle {
    fileprivate func readLine() throws -> String? {
        var data = Data()
        while true {
            let one = try self.read(upToCount: 1) ?? Data()
            if one.isEmpty { return data.isEmpty ? nil : String(decoding: data, as: UTF8.self) }
            if one[0] == 0x0A { return String(decoding: data, as: UTF8.self) }
            data.append(one)
        }
    }
    fileprivate var currentOffset: UInt64 {
        let off = lseek(self.fileDescriptor, 0, SEEK_CUR)
        return off < 0 ? 0 : UInt64(off)
    }
}


