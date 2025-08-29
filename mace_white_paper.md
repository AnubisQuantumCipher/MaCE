# MaCE (Modular AEAD + Composite Encapsulation): A State-of-the-Art Encryption Tool

**Author**: Manus AI

## Abstract

This white paper introduces MaCE (Modular AEAD + Composite Encapsulation), a cutting-edge encryption tool designed to provide robust, high-performance, and future-proof data protection. Built with modern Swift and optimized for the macOS ecosystem, MaCE leverages advanced cryptographic primitives, including a hybrid post-quantum key encapsulation mechanism, to address contemporary and emerging security challenges. This document delves into MaCE's architectural design, cryptographic foundations, security advantages, and its position as a leading solution for secure data management in an evolving threat landscape.

## 1. Introduction

In an era where digital data is constantly under threat from increasingly sophisticated adversaries, the demand for secure and efficient encryption solutions has never been more critical. Traditional encryption methods, while effective against current computational capabilities, face looming challenges from advancements in cryptanalysis and the eventual advent of practical quantum computers. MaCE (Modular AEAD + Composite Encapsulation) emerges as a response to these evolving threats, offering a state-of-the-art encryption tool that combines robust security with modern design principles.

MaCE is not merely another encryption utility; it is a meticulously engineered system built from the ground up using Swift, a powerful and safe programming language, and leveraging Apple's CryptoKit for optimized performance on macOS. Its design philosophy centers on modularity, authenticated encryption with associated data (AEAD), and composite encapsulation, ensuring both data confidentiality and integrity while preparing for the post-quantum cryptographic era.

This white paper aims to provide a comprehensive overview of MaCE, detailing its core features, the cryptographic primitives it employs, its security posture, and its advantages over existing encryption protocols. We will explore how MaCE addresses the limitations of previous-generation tools and positions itself as a forward-looking solution for individuals and organizations seeking to safeguard their sensitive information.

## 2. Design Principles and Architecture

MaCE's architecture is founded on principles that prioritize security, performance, and adaptability. The tool is designed as a command-line utility, offering a flexible interface for integration into various workflows. Its modular design allows for independent evolution and updates of its components, ensuring that it can adapt to new cryptographic standards and emerging threats without requiring a complete overhaul.

### 2.1. Modular Design

The 


modular nature of MaCE is a cornerstone of its design. This approach separates distinct functionalities into independent modules, such as key generation, encryption, decryption, and key management. This separation offers several benefits:

*   **Enhanced Security**: By isolating components, the attack surface for each module is reduced. A vulnerability in one module is less likely to compromise the entire system.
*   **Improved Maintainability**: Developers can update or replace individual modules without affecting the entire codebase, facilitating rapid response to new cryptographic discoveries or security patches.
*   **Flexibility and Extensibility**: New cryptographic algorithms or features can be integrated as new modules, allowing MaCE to evolve with the cryptographic landscape.

### 2.2. Authenticated Encryption with Associated Data (AEAD)

MaCE employs Authenticated Encryption with Associated Data (AEAD) as a fundamental cryptographic primitive for its payload encryption. AEAD schemes, such as AES-GCM, provide both confidentiality (preventing unauthorized disclosure of data) and integrity/authenticity (ensuring data has not been tampered with and originates from a legitimate source). This is crucial for modern encryption protocols, as it protects against various active attacks where an adversary might attempt to modify ciphertext.

In MaCE, AES-GCM is specifically chosen for payload encryption. This choice is significant for macOS users because AES-GCM can leverage hardware acceleration available on Apple silicon and Intel processors with AES-NI instructions. This hardware optimization leads to significantly faster encryption and decryption operations, making MaCE highly performant for large files and high-throughput applications. The use of authenticated chunks further enhances this, allowing for early detection of tampering and preventing the processing of corrupted or malicious data.

### 2.3. Composite Encapsulation

The 


concept of Composite Encapsulation is central to MaCE's future-proofing strategy, particularly in the context of post-quantum cryptography. This involves combining multiple key encapsulation mechanisms (KEMs) to derive a shared secret. By doing so, MaCE achieves a hybrid security model that offers resilience against both classical and quantum computing threats.

