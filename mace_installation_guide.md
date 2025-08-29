# MaCE (Modular AEAD + Composite Encapsulation) Installation Guide for macOS

This guide provides comprehensive instructions for installing MaCE, a state-of-the-art encryption tool, on macOS. It covers the installation of necessary prerequisites, including Swift, and the build process for MaCE itself. This guide is based on the `mace_ultimate_bootstrap_FINAL.sh` script and aims to provide a clear, step-by-step process for users.

## Table of Contents

1.  [Introduction](#introduction)
2.  [System Requirements](#system-requirements)
3.  [Step 1: Install Xcode Command Line Tools](#step-1-install-xcode-command-line-tools)
4.  [Step 2: Install Homebrew](#step-2-install-homebrew)
5.  [Step 3: Install Swiftly (Swift Toolchain Manager)](#step-3-install-swiftly-swift-toolchain-manager)
6.  [Step 4: Install Swift Toolchain](#step-4-install-swift-toolchain)
7.  [Step 5: Build MaCE](#step-5-build-mace)
8.  [Step 6: Set Up Environment Variables](#step-6-set-up-environment-variables)
9.  [Step 7: Verify Installation](#step-7-verify-installation)
10. [Basic Usage](#basic-usage)
11. [Troubleshooting](#troubleshooting)

## 1. Introduction

MaCE (Modular AEAD + Composite Encapsulation) is a powerful and modern encryption tool built with Swift, designed for robust data protection. It leverages cutting-edge cryptographic primitives and is optimized for security and performance. This guide will walk you through the process of getting MaCE up and running on your macOS system.

## 2. System Requirements

Before proceeding with the installation, ensure your macOS system meets the following requirements:

*   **Operating System**: macOS (version 15+ recommended for full ML-KEM functionality, though the bootstrap script supports general macOS).
*   **Disk Space**: At least 2 GB of free disk space.
*   **Internet Connection**: A stable internet connection is required to download dependencies and Swift components.
*   **User Privileges**: Administrator (sudo) privileges may be required for some installations (e.g., Xcode Command Line Tools, Homebrew).

## 3. Step 1: Install Xcode Command Line Tools

Xcode Command Line Tools are essential for compiling software on macOS, including Swift. If you don't have them installed, you will need to install them first.

1.  Open your Terminal application (you can find it in `Applications/Utilities/Terminal.app`).
2.  Execute the following command:

    ```bash
    xcode-select --install
    ```

3.  A software update pop-up will appear. Click 


"Install" and follow the prompts to complete the installation. This may take some time depending on your internet connection.
4.  Once the installation is complete, verify it by running:

    ```bash
    xcode-select -p
    ```

    This command should return the path to the Xcode Command Line Tools directory (e.g., `/Applications/Xcode.app/Contents/Developer`).

## 4. Step 2: Install Homebrew

Homebrew is a popular package manager for macOS that simplifies the installation of various software. MaCE's dependencies might implicitly rely on tools installed via Homebrew, and it's generally a good practice to have it.

1.  Open your Terminal.
2.  Install Homebrew by running the following command:

    ```bash
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    ```

3.  Follow the instructions in the terminal. You might be prompted to enter your password. Homebrew will install necessary components and configure your shell environment.
4.  After installation, ensure Homebrew is correctly set up in your PATH. The installer usually provides instructions for this. For zsh (default shell in recent macOS versions), you might need to add something like this to your `~/.zshrc`:

    ```bash
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
    eval "$(/opt/homebrew/bin/brew shellenv)"
    ```

    For bash, it would be `~/.bash_profile` or `~/.bashrc`.
5.  Verify Homebrew installation:

    ```bash
    brew doctor
    ```

    This command should report `Your system is ready to brew.` or similar.

## 5. Step 3: Install Swiftly (Swift Toolchain Manager)

Swiftly is a toolchain manager for Swift, allowing you to easily install and manage different Swift versions. MaCE relies on a specific Swift version (6.1.2 as per the bootstrap script).

1.  Open your Terminal.
2.  Install Swiftly by running the following command:

    ```bash
    curl -L https://swiftlang.github.io/swiftly/swiftly-install.sh | bash
    ```

3.  The script will download and install Swiftly. After installation, you need to source its environment variables. The installer typically adds lines to your shell profile (e.g., `~/.zshrc` or `~/.bashrc`). If not, manually add the following lines to your shell profile file:

    ```bash
    export SWIFTLY_HOME_DIR="${HOME}/.local/share/swiftly"
    if [[ -f "${SWIFTLY_HOME_DIR}/env.sh" ]]; then
        source "${SWIFTLY_HOME_DIR}/env.sh"
    fi
    ```

4.  Reload your shell configuration to apply the changes:

    ```bash
    source ~/.zshrc # or source ~/.bashrc
    ```

5.  Verify Swiftly installation:

    ```bash
    swiftly --version
    ```

    This should display the Swiftly version.

## 6. Step 4: Install Swift Toolchain

Now that Swiftly is installed, you can use it to install the specific Swift toolchain required for MaCE.

1.  Open your Terminal.
2.  Ensure your Swiftly environment is sourced (as in the previous step).
3.  Install Swift version 6.1.2:

    ```bash
    swiftly install 6.1.2
    ```

    You might be prompted to confirm the installation; type `Y` and press Enter.
4.  Set Swift 6.1.2 as the default Swift version for your environment:

    ```bash
    swiftly use 6.1.2
    ```

5.  Verify the Swift installation:

    ```bash
    swift --version
    ```

    This command should output information about Swift version 6.1.2.

## 7. Step 5: Build MaCE

With Swift installed, you can now build the MaCE application from its source code. Ensure you have the MaCE source code extracted. If you downloaded the `MaCE_v3.2_Complete_FIXED.tar.gz` file, extract it first.

1.  Navigate to the root directory of the extracted MaCE source code. This directory should contain `Package.swift`.

    ```bash
    cd /path/to/your/MaCE_v3.2_Complete_FIXED/Sources/Mace # Adjust this path as needed
    ```

2.  Build MaCE in release mode. This will compile the MaCE executable.

    ```bash
    swift build --configuration release
    ```

    This process may take a few minutes as Swift compiles all necessary modules.
3.  Install the compiled MaCE binary to your local bin directory. This makes the `mace` command globally accessible in your terminal.

    ```bash
    mkdir -p "${HOME}/.local/bin"
    cp .build/release/mace "${HOME}/.local/bin/"
    chmod +x "${HOME}/.local/bin/mace"
    ```

## 8. Step 6: Set Up Environment Variables

To ensure `mace` and `swiftly` commands are always available in your terminal, you need to add their paths to your shell's environment variables. The bootstrap script automatically handles this, but it's good to understand the process.

1.  Identify your shell profile file. Common ones are:
    *   `~/.zshrc` (for Zsh, default on recent macOS)
    *   `~/.bashrc` (for Bash)
    *   `~/.bash_profile` (for Bash, often used for login shells)
    *   `~/.profile` (a general profile file)

2.  Open your shell profile file using a text editor (e.g., `nano`, `vim`, or VS Code).

    ```bash
    nano ~/.zshrc # Replace with your shell profile file
    ```

3.  Add the following lines to the end of the file, if they are not already present. These lines ensure Swiftly's environment is sourced and your local `bin` directory (where `mace` is installed) is in your PATH.

    ```bash
    # Added by MaCE bootstrap
    if [[ -f "${HOME}/.local/share/swiftly/env.sh" ]]; then
        source "${HOME}/.local/share/swiftly/env.sh"
    fi
    export PATH="$HOME/.local/bin:$PATH"
    ```

4.  Save the file and exit the text editor.
5.  Reload your shell profile to apply the changes to your current session:

    ```bash
    source ~/.zshrc # Replace with your shell profile file
    ```

## 9. Step 7: Verify Installation

After completing all the steps, it's crucial to verify that MaCE has been installed correctly.

1.  Open a new Terminal window or tab (or reload your current one as shown above).
2.  Check if the `mace` command is recognized:

    ```bash
    mace --version
    ```

    This should display the installed MaCE version (e.g., `MaCE v3.2`).
3.  Check the help command:

    ```bash
    mace --help
    ```

    This should display the main help message for MaCE, listing available commands.

## 10. Basic Usage

Here are some basic commands to get you started with MaCE:

*   **Generate a key pair**: MaCE uses public/private key pairs for encryption. The private key is stored securely in your macOS Keychain.

    ```bash
    mace keygen --label "my-first-mace-key"
    ```

    This will generate a new key pair and store the private key in your Keychain with the label "my-first-mace-key". It will output the public key, which you can share with others.

*   **Encrypt a file**: To encrypt a file, you need the recipient's public key (either directly provided or associated with a Keychain label).

    ```bash
    mace encrypt my_document.txt --to-id "my-first-mace-key" --output my_document.txt.mace
    ```

    Or, if you have the recipient's public key string:

    ```bash
    mace encrypt sensitive_data.zip --recipient "mace1<base64_public_key>" --output sensitive_data.zip.mace
    ```

*   **Decrypt a file**: To decrypt a file, you need access to the private key that corresponds to one of the public keys used for encryption. If the private key is in your Keychain, MaCE will automatically use it.

    ```bash
    mace decrypt my_document.txt.mace --id "my-first-mace-key" --output my_document_decrypted.txt
    ```

    If you have a private key file (e.g., `private_key.bin`):

    ```bash
    mace decrypt encrypted_file.mace --private-key private_key.bin --output decrypted_file.txt
    ```

## 11. Troubleshooting

If you encounter issues during installation or usage, consider the following:

*   **Internet Connectivity**: Ensure you have a stable internet connection throughout the installation process.
*   **Disk Space**: Verify that you have at least 2 GB of free disk space.
*   **Xcode Command Line Tools**: Make sure Xcode Command Line Tools are fully installed and updated.
*   **Shell Profile**: Double-check that your shell profile (`.zshrc`, `.bashrc`, etc.) is correctly configured with the Swiftly environment and `~/.local/bin` in your PATH. Remember to `source` the file after making changes or open a new terminal.
*   **Permissions**: Ensure you have the necessary permissions to install software and write to directories.
*   **Swift Version**: Confirm that Swift version 6.1.2 is active using `swift --version` and `swiftly use 6.1.2`.
*   **Error Messages**: Read any error messages carefully. They often provide clues about what went wrong.

For further assistance, refer to the official MaCE documentation or seek help from the MaCE community. 

