#!/bin/bash

# MaCE v3.2 Linux Installation Script
# Complete automated installation for Ubuntu/Debian systems

set -e

echo "🚀 MaCE v3.2 Linux Installation Script"
echo "======================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on Linux
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    print_error "This script is designed for Linux systems only."
    exit 1
fi

# Update system packages
print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install required dependencies
print_status "Installing required dependencies..."
sudo apt install -y curl git build-essential libssl-dev pkg-config

# Install Swiftly (Swift toolchain manager)
print_status "Installing Swiftly..."
if ! command -v swiftly &> /dev/null; then
    curl -L https://swiftlang.github.io/swiftly/swiftly-install.sh | bash
    
    # Source Swiftly environment
    export SWIFTLY_HOME_DIR="${HOME}/.local/share/swiftly"
    if [[ -f "${SWIFTLY_HOME_DIR}/env.sh" ]]; then
        source "${SWIFTLY_HOME_DIR}/env.sh"
    fi
    
    print_success "Swiftly installed successfully"
else
    print_warning "Swiftly already installed"
fi

# Install Swift 6.1.2
print_status "Installing Swift 6.1.2..."
source "${HOME}/.local/share/swiftly/env.sh"
swiftly install 6.1.2
swiftly use 6.1.2

# Verify Swift installation
print_status "Verifying Swift installation..."
swift --version

# Build MaCE
print_status "Building MaCE..."
swift build --configuration release

# Install MaCE binary
print_status "Installing MaCE binary..."
mkdir -p "${HOME}/.local/bin"
cp .build/release/mace "${HOME}/.local/bin/"
chmod +x "${HOME}/.local/bin/mace"

# Build and install KeyGen utility
print_status "Building KeyGen utility..."
swift build --product keygen --configuration release
cp .build/release/keygen "${HOME}/.local/bin/"
chmod +x "${HOME}/.local/bin/keygen"

# Add to PATH if not already there
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    print_status "Added ~/.local/bin to PATH in ~/.bashrc"
fi

# Source the updated PATH
export PATH="$HOME/.local/bin:$PATH"

# Test installation
print_status "Testing MaCE installation..."
if command -v mace &> /dev/null; then
    print_success "MaCE installed successfully!"
    mace --version
else
    print_error "MaCE installation failed"
    exit 1
fi

if command -v keygen &> /dev/null; then
    print_success "KeyGen utility installed successfully!"
else
    print_error "KeyGen installation failed"
    exit 1
fi

echo ""
print_success "🎉 MaCE v3.2 installation completed successfully!"
echo ""
echo "📋 Quick Start Guide:"
echo "1. Generate a key pair: keygen"
echo "2. Encrypt a file: mace encrypt file.pdf --recipient \$(cat mace_public_key_bech32.txt)"
echo "3. Decrypt a file: mace decrypt file.pdf.mace --private-key mace_private_key.bin"
echo ""
echo "📚 For complete documentation, see README.md"
echo "🔧 If you encounter issues, restart your terminal to refresh PATH"

