import Foundation
import ArgumentParser
#if canImport(CryptoKit)
import CryptoKit
#else
import Crypto
#endif
import MaceCore

struct Keygen: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Create a new identity (private key in Keychain).")

    @Option(name: .shortAndLong, help: "Human label (e.g., alice@example.com).")
    var label: String

    @Flag(help: "Require Touch ID / user presence.")
    var biometry: Bool = false

    @Flag(help: "Interactive prompts.")
    var interactive: Bool = false

    mutating func validate() throws {
        if label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if interactive {
                label = prompt("Enter a label (e.g., alice@example.com): ")
            } else {
                throw ValidationError("Label cannot be empty. Try --interactive.")
            }
        }
    }

    func run() throws {
        let pair = MaceHPKE.generateKeyPair()
        try KeychainStore.storePrivate(label: label, privateRaw: pair.privateRaw, requireBiometry: biometry)
        try KeychainStore.storePublic(identity: try Identity(label: label, publicRaw: pair.publicRaw))
        let bech = (try? RecipientPublicKey(raw: pair.publicRaw))?.bech32 ?? ""
        print("# Public key for \(label):")
        print(bech)
        Log.ok("Saved private key in Keychain (label: \(label))")
    }
}