Specifically, MaCE utilizes a hybrid approach that combines X25519 for classical security with ML-KEM-768 for post-quantum security. This means that even if one of the underlying cryptographic primitives is broken (e.g., X25519 by a quantum computer using Shor's algorithm), the overall security of the key encapsulation remains intact due to the strength of the other primitive. This layered security approach ensures forward secrecy and long-term data protection against an uncertain future cryptographic landscape.

## 3. Cryptographic Foundations

MaCE's security is built upon a foundation of well-vetted and modern cryptographic primitives. The selection of these algorithms reflects a commitment to strong security, performance, and future-readiness.

### 3.1. Key Derivation Functions (KDFs)

MaCE employs the HMAC-based Key Derivation Function (HKDF) for deriving cryptographic keys from initial key material. HKDF is a widely recognized and recommended KDF that securely extracts and expands pseudorandom key material. It is used in MaCE for various purposes, including deriving the wrap key for the file key and the payload key for data encryption. The use of per-file context (salt) hardens HKDF, ensuring that each encryption operation is unique and resistant to multi-target attacks.

### 3.2. Symmetric Encryption: AES-GCM

For the encryption of the actual file payload, MaCE utilizes AES-256 in Galois/Counter Mode (GCM). AES-256 is a symmetric block cipher with a 256-bit key, providing a very high level of security. GCM is an authenticated encryption mode that provides both confidentiality and authenticity, meaning it protects against both passive eavesdropping and active tampering. As previously mentioned, AES-GCM is chosen for its ability to leverage hardware acceleration on macOS, resulting in superior performance.

### 3.3. Key Wrapping: ChaCha20-Poly1305

While AES-GCM is used for payload encryption, MaCE employs ChaCha20-Poly1305 for wrapping the file key. ChaCha20 is a stream cipher, and Poly1305 is a message authentication code. This combination provides authenticated encryption. The decision to use ChaCha20-Poly1305 for key wrapping, despite using AES-GCM for the payload, aligns with the design philosophy of age, which often uses ChaCha20-Poly1305 throughout. This choice might also be influenced by the desire to maintain some level of compatibility or familiarity with age's internal mechanisms, while still introducing performance optimizations where possible.

### 3.4. Public-Key Cryptography: X25519

For classical public-key cryptography, MaCE incorporates X25519, an elliptic curve Diffie-Hellman (ECDH) key exchange function. X25519 is known for its high security, speed, and resistance to various side-channel attacks. It is a widely adopted standard for key agreement in modern cryptographic protocols and forms one half of MaCE's hybrid key encapsulation.

### 3.5. Post-Quantum Cryptography: ML-KEM-768

To address the threat of quantum computers, MaCE integrates ML-KEM-768 (formerly known as Kyber-768), a lattice-based key encapsulation mechanism. ML-KEM-768 is a NIST-standardized post-quantum cryptographic algorithm, meaning it is designed to resist attacks from quantum computers. Its inclusion in MaCE provides a crucial layer of future-proofing, ensuring that encrypted data remains secure even if quantum computers become capable of breaking traditional elliptic curve cryptography. The implementation of ML-KEM-768 in MaCE leverages CryptoKit, Apple's cryptographic framework, which is available on macOS 15 and later.

## 4. Security Advantages

MaCE's design and cryptographic choices provide several significant security advantages over existing encryption solutions, particularly when compared to protocols like age.

### 4.1. Enhanced Key Strength

MaCE utilizes a 256-bit file key for its symmetric encryption. This is a direct improvement over age, which employs a 128-bit file key. While 128-bit security is currently considered sufficient for most applications, a 256-bit key offers a substantially larger keyspace, making brute-force attacks computationally infeasible even with theoretical advancements like Grover's algorithm on quantum computers. This higher key strength provides a more robust and future-proof foundation for data confidentiality.

### 4.2. Proactive Post-Quantum Security

The most prominent security advantage of MaCE is its proactive integration of post-quantum cryptography. By combining X25519 with ML-KEM-768 in a hybrid key encapsulation scheme, MaCE ensures that the derived shared secret is secure against both classical and quantum adversaries. This is a critical distinction from protocols that rely solely on pre-quantum algorithms like X25519, which are known to be vulnerable to quantum attacks. MaCE's hybrid approach mitigates the risk of a 


future cryptographic break, providing long-term security for sensitive data.

### 4.3. Robust Header Authentication

MaCE includes a robust mechanism for authenticating its header. The header, which contains critical information about the encryption process (such as recipient stanzas and context), is authenticated using an HMAC-SHA-256 MAC. This prevents an attacker from tampering with the header, which could otherwise lead to various attacks, such as redirecting the encrypted file to a different recipient or manipulating the encryption context. This feature adds an essential layer of integrity protection to the entire encryption process.

### 4.4. Secure Key Management on macOS

MaCE is designed to integrate seamlessly with the macOS Keychain, a secure storage system for keys and other sensitive data. By storing private keys in the Keychain, MaCE leverages the security features of the operating system, including hardware-backed storage and user presence verification (e.g., via Touch ID or password). This approach is more secure than storing private keys as plaintext files on disk, as it protects them from unauthorized access and malware.

## 5. Practical Features and Usage

Beyond its strong security foundations, MaCE offers several practical features that enhance its usability and performance.

### 5.1. Streaming Encryption and Decryption

MaCE supports streaming encryption and decryption, allowing it to handle large files efficiently without requiring the entire file to be loaded into memory. This is particularly important for modern data workflows where file sizes can be substantial. The use of authenticated chunks within the stream ensures that any tampering is detected early in the process, preventing the processing of corrupted data.

### 5.2. Performance Optimization

As a macOS-native application built with Swift and CryptoKit, MaCE is highly optimized for performance on Apple hardware. The use of hardware-accelerated AES-GCM for payload encryption provides a significant speed advantage over software-only implementations of other ciphers. This makes MaCE an ideal choice for performance-critical applications on macOS.

### 5.3. User-Friendly Command-Line Interface

MaCE provides a clear and intuitive command-line interface, making it accessible to both novice and experienced users. The commands for key generation, encryption, and decryption are straightforward, and the tool provides helpful feedback and error messages. The ability to use Keychain labels for recipients simplifies key management and reduces the risk of errors.

### 5.4. Cross-Platform Potential

While the current implementation is optimized for macOS, MaCE is described as a cross-platform tool. The core cryptographic logic, being written in Swift, has the potential to be compiled for other platforms, such as Linux and Windows. This suggests a future where MaCE could offer its advanced security features to a broader audience, although the macOS-specific optimizations (like CryptoKit integration) would need to be adapted or replaced on other platforms.

## 6. Comparison with age

MaCE was inspired by age, and a comparison between the two highlights the advancements that MaCE brings to the table.

| Feature | MaCE | age |
| :--- | :--- | :--- |
| **File Key Size** | 256-bit | 128-bit |
| **Post-Quantum Security** | Hybrid (X25519 + ML-KEM-768) | None (X25519 only) |
| **Payload Encryption** | AES-GCM (hardware accelerated on macOS) | ChaCha20-Poly1305 |
| **Platform** | macOS-native (with cross-platform potential) | Cross-platform (Go, Python, Java, etc.) |
| **Key Management** | Keychain integration on macOS | File-based keys, passphrase support |

While age is a commendable and widely used tool, MaCE represents a significant step forward in terms of security and future-proofing. Its adoption of a 256-bit key and, most importantly, its hybrid post-quantum cryptographic scheme, positions it as a more robust solution for long-term data protection.

## 7. Conclusion

MaCE (Modular AEAD + Composite Encapsulation) is a state-of-the-art encryption tool that successfully combines modern cryptographic principles with high performance and a user-friendly design. By leveraging Swift and macOS-specific optimizations, it offers a superior experience for users within the Apple ecosystem. Its proactive integration of post-quantum cryptography through a hybrid key encapsulation mechanism sets a new standard for future-proof data protection.

As the digital world continues to evolve, so too must our tools for securing it. MaCE represents a significant advancement in the field of file encryption, providing a robust, efficient, and forward-looking solution that is well-equipped to handle the security challenges of today and tomorrow. For individuals and organizations seeking the highest level of data protection, particularly in a post-quantum world, MaCE stands out as a compelling and highly recommended choice.

