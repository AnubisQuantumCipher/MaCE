import Foundation
#if canImport(CryptoKit)
import CryptoKit
#else
import Crypto
#endif

public struct Progressor {
    public let total: UInt64
    private var lastPrintedAt: UInt64 = 0
    private let step: UInt64
    private let enabled: Bool
    private let write: (String)->Void

    public init(total: UInt64, enabled: Bool, steps: Int = 100, writer: ((String)->Void)? = nil) {
        self.total = total
        self.enabled = enabled
        self.step = total > 0 ? max(1, total / UInt64(steps)) : 1
        self.write = writer ?? { message in
            // Simple stderr write without concurrency issues
            FileHandle.standardError.write(Data(message.utf8))
        }
    }
    public mutating func start() {
        guard enabled else { return }
        render(done: 0, final: false)
    }
    public mutating func update(done: UInt64) {
        guard enabled else { return }
        if done >= lastPrintedAt + step || done == total || lastPrintedAt == 0 {
            render(done: done, final: done == total)
            lastPrintedAt = done
        }
    }
    private func render(done: UInt64, final: Bool) {
        let pct = total == 0 ? 100.0 : Double(done) / Double(total) * 100.0
        let barLen = 30
        let filled = max(0, Int((Double(barLen) * pct / 100.0).rounded(.down)))
        let bar = String(repeating: "█", count: filled) + String(repeating: "─", count: max(0, barLen - filled))
        let line = String(format: "\r[%@] %6.2f%%", bar, pct)
        write(line + (final ? "\n" : ""))
    }
}

public struct StreamEncryptor {
    public let fileKey: SymmetricKey
    public let context: Data // HKDF salt
    public let headerMac: Data
    public let chunkSize: Int

    public init(fileKey: SymmetricKey, context: Data, headerMac: Data, chunkSize: Int) {
        self.fileKey = fileKey; self.context = context; self.headerMac = headerMac; self.chunkSize = chunkSize
    }

    public func encrypt(input: URL, out: FileHandle, progress: inout Progressor?) throws {
        let payloadKey = KDF.hkdf(fileKey, info: "mace v1 payload", out: 32, salt: context)
        var counter: UInt64 = 0
        let attrs = try FileManager.default.attributesOfItem(atPath: input.path)
        let fileSize = UInt64((attrs[.size] as? NSNumber)?.uint64Value ?? 0)
        var done: UInt64 = 0
        progress?.start()

        let fh = try FileHandle(forReadingFrom: input)
        defer { try? fh.close() }

        while true {
            let chunk = try fh.read(upToCount: chunkSize) ?? Data()
            let isFinal = chunk.count < chunkSize
            // Nonce: 12 bytes => 3 zero prefix + 8 counter + 1 flag
            var nonce = Data([0x00, 0x00, 0x00])
            var be = counter.bigEndian
            withUnsafeBytes(of: &be) { nonce.append(contentsOf: $0) }
            nonce.append(isFinal ? 0x01 : 0x00)
            guard let n = try? AES.GCM.Nonce(data: nonce) else { throw MaceError.crypto("nonce len") }
            let sealed = try AES.GCM.seal(chunk, using: payloadKey, nonce: n, authenticating: headerMac)
            guard let comb = sealed.combined else { throw MaceError.crypto("combined nil") }
            out.write(comb)
            done += UInt64(chunk.count)
            progress?.update(done: min(done, fileSize))
            if isFinal { break }
            counter &+= 1; if counter == .max { throw MaceError.overflow }
        }
    }
}

public struct StreamDecryptor {
    public let fileKey: SymmetricKey
    public let context: Data
    public let headerMac: Data
    public let chunkSize: Int

    public init(fileKey: SymmetricKey, context: Data, headerMac: Data, chunkSize: Int) {
        self.fileKey = fileKey; self.context = context; self.headerMac = headerMac; self.chunkSize = chunkSize
    }

    public func decrypt(from fh: FileHandle, payloadLength: UInt64, out: FileHandle, progress: inout Progressor?) throws {
        let payloadKey = KDF.hkdf(fileKey, info: "mace v1 payload", out: 32, salt: context)
        let nonceSize = 12, tag = 16
        let full = nonceSize + chunkSize + tag
        var remaining = payloadLength
        var processed: UInt64 = 0
        progress?.start()

        func readExact(_ n: Int) throws -> Data {
            var data = Data(); data.reserveCapacity(n)
            while data.count < n {
                let got = try fh.read(upToCount: n - data.count) ?? Data()
                if got.isEmpty { throw MaceError.parse("unexpected EOF") }
                data.append(got)
            }
            return data
        }

        while remaining >= UInt64(full) {
            let nonce = try readExact(nonceSize); if nonce.last! != 0x00 { throw MaceError.parse("non-final flagged final") }
            let ct = try readExact(chunkSize + tag)
            let n = try AES.GCM.Nonce(data: nonce)
            let box = try AES.GCM.SealedBox(nonce: n, ciphertext: ct.dropLast(tag), tag: ct.suffix(tag))
            let pt = try AES.GCM.open(box, using: payloadKey, authenticating: headerMac)
            out.write(pt)
            remaining -= UInt64(full); processed += UInt64(pt.count); progress?.update(done: processed)
        }

        if remaining > 0 {
            guard remaining >= UInt64(nonceSize + tag) else { throw MaceError.parse("truncated final") }
            let nonce = try readExact(nonceSize); if nonce.last! != 0x01 { throw MaceError.parse("final flag missing") }
            let ct = try readExact(Int(remaining) - nonceSize)
            let n = try AES.GCM.Nonce(data: nonce)
            let box = try AES.GCM.SealedBox(nonce: n, ciphertext: ct.dropLast(tag), tag: ct.suffix(tag))
            let pt = try AES.GCM.open(box, using: payloadKey, authenticating: headerMac)
            out.write(pt); processed += UInt64(pt.count); progress?.update(done: processed)
        }
    }
}


