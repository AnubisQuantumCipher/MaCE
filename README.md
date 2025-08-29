# MaCE (Modular AEAD + Composite Encapsulation)

MaCE is a cutting-edge, cross-platform encryption tool designed for unparalleled security, privacy, and ease of use. It leverages modern Swift and advanced cryptographic primitives to provide a robust and future-proof solution for protecting your digital assets.

In an era where digital data faces constant threats from increasingly sophisticated attacks, MaCE emerges as a proactive solution, offering a powerful and reliable encryption system. Its design philosophy centers on modularity, authenticated encryption with associated data (AEAD), and composite encapsulation, ensuring both data confidentiality and integrity, while preparing for the post-quantum era.

## Features

*   **Modular AEAD**: Utilizes Authenticated Encryption with Associated Data (AEAD) for both confidentiality and integrity, ensuring highly efficient and secure cryptographic operations.
*   **Composite Encapsulation**: Employs a hybrid post-quantum cryptographic approach combining traditional elliptic-curve cryptography (ECC) like X25519 with quantum-resistant algorithms such as ML-KEM-768 (NIST-recommended). This provides future-proof security against emerging threats, including those posed by quantum computers.
*   **High Performance**: Optimized for macOS with hardware-accelerated AES-GCM for rapid encryption and decryption, leveraging the full potential of Apple silicon.
*   **Robust Key Management**: Supports secure key generation and management, including integration with macOS Keychain for highly secure and convenient storage of private keys.
*   **Streaming Support**: Efficiently handles large files, enabling the processing of data streams without loading the entire file into memory, thus minimizing resource consumption.

## Basic Installation: macOS

This section provides a concise guide to installing MaCE on macOS. For a comprehensive, step-by-step guide with troubleshooting tips, please refer to the [full installation guide](mace_installation_guide.md).

### Prerequisites

Before you begin, ensure your macOS system has at least 2 GB of free disk space and a stable internet connection.

### Step 1: Install Xcode Command Line Tools

If you don't have them already, install Xcode Command-Line Tools:

```bash
xcode-select --install
```

Follow the on-screen prompts to complete the installation.

### Step 2: Install Homebrew

If you don't have Homebrew, the macOS package manager, install it:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Follow the instructions provided by the installer.

### Step 3: Install Swiftly (Swift Toolchain Manager)

Swiftly is essential for managing Swift versions. Install it with:

```bash
curl -L https://swiftlang.github.io/swiftly/swiftly-install.sh | bash
```

After installation, ensure you source the Swiftly environment by adding the following to your shell profile (`~/.zshrc` or `~/.bashrc`):

```bash
export SWIFTLY_HOME_DIR="${HOME}/.local/share/swiftly"
if [[ -f "${SWIFTLY_HOME_DIR}/env.sh" ]]; then
    source "${SWIFTLY_HOME_DIR}/env.sh"
fi
```

Then, reload your shell: `source ~/.zshrc` (or your respective shell profile).

### Step 4: Install Swift Toolchain

Install the required Swift version (6.1.2) and set it as default:

```bash
swiftly install 6.1.2
swiftly use 6.1.2
```

### Step 5: Build MaCE

Navigate to the root directory of the MaCE project (where `Package.swift` is located) and build it in release mode. Then, install the binary:

```bash
swift build --configuration release
mkdir -p "${HOME}/.local/bin"
cp .build/release/mace "${HOME}/.local/bin/"
chmod +x "${HOME}/.local/bin/mace"
```

Ensure `~/.local/bin` is in your system's PATH. You might need to add `export PATH="$HOME/.local/bin:$PATH"` to your shell profile and reload it.

## White Paper

For an in-depth understanding of MaCE's design, cryptographic foundations, and security advantages, please refer to the [MaCE White Paper](mace_white_paper.md).

## Usage

MaCE is designed for intuitive command-line usage. Here are common operations:

### 1. Generate a Key Pair

MaCE uses public/private key pairs for encryption. The private key is securely stored in your macOS Keychain.

```bash
mace keygen --label "my-key-label" # Creates keys, prompts Touch ID if needed
```

To display your public key string (to share with others):

```bash
mace pub --label "my-key-label"
```

### 2. Encrypt a File

