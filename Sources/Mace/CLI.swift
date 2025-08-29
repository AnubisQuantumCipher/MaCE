import Foundation
import ArgumentParser
import MaceCore

struct GlobalOptions: ParsableArguments {
    @Flag(name: .customLong("no-color"), help: "Disable colored output.") var noColor = false
    @Flag(name: .customLong("quiet"), help: "Silence non-error output.") var quiet = false
    @Flag(name: .customLong("verbose"), help: "Developer diagnostics.") var verbose = false
}

@main
struct Mace: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "MaCE: Modular AEAD + Composite Encapsulation. macOS-native encryption.",
        discussion: """
        - Private keys in Keychain; Touch ID / user presence
        - Per-file context (salt) hardens HKDF; header is HMAC'd
        - True streaming I/O; progress bar; chunk-size tuning
        - Rotate command to regenerate device-bound keys
        - Future-proofed with PQC 'lane' for quantum-secure algorithms
        """,
        version: MaceVersion.cli,
        subcommands: [Keygen.self, Rotate.self, ListIDs.self, Pub.self, Encrypt.self, Decrypt.self]
    )

    @OptionGroup var globals: GlobalOptions

    mutating func run() throws {
        Log.quiet = globals.quiet
        Log.useColor = !globals.noColor
        Log.verbose = globals.verbose
        throw CleanExit.helpRequest(self)
    }
}


