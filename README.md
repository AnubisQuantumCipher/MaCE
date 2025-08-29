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

Basic usage examples:

*   **Generate a key pair**:
    ```bash
    mace keygen --label "my-first-mace-key"
    ```

*   **Encrypt a file**: To encrypt a file, you can use the recipient's public key or a Keychain entry.

    ```bash
    mace encrypt my_document.txt --to-id "my-first-mace-key" --output my_document.txt.mace
    ```

    Or, using a public key string:

    ```bash
    mace encrypt sensitive_data.zip --recipient "mace1<public_key_string>" --output sensitive_data.zip.mace
    ```

*   **Decrypt a file**: To decrypt a file, you need access to the private key corresponding to one of the encryption keys.

    ```bash
    mace decrypt my_document.txt.mace --id "my-first-mace-key" --output my_document_decrypted.txt
    ```

    Or, using a private key file:

    ```bash
    mace decrypt encrypted_file.mace --private-key private_key.bin --output decrypted_file.txt
    ```

## Contributing

We welcome contributions to the MaCE project. Please refer to the `CONTRIBUTING.md` file (to be added) for guidelines.

## License

This project is licensed under the MIT License. See the `LICENSE` file in the project repository for more details.