Encrypt a file to yourself (using your Keychain identity):

```bash
mace encrypt "$HOME/Desktop/MyDocument.pdf" --to-id "my-key-label" --progress
```

*   **Output**: By default, the encrypted file will be named `MyDocument.pdf.mace` in the same directory.
*   **Overwriting**: If the output file already exists, use `--force` to overwrite:

    ```bash
    mace encrypt "$HOME/Desktop/MyDocument.pdf" --to-id "my-key-label" --force
    ```

*   **Custom Output Name**: Choose a custom name for the encrypted file:

    ```bash
    mace encrypt "$HOME/Desktop/MyDocument.pdf" --to-id "my-key-label" \
      --output "$HOME/Desktop/MyDocument (encrypted).pdf.mace"
    ```

*   **Encrypting to a Public Key String**: To encrypt using a recipient's public key string instead of a Keychain label:

    ```bash
    mace encrypt "$HOME/Desktop/MyDocument.pdf" \
      --recipient "mace1<base64_public_key_string>" \
      --output "$HOME/Desktop/MyDocument.pdf.mace"
    ```

*   **Encrypting Folders**: MaCE encrypts single files. For folders, first compress them (e.g., with `tar` or `zip`), then encrypt the archive:

    ```bash
    # Create an archive of the folder
    tar -czf "$HOME/Desktop/MyFolder.tar.gz" -C "$HOME/Desktop" "My Folder"

    # Encrypt the archive
    mace encrypt "$HOME/Desktop/MyFolder.tar.gz" \
      --to-id "my-key-label" \
      --output "$HOME/Desktop/MyFolder.tar.gz.mace" \
      --progress
    ```

### 3. Decrypt a File

To decrypt a file, you need access to the private key corresponding to one of the public keys used for encryption. If the private key is in your Keychain, MaCE will automatically use it.

```bash
mace decrypt "$HOME/Desktop/MyDocument.pdf.mace" --id "my-key-label" \
  --output "$HOME/Desktop/MyDocument (decrypted).pdf"
```

*   **Decrypting Archives**: If you encrypted a folder as an archive, decrypt it and then unpack:

    ```bash
    mace decrypt "$HOME/Desktop/MyFolder.tar.gz.mace" --id "my-key-label" \
      --output "$HOME/Desktop/MyFolder.tar.gz"

    # Then unpack the archive
    tar -xzf "$HOME/Desktop/MyFolder.tar.gz" -C "$HOME/Desktop"
    ```

### 4. Other Useful Commands

*   **List Saved Identities**:

    ```bash
    mace list-ids
    ```

*   **Encrypt to Multiple Recipients** (mix Keychain labels and raw recipient strings):

    ```bash
    mace encrypt "$HOME/Desktop/SharedDocument.docx" \
      --to-id "my-key-label" \
      --recipient "mace1<another_public_key_string>" \
      --progress
    ```

### Notes on Usage

*   **Paths with Spaces**: Paths containing spaces must be **quoted** (as shown in examples) or escaped (`My\ Document.pdf`).
*   **Overwriting Output**: If the output file already exists and you want to overwrite it, use the `--force` flag.
*   **Keychain/Touch ID Prompts**: These are expected, as MaCE securely stores private keys in your Keychain.
*   **No Passphrase Support**: The current build of MaCE (v3.2) is **identity-only** and does not support passphrase-based encryption. It relies on Keychain/HPKE recipients.

## Troubleshooting

This section addresses common issues and provides solutions to help you successfully install and use MaCE.

### 1. `Format.swift` Header Mangle Error

**Problem**: You might encounter a build error related to `Sources/MaceCore/Format.swift` where the conditional import section is malformed, appearing as `#elseif canImport(Glibc)if canImport(Glibc)`.

**Reason**: This typically occurs if a previous search/replace operation incorrectly modified the `#if ... #endif` block for platform-specific imports.

**Solution**: Navigate to your MaCE project directory and execute the following `perl` command. This command will correctly repair the conditional import at the top of `Format.swift`.

