import Foundation
import ArgumentParser
import MaceCore

struct ListIDs: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "List stored Keychain identities.")
    func run() throws { for l in KeychainStore.list() { print(l) } }
}


