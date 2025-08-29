import Foundation
import ArgumentParser
#if canImport(CryptoKit)
import CryptoKit
#else
import Crypto
#endif
import MaceCore

struct Decrypt: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Decrypt a .mace file.",
        discussion: "Tries provided Keychain labels; verifies header MAC; streams decrypt with progress."
    )

    @Argument(help: "Input .mace file")
    var input: String

    @Option(name: .shortAndLong, help: "Output file (default: strip .mace)")
    var output: String?

    @Option(name: .customLong("id"), parsing: .upToNextOption, help: "Keychain labels to try.")
    var ids: [String] = []

    @Option(name: .customLong("private-key"), help: "Private key file for decryption (Linux/testing).")
    var privateKeyFile: String?

    @Option(name: .customLong("prompt"), help: "Keychain access prompt.")
    var prompt: String = "Unlock Mace key"

    @Option(name: .customLong("chunk-size"), help: "Override chunk size (bytes). Normally not needed; header carries it.")
    var overrideChunkSize: Int?

    @Flag(name: .customLong("progress"), help: "Show a progress bar.")
    var showProgress: Bool = false

    @Flag(help: "Interactive prompts.")
    var interactive: Bool = false

    @Flag(name: .customLong("force"), help: "Overwrite output if it exists.")
    var force: Bool = false

    mutating func run() throws {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: input, isDirectory: &isDir), !isDir.boolValue
        else { throw MaceError.io("Input not found or is a directory") }
        guard FileManager.default.isReadableFile(atPath: input) else { throw MaceError.io("Input not readable") }

        if ids.isEmpty && privateKeyFile == nil && interactive {
            Log.warn("No Keychain IDs or private key file supplied.")
            while true {
                let v = UserInput.prompt("Enter a Keychain label (blank to stop): ")
                if v.isEmpty { break }; ids.append(v)
            }
        }
        guard !ids.isEmpty || privateKeyFile != nil else { 
            throw ValidationError("No Keychain IDs or private key file. Use --id, --private-key, or --interactive.") 
        }

        let outPath = output ?? (input.hasSuffix(".mace") ? String(input.dropLast(5)) : input + ".out")
        let outDir = URL(fileURLWithPath: outPath).deletingLastPathComponent().path
        if !FileManager.default.fileExists(atPath: outDir) {
            try FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true, attributes: nil)
        }
        if FileManager.default.fileExists(atPath: outPath) && !force {
            if interactive {
                let ans = UserInput.prompt("Output exists. Overwrite? (y/N): ")
                guard ans.lowercased().starts(with: "y") else { throw MaceError.io("Refused to overwrite \(outPath)") }
            } else { throw MaceError.io("Output exists. Use --force to overwrite.") }
        }

        let url = URL(fileURLWithPath: input)
        let (headerWithoutMac, mac, payloadOffset, payloadLen) = try Header.read(from: url)
        let header = try Header.parseHeaderBytes(headerWithoutMac)

        // Use header's chunk size, with optional override
        let effectiveChunk = overrideChunkSize ?? header.chunkSize
        if let override = overrideChunkSize, override != header.chunkSize {
            Log.warn("Using overridden chunk size \(override) (header says \(header.chunkSize)). This is rarely necessary.")
        }

        // Version check (forward compatibility)
        guard header.versionMajor == MaceVersion.headerMajor else {
            throw MaceError.parse("Unsupported header version: \(header.versionMajor).\(header.versionMinor). Expected \(MaceVersion.headerMajor).X")
        }

        var privs: [(label: String, raw: Data)] = []
        
        // Load private keys from Keychain
        for l in ids {
            do { let pk = try KeychainStore.loadPrivate(label: l, prompt: prompt); privs.append((l, pk)) }
            catch { Log.debug("Keychain load failed for '\(l)': \(error)") }
        }
        
        // Load private key from file if provided
        if let pkFile = privateKeyFile {
            do {
                let privateKeyData = try Data(contentsOf: URL(fileURLWithPath: pkFile))
                guard privateKeyData.count == 32 else { 
                    throw MaceError.badKey("Private key file must contain exactly 32 bytes") 
                }
                privs.append(("file:\(pkFile)", privateKeyData))
                Log.debug("Loaded private key from file: \(pkFile)")
            } catch {
                Log.warn("Failed to load private key from file '\(pkFile)': \(error)")
            }
        }
        
        guard !privs.isEmpty else { throw MaceError.io("No usable private keys.") }

        var fileKeySD: SensitiveData?
        outer: for st in header.hpke {
            for (label, priv) in privs {
                do { let fk = try MaceHPKE.open(encapsulated: st.enc, ciphertext: st.box, myPrivateRaw: priv, aad: Data())
                     fileKeySD = SensitiveData(fk); break outer }
                catch { Log.debug("Key \'\(label)\' did not match this stanza") }
            }
        }
        guard let fkSD = fileKeySD else { throw MaceError.parse("Decryption failed.") }
        defer { fkSD.zero() }

        let fileKey = SymmetricKey(data: fkSD.data)
        let macKey = KDF.hkdf(fileKey, info: "mace v1 mac", out: 32, salt: header.context)
        guard HMAC<SHA256>.isValidAuthenticationCode(mac, authenticating: headerWithoutMac, using: macKey)
        else { throw MaceError.mac }

        _ = FileManager.default.createFile(atPath: outPath, contents: nil)
        let outFH = try FileHandle(forWritingTo: URL(fileURLWithPath: outPath))
        let inFH = try FileHandle(forReadingFrom: url)
        try inFH.seek(toOffset: payloadOffset)

        let envNoProg = ProcessInfo.processInfo.environment["MACE_NO_PROGRESS"] != nil
        var prog: Progressor? = (showProgress && !envNoProg) ? Progressor(total: payloadLen, enabled: true) : nil

        let dec = StreamDecryptor(fileKey: fileKey, context: header.context, headerMac: mac, chunkSize: effectiveChunk)
        try dec.decrypt(from: inFH, payloadLength: payloadLen, out: outFH, progress: &prog)

        try outFH.close(); try inFH.close()
        Log.ok("Decrypted -> \(outPath)")
    }
}