```bash
cd /path/to/your/MaCE_v3.2_Complete_FIXED # Adjust this path as needed
/usr/bin/perl -0777 -i -pe 'BEGIN{$r="#if canImport(Darwin)\nimport Darwin\n#elseif canImport(Glibc)\nimport Glibc\n#endif"} s/\A(\s*import\s+Foundation\s*)#if.*?#endif/$1$r/s' Sources/MaceCore/Format.swift
```

To verify the fix, you can inspect the first few lines of `Format.swift`:

```bash
sed -n '1,10p' Sources/MaceCore/Format.swift
```

The output should correctly show:

```
import Foundation
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif
```

Additionally, you might want to remove any backup files created by `perl` (e.g., `.bak` files) to silence warnings during the build process:

```bash
rm -f Sources/MaceCore/*.bak
```

### 2. Keychain Error -34018 (Require Biometry)

**Problem**: During `mace keygen` or other Keychain-related operations, you might encounter a `-34018` error, often indicating an issue with biometry requirements (e.g., Touch ID).

**Reason**: Some macOS setups or specific Keychain configurations might be strict about requiring biometry for Keychain access by command-line tools.

**Solution (Temporary Workaround)**: To proceed with the installation and usage, you can temporarily disable the `requireBiometry` flag in `Sources/MaceCore/KeychainStore.swift`. This allows MaCE to interact with the Keychain without strict biometry checks. You can re-enable this later if desired.

```bash
cd /path/to/your/MaCE_v3.2_Complete_FIXED # Adjust this path as needed
/usr/bin/perl -0777 -i -pe 's/requireBiometry:\s*Bool\s*=\s*true/requireBiometry: Bool = false/' Sources/MaceCore/KeychainStore.swift
```

After applying this fix, clean your Swift package build and rebuild MaCE:

```bash
swift package clean
swift build --configuration release
```

If `keygen` still fails with `-34018` after this, you can still use MaCE in passphrase mode (if supported by your build) or consider adjusting Access Control flags in `KeychainStore.swift` more specifically (e.g., using `.userPresence` or providing a `--biometry` toggle).

### 3. General Build and Installation Issues

**Problem**: Build failures or `mace` command not found after installation.

**Reason**: This can be due to various reasons, including incorrect environment setup, missing dependencies, or issues during the Swift build process.

**Solutions**:

*   **Verify PATH**: Ensure that `~/.local/bin` is correctly added to your system's PATH environment variable. After modifying your shell profile (e.g., `~/.zshrc` or `~/.bashrc`), always remember to `source` the file or open a new terminal session.

    ```bash
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc # or ~/.bashrc
    source ~/.zshrc # or ~/.bashrc
    ```

*   **Clean Build**: Sometimes, a corrupted build cache can cause issues. Clean the Swift package and rebuild:

    ```bash
    swift package clean
    swift build --configuration release
    ```

*   **Dependency Check**: Re-run the `install_dependencies` and `install_swift` steps from the installation guide to ensure all prerequisites are met and Swift is correctly installed and active.

*   **Error Message Analysis**: Always read the error messages carefully. They often provide specific clues about the nature of the problem (e.g., missing files, compilation errors, linker issues).

*   **Internet Connectivity**: Confirm you have a stable internet connection, as many steps involve downloading resources.

*   **Disk Space**: Ensure you have sufficient disk space (at least 2GB).

*   **Xcode Command Line Tools**: On macOS, verify that Xcode Command Line Tools are fully installed and updated (`xcode-select --install`).

*   **Permissions**: Ensure you have the necessary permissions to install software and write to directories. Use `sudo` where appropriate for system-wide installations, though user-local installation is generally recommended.

By following these troubleshooting steps, you should be able to resolve most common issues encountered during the installation and usage of MaCE.

## Contributing

To maintain the integrity and direction of this project, contributions are currently accepted by invitation or explicit request only. If you have a suggestion, bug report, or feature request, please open an issue on the GitHub repository. If your proposal aligns with the project's roadmap and goals, you may be invited to contribute directly.

For more details, please refer to the [CONTRIBUTING.md](CONTRIBUTING.md) file.

## License

This project is licensed under the MIT License. See the `LICENSE` file in the project repository for more details.




## Troubleshooting

This section addresses common issues and provides solutions to help you successfully install and use MaCE.

### 1. `Format.swift` Header Mangle Error

