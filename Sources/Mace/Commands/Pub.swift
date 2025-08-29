import Foundation
import ArgumentParser
import MaceCore

struct Pub: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Print the bech32 public key for a Keychain identity.")

    @Option(name: .shortAndLong, help: "Keychain label")
    var label: String

    func run() throws {
        let id = try KeychainStore.loadPublic(label: label)
        let bech = (try? RecipientPublicKey(raw: id.publicRaw))?.bech32 ?? ""
        print(bech)
    }
}


