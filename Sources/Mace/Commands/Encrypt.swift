import Foundation
import ArgumentParser
#if canImport(CryptoKit)
import CryptoKit
#else
import Crypto
#endif
import MaceCore

struct Encrypt: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Encrypt a file to one or more recipients.",
        discussion: """
        Recipients: --to-id (Keychain labels) and/or --recipient (bech32). Use --recipients-file or '-' for stdin.
        Per-file context (-> context <b64>) is included in header and used as HKDF salt. Header is HMAC'd.
        """
    )

    @Argument(help: "Input file path")
    var input: String

    @Option(name: .shortAndLong, parsing: .upToNextOption, help: "Recipient bech32 strings.")
    var recipient: [String] = []

    @Option(name: .customLong("to-id"), parsing: .upToNextOption, help: "Recipient Keychain labels.")
    var toIDs: [String] = []

    @Option(name: .shortAndLong, help: "Output file (default: input + .mace)")
    var output: String?

    @Option(name: .customLong("recipients-file"), parsing: .upToNextOption,
            help: "File(s) with one recipient per line; '-' for stdin.")
    var recipientsFile: [String] = []

    @Option(name: .customLong("chunk-size"), help: "Bytes per chunk (default 65536, min 4096, max 4194304).")
    var chunkSize: Int = 65536

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

        // chunk size tuning
        if chunkSize < 4096 || chunkSize > 4*1024*1024 {
            if interactive {
                Log.warn("Invalid --chunk-size \(chunkSize). Using 65536.")
                chunkSize = 65536
            } else {
                throw ValidationError("--chunk-size must be 4096..4194304")
            }
        }

        // Collect recipients
        var bechRecipients = recipient
        for path in recipientsFile {
            if path == "-" {
                let stdin = FileHandle.standardInput
                while let data = try? stdin.read(upToCount: 4096),
                      let text = String(data: data, encoding: .utf8), !text.isEmpty {
                    for line in text.split(separator: "\n").map(String.init) {
                        let t = line.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !t.isEmpty && !t.hasPrefix("#") { bechRecipients.append(t) }
                    }
                }
            } else {
                let content = try String(contentsOfFile: path, encoding: .utf8)
                for line in content.split(separator: "\n").map(String.init) {
                    let t = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !t.isEmpty && !t.hasPrefix("#") { bechRecipients.append(t) }
                }
            }
        }

        if bechRecipients.isEmpty && toIDs.isEmpty {
            if interactive {
                Log.warn("No recipients provided; let's add some.")
                while true {
                    let v = prompt("Enter a bech32 recipient (blank to stop): ")
                    if v.isEmpty { break }
                    bechRecipients.append(v)
                }
            }
        }

        // Parse/lookup recipients; interactive recovery if all fail
        var hdr = Header(chunkSize: chunkSize)  // CHANGED: Pass chunk size to header
        var anyAdded = false
        for id in toIDs {
            do {
                let _ = try KeychainStore.loadPublic(label: id).publicRaw
                // Placeholder for HPKE stanza - will be filled after fileKey is generated
                hdr.hpke.append(.init(id: Data(id.utf8).base64EncodedString(), enc: Data(), box: Data()))
                anyAdded = true
            } catch { Log.warn("Skipping recipient id '\(id)': \(error)") }
        }
        for r in bechRecipients {
            do { 
                _ = try RecipientPublicKey.parse(r)
                // Store the actual bech32 key in base64 encoding for later retrieval
                hdr.hpke.append(.init(id: Data(r.utf8).base64EncodedString(), enc: Data(), box: Data()))
                anyAdded = true
            }
            catch { Log.warn("Skipping recipient key '\(r)': \(error)") }
        }

        while !anyAdded && interactive {
            Log.warn("No valid recipients yet.")
            let v = prompt("Add bech32 recipient (or blank to skip): ")
            if v.isEmpty { break }
            if (try? RecipientPublicKey.parse(v)) != nil {
                hdr.hpke.append(.init(id: Data(v.utf8).base64EncodedString(), enc: Data(), box: Data()))
                anyAdded = true
            } else {
                Log.warn("That didn't parse. Try again.")
            }
        }

        guard !hdr.hpke.isEmpty else { throw MaceError.misuse("No valid recipients. Aborting.") }

        // Output handling
        let outPath = output ?? (input + ".mace")
        let outDir = URL(fileURLWithPath: outPath).deletingLastPathComponent().path
        if !FileManager.default.fileExists(atPath: outDir) {
            try FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true, attributes: nil)
        }
        if FileManager.default.fileExists(atPath: outPath) && !force {
            if interactive {
                let ans = UserInput.prompt("Output exists. Overwrite? (y/N): ")
                guard ans.lowercased().starts(with: "y") else { throw MaceError.io("Refused to overwrite \(outPath)") }
            } else {
                throw MaceError.io("Output exists. Use --force to overwrite.")
            }
        }

        let fileKey = SymmetricKey(size: .bits256)
        let fileKeySD = SensitiveData(fileKey.withUnsafeBytes { Data($0) })
        defer { fileKeySD.zero() }

        // Fill in HPKE stanzas with actual encrypted file keys
        for i in 0..<hdr.hpke.count {
            let stanza = hdr.hpke[i]
            let decodedId = String(data: Data(base64Encoded: stanza.id) ?? Data(), encoding: .utf8) ?? ""
            
            // Check if this is a bech32 recipient by trying to parse it
            if decodedId.hasPrefix("mace1") {
                // Bech32 recipient
                let pub = try RecipientPublicKey.parse(decodedId)
                let (enc, ct) = try MaceHPKE.seal(fileKey: fileKeySD.data, recipientPublicRaw: pub, aad: Data())
                hdr.hpke[i] = Header.HPKEStanza(id: stanza.id, enc: enc, box: ct)
            } else {
                // Keychain label recipient
                let label = decodedId
                let pub = try KeychainStore.loadPublic(label: label).publicRaw
                let (enc, ct) = try MaceHPKE.seal(fileKey: fileKeySD.data, recipientPublicRaw: pub, aad: Data())
                hdr.hpke[i] = Header.HPKEStanza(id: stanza.id, enc: enc, box: ct)
            }
        }

        let headerWithoutMac = hdr.serialize(with: nil)
        let macKey = KDF.hkdf(fileKey, info: "mace v1 mac", out: 32, salt: hdr.context)
        let mac = HMAC<SHA256>.authenticationCode(for: headerWithoutMac, using: macKey)
        let headerWithMac = hdr.serialize(with: Data(mac))

        _ = FileManager.default.createFile(atPath: outPath, contents: nil)
        guard let out = try? FileHandle(forWritingTo: URL(fileURLWithPath: outPath))
        else { throw MaceError.io("Cannot open output file") }
        out.write(headerWithMac)

        let envNoProg = ProcessInfo.processInfo.environment["MACE_NO_PROGRESS"] != nil
        let attrs = try FileManager.default.attributesOfItem(atPath: input)
        let size = UInt64((attrs[.size] as? NSNumber)?.uint64Value ?? 0)
        var prog: Progressor? = (showProgress && !envNoProg) ? Progressor(total: size, enabled: true) : nil

        let enc = StreamEncryptor(fileKey: fileKey, context: hdr.context, headerMac: Data(mac), chunkSize: chunkSize)
        try enc.encrypt(input: URL(fileURLWithPath: input), out: out, progress: &prog)
        try out.close()
        Log.ok("Encrypted -> \(outPath)")
    }
}