**Problem**: You might encounter a build error related to `Sources/MaceCore/Format.swift` where the conditional import section is malformed, appearing as `#elseif canImport(Glibc)if canImport(Glibc)`.

**Reason**: This typically occurs if a previous search/replace operation incorrectly modified the `#if ... #endif` block for platform-specific imports.

**Solution**: Navigate to your MaCE project directory and execute the following `perl` command. This command will correctly repair the conditional import at the top of `Format.swift`.

```bash
cd /path/to/your/MaCE_v3.2_Complete_FIXED # Adjust this path as needed
/usr/bin/perl -0777 -i -pe 'BEGIN{$r="#if canImport(Darwin)\nimport Darwin\n#elseif canImport(Glibc)\nimport Glibc\n#endif"} s/\A(\s*import\s+Foundation\s*)#if.*?#endif/$1$r/s' Sources/MaceCore/Format.swift
```

To verify the fix, you can inspect the first few lines of `Format.swift`:

```bash
sed -n '1,10p' Sources/MaceCore/Format.swift
```

The output should correctly show:

```
import Foundation
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif
```

Additionally, you might want to remove any backup files created by `perl` (e.g., `.bak` files) to silence warnings during the build process:

```bash
rm -f Sources/MaceCore/*.bak
```

### 2. Keychain Error -34018 (Require Biometry)

**Problem**: During `mace keygen` or other Keychain-related operations, you might encounter a `-34018` error, often indicating an issue with biometry requirements (e.g., Touch ID).

**Reason**: Some macOS setups or specific Keychain configurations might be strict about requiring biometry for Keychain access by command-line tools.

**Solution (Temporary Workaround)**: To proceed with the installation and usage, you can temporarily disable the `requireBiometry` flag in `Sources/MaceCore/KeychainStore.swift`. This allows MaCE to interact with the Keychain without strict biometry checks. You can re-enable this later if desired.

```bash
cd /path/to/your/MaCE_v3.2_Complete_FIXED # Adjust this path as needed
/usr/bin/perl -0777 -i -pe 's/requireBiometry:\s*Bool\s*=\s*true/requireBiometry: Bool = false/' Sources/MaceCore/KeychainStore.swift
```

After applying this fix, clean your Swift package build and rebuild MaCE:

```bash
swift package clean
swift build --configuration release
```

If `keygen` still fails with `-34018` after this, you can still use MaCE in passphrase mode (if supported by your build) or consider adjusting Access Control flags in `KeychainStore.swift` more specifically (e.g., using `.userPresence` or providing a `--biometry` toggle).

### 3. General Build and Installation Issues

**Problem**: Build failures or `mace` command not found after installation.

**Reason**: This can be due to various reasons, including incorrect environment setup, missing dependencies, or issues during the Swift build process.

**Solutions**:

*   **Verify PATH**: Ensure that `~/.local/bin` is correctly added to your system's PATH environment variable. After modifying your shell profile (e.g., `~/.zshrc` or `~/.bashrc`), always remember to `source` the file or open a new terminal session.

    ```bash
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc # or ~/.bashrc
    source ~/.zshrc # or ~/.bashrc
    ```

*   **Clean Build**: Sometimes, a corrupted build cache can cause issues. Clean the Swift package and rebuild:

    ```bash
    swift package clean
    swift build --configuration release
    ```

*   **Dependency Check**: Re-run the `install_dependencies` and `install_swift` steps from the installation guide to ensure all prerequisites are met and Swift is correctly installed and active.

*   **Error Message Analysis**: Always read the error messages carefully. They often provide specific clues about the nature of the problem (e.g., missing files, compilation errors, linker issues).

*   **Internet Connectivity**: Confirm you have a stable internet connection, as many steps involve downloading resources.

*   **Disk Space**: Ensure you have sufficient disk space (at least 2GB).

*   **Xcode Command Line Tools**: On macOS, verify that Xcode Command Line Tools are fully installed and updated (`xcode-select --install`).

*   **Permissions**: Ensure you have the necessary permissions to install software and write to directories. Use `sudo` where appropriate for system-wide installations, though user-local installation is generally recommended.

By following these troubleshooting steps, you should be able to resolve most common issues encountered during the installation and usage of MaCE.


