import Foundation
import ArgumentParser
import MaceCore

struct Rotate: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Rotate an identity: generate new keys and print the new public.")

    @Option(name: .shortAndLong, help: "Existing Keychain label to rotate (overwritten).")
    var label: String

    @Flag(help: "Require Touch ID / user presence.")
    var biometry: Bool = true

    @Flag(help: "Interactive prompts.")
    var interactive: Bool = false

    func run() throws {
        if interactive {
            Log.warn("Rotating \'\(label)\' will replace the private key. Recipients must receive your new public key.")
            Log.warn("Note: biometryCurrentSet means changing Touch ID/Face ID invalidates old keys.")
            let ans = prompt("Proceed with rotation? (y/N): ")
            guard ans.lowercased().hasPrefix("y") else { throw MaceError.misuse("Cancelled by user.") }
        }
        let pair = MaceHPKE.generateKeyPair()
        try KeychainStore.storePrivate(label: label, privateRaw: pair.privateRaw, requireBiometry: biometry)
        try KeychainStore.storePublic(identity: try Identity(label: label, publicRaw: pair.publicRaw))
        let bech = (try? RecipientPublicKey(raw: pair.publicRaw))?.bech32 ?? ""
        print("# NEW public key for \(label):")
        print(bech)
        Log.ok("Rotated identity \'\(label)\'. Share your new public key with recipients.")
    }
}


