import XCTest
@testable import MaceCore
#if canImport(CryptoKit)
import CryptoKit
#else
import Crypto
#endif

final class ChunkSizeTests: XCTestCase {
    
    func testStreamRoundtripNonDefaultChunk() throws {
        let n = 700_000
        let inURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("nondef_in.bin")
        let encURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("nondef_enc.bin")
        let outURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("nondef_out.bin")
        
        try Data((0..<n).map { _ in UInt8.random(in: 0...255) }).write(to: inURL)

        let ctx = Data((0..<16).map { _ in UInt8.random(in: 0...255) })
        var h = Header(context: ctx, chunkSize: 131072) // 128KiB
        h.hpke.append(.init(id: "x", enc: Data(repeating: 1, count: 32), box: Data(repeating: 2, count: 64)))
        let fk = SymmetricKey(size: .bits256)
        let macKey = KDF.hkdf(fk, info: "mace v1 mac", out: 32, salt: ctx)
        let hdrNoMac = h.serialize(with: nil)
        let mac = HMAC<SHA256>.authenticationCode(for: hdrNoMac, using: macKey)
        let hdrWithMac = h.serialize(with: Data(mac))

        FileManager.default.createFile(atPath: encURL.path, contents: nil)
        let out = try FileHandle(forWritingTo: encURL)
        out.write(hdrWithMac)
        var prog: Progressor? = nil
        try StreamEncryptor(fileKey: fk, context: ctx, headerMac: Data(mac), chunkSize: 131072)
            .encrypt(input: inURL, out: out, progress: &prog)
        try out.close()

        let (hdr2, mac2, off, len) = try Header.read(from: encURL)
        let parsed = try Header.parseHeaderBytes(hdr2)
        XCTAssertEqual(parsed.chunkSize, 131072)

        FileManager.default.createFile(atPath: outURL.path, contents: nil)
        let outFH = try FileHandle(forWritingTo: outURL)
        let inFH = try FileHandle(forReadingFrom: encURL)
        try inFH.seek(toOffset: off)
        var prog2: Progressor? = nil
        try StreamDecryptor(fileKey: fk, context: ctx, headerMac: mac2, chunkSize: parsed.chunkSize)
            .decrypt(from: inFH, payloadLength: len, out: outFH, progress: &prog2)
        try outFH.close(); try inFH.close()

        XCTAssertEqual(try Data(contentsOf: outURL), try Data(contentsOf: inURL))
        
        // Cleanup
        try? FileManager.default.removeItem(at: inURL)
        try? FileManager.default.removeItem(at: encURL)
        try? FileManager.default.removeItem(at: outURL)
    }
    
    func testHeaderChunkSizeParsing() throws {
        // Test various chunk sizes are correctly stored and parsed
        let testSizes = [4096, 65536, 131072, 262144]
        
        for size in testSizes {
            let ctx = Data((0..<16).map { _ in UInt8.random(in: 0...255) })
            let h = Header(context: ctx, chunkSize: size)
            
            let serialized = h.serialize(with: nil)
            let parsed = try Header.parseHeaderBytes(serialized)
            
            XCTAssertEqual(parsed.chunkSize, size, "Chunk size \(size) not preserved through serialization")
        }
    }
    
    func testInvalidChunkSizeRejected() throws {
        // Test that invalid chunk sizes are rejected during parsing
        let invalidSizes = [1024, 3000, 8_388_609] // Too small, not multiple of 4096, too large
        
        for size in invalidSizes {
            let ctx = Data((0..<16).map { _ in UInt8.random(in: 0...255) })
            
            // Manually create a header with invalid chunk size
            var s = "mace/v1\n"
            s += "-> params aesgcm256 x25519 \(size) stream-v1\n"
            s += "-> context \(ctx.base64EncodedString())\n"
            let headerData = Data(s.utf8)
            
            XCTAssertThrowsError(try Header.parseHeaderBytes(headerData)) { error in
                XCTAssertTrue(error is MaceError, "Should throw MaceError for invalid chunk size \(size)")
            }
        }
    }
}

