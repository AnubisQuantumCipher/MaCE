# MaCE (Modular AEAD + Composite Encapsulation)

MaCE is a state-of-the-art, cross-platform encryption tool designed for security, performance, and ease of use. Built with modern Swift, it leverages cutting-edge cryptographic primitives to provide a robust and future-proof solution for protecting your data.

## Features

*   **Modular AEAD**: Utilizes Authenticated Encryption with Associated Data (AEAD) for both confidentiality and integrity.
*   **Composite Encapsulation**: Employs a hybrid post-quantum cryptographic approach combining X25519 and ML-KEM-768 for future-proof security.
*   **High Performance**: Optimized for macOS with hardware-accelerated AES-GCM.
*   **Secure Key Management**: Integrates with macOS Keychain for secure private key storage.
*   **Streaming Support**: Efficiently handles large files with streaming encryption/decryption.

## Installation

For a comprehensive installation guide on macOS, please refer to [mace_installation_guide.md](mace_installation_guide.md).

## White Paper

For an in-depth understanding of MaCE's design, cryptographic foundations, and security advantages, please read the [mace_white_paper.md](mace_white_paper.md).

## Usage

Basic usage examples:

*   **Generate a key pair**:
    ```bash
    mace keygen --label "my-key"
    ```

*   **Encrypt a file**:
    ```bash
    mace encrypt my_document.txt --to-id "my-key" --output my_document.txt.mace
    ```

*   **Decrypt a file**:
    ```bash
    mace decrypt my_document.txt.mace --id "my-key" --output my_document_decrypted.txt
    ```

## Contributing

We welcome contributions to the MaCE project. Please refer to the `CONTRIBUTING.md` file (to be added) for guidelines.

## License

This project is licensed under the MIT License - see the `LICENSE` file (to be added) for details.


