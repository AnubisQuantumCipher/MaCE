import Foundation
import MaceCore

// Generate a key pair
let keyPair = MaceHPKE.generateKeyPair()

// Get the public key in proper Bech32 format using RecipientPublicKey
let recipientKey = try! RecipientPublicKey(raw: keyPair.publicRaw)
let publicKeyBech32 = recipientKey.bech32

// Save the private key to a file
let privateKeyFile = URL(fileURLWithPath: "mace_private_key.bin")
try keyPair.privateRaw.write(to: privateKeyFile)

// Save the public key to a file for reference
let publicKeyFile = URL(fileURLWithPath: "mace_public_key_bech32.txt")
try publicKeyBech32.write(to: publicKeyFile, atomically: true, encoding: String.Encoding.utf8)

print("Key pair generated successfully!")
print("Public key (Bech32): \(publicKeyBech32)")
print("Private key saved to: mace_private_key.bin")
print("Public key saved to: mace_public_key_bech32.txt")

