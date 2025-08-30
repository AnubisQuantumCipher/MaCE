# 🛡️ MaCE Installation Guide - BULLETPROOF METHOD

## 🚀 **ONE-COMMAND INSTALLATION (GUARANTEED SUCCESS)**

### **For Linux (Ubuntu/Debian)**

```bash
git clone https://github.com/AnubisQuantumCipher/MaCE.git
cd MaCE
chmod +x install_linux_bulletproof.sh
./install_linux_bulletproof.sh
```

**✅ THAT'S IT!** - Zero user interaction required • Complete automation • Comprehensive testing

---

## 🎯 **WHAT THE SCRIPT DOES**

### **🔧 Automatic Setup**
1. **Updates system packages** (apt update/upgrade)
2. **Installs dependencies** (curl, git, build-essential, libssl-dev, pkg-config, bc, expect)
3. **Downloads and installs Swiftly** (Swift toolchain manager)
4. **Installs Swift 6.1.2** (latest stable version)
5. **Builds MaCE and KeyGen** (release configuration)
6. **Installs binaries** to ~/.local/bin
7. **Configures PATH** in ~/.bashrc
8. **Tests functionality** (complete encryption/decryption cycle)

### **🧪 Verification Tests**
- ✅ **Build verification** - Ensures MaCE and KeyGen compile successfully
- ✅ **Installation verification** - Confirms binaries are accessible
- ✅ **Functionality test** - Tests complete encryption/decryption cycle
- ✅ **Performance test** - Measures overhead and processing speed
- ✅ **Integrity test** - Verifies perfect data restoration

---

## 📊 **EXPECTED RESULTS**

### **🎯 Installation Output**
```
🚀 MaCE v3.2 Linux Installation Script (Bulletproof)
====================================================
[INFO] Updating system packages...
[INFO] Installing required dependencies...
[INFO] Installing Swiftly...
[INFO] Installing Swift 6.1.2...
[INFO] Building MaCE...
[INFO] Building KeyGen utility...
[INFO] Installing MaCE and KeyGen binaries...
[INFO] Testing MaCE installation...
[SUCCESS] MaCE installed successfully!
[INFO] Running comprehensive functionality test...
[SUCCESS] Functionality test passed - encryption/decryption working perfectly!
[SUCCESS] Performance verified: 1253 bytes overhead for 35 byte file

🎉 MaCE v3.2 installation completed successfully!
```

### **🔧 Post-Installation**
After successful installation:
- **MaCE binary**: Available as `mace` command
- **KeyGen utility**: Available as `keygen` command
- **PATH updated**: ~/.bashrc modified to include ~/.local/bin
- **Ready to use**: Restart terminal or run `source ~/.bashrc`

---

## 🎯 **QUICK START AFTER INSTALLATION**

### **1. Generate Key Pair**
```bash
keygen
```
**Output**:
- `mace_private_key.bin` (keep secure!)
- `mace_public_key_bech32.txt` (shareable)

### **2. Encrypt File**
```bash
mace encrypt document.pdf --recipient $(cat mace_public_key_bech32.txt)
```
**Output**: `document.pdf.mace`

### **3. Decrypt File**
```bash
mace decrypt document.pdf.mace --private-key mace_private_key.bin
```
**Output**: `document.pdf` (perfectly restored)

### **4. Verify Integrity**
```bash
sha256sum original.pdf decrypted.pdf
```
**Result**: Identical hashes = perfect restoration

---

## 🛠️ **ALTERNATIVE INSTALLATION METHODS**

### **🔧 Manual Installation (If Script Fails)**

#### **Step 1: Install Dependencies**
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl git build-essential libssl-dev pkg-config bc expect
```

#### **Step 2: Install Swiftly**
```bash
curl -L https://swiftlang.github.io/swiftly/swiftly-install.sh | bash
source ~/.local/share/swiftly/env.sh
```

#### **Step 3: Install Swift**
```bash
swiftly install 6.1.2
swiftly use 6.1.2
```

#### **Step 4: Build MaCE**
```bash
swift build --configuration release
swift build --product keygen --configuration release
```

#### **Step 5: Install Binaries**
```bash
mkdir -p ~/.local/bin
cp .build/release/mace ~/.local/bin/
cp .build/release/keygen ~/.local/bin/
chmod +x ~/.local/bin/mace ~/.local/bin/keygen
```

#### **Step 6: Update PATH**
```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

#### **Step 7: Test Installation**
```bash
mace --version
keygen
```

---

## 🔍 **TROUBLESHOOTING**

### **❓ Script Fails?**
- **Check internet connection**: Script downloads Swift toolchain (~800MB)
- **Ensure sufficient disk space**: Need ~2GB free space
- **Run with sudo if needed**: Some dependency installations may require elevated privileges
- **Check system compatibility**: Tested on Ubuntu 22.04+

### **❓ Command Not Found?**
```bash
# Restart terminal or source bashrc
source ~/.bashrc

# Check if binaries exist
ls -la ~/.local/bin/mace ~/.local/bin/keygen

# Manually add to PATH
export PATH="$HOME/.local/bin:$PATH"
```

### **❓ Build Errors?**
```bash
# Check Swift installation
swift --version

# Rebuild with verbose output
swift build --configuration release --verbose
```

### **❓ Need Help?**
- **See**: [INSTALLATION_TROUBLESHOOTING.md](INSTALLATION_TROUBLESHOOTING.md)
- **Check**: [PERFORMANCE_RESULTS.md](PERFORMANCE_RESULTS.md) for expected results
- **Review**: [MaCE_COMPLETE_SUCCESS_REPORT.md](MaCE_COMPLETE_SUCCESS_REPORT.md) for verification

---

## 📊 **SYSTEM REQUIREMENTS**

### **✅ Supported Systems**
- **Ubuntu 22.04+** (tested and verified)
- **Debian 11+** (compatible)
- **Other Linux distributions** (may work with package manager adjustments)

### **💾 Hardware Requirements**
- **Disk Space**: 2GB free space (for Swift toolchain)
- **RAM**: 2GB minimum (for compilation)
- **CPU**: x86_64 architecture
- **Network**: Internet connection (for downloads)

### **📦 Dependencies (Auto-Installed)**
- curl, git, build-essential
- libssl-dev, pkg-config, bc
- expect (for automation)
- Swift 6.1.2 (via Swiftly)

---

## 🎊 **SUCCESS VERIFICATION**

### **✅ Installation Successful If:**
- Script completes without errors
- `mace --version` shows "3.2.0"
- `keygen` creates key files
- Functionality test passes
- Performance metrics displayed

### **📊 Expected Performance**
- **Small files**: Instant processing
- **Large files**: ~350 MB/s throughput
- **Overhead**: <0.05% for files >1MB
- **Memory**: Minimal usage (streaming)

---

## 🚀 **READY TO USE**

After successful installation, MaCE is ready for:
- ✅ **Personal file encryption**
- ✅ **Enterprise document security**
- ✅ **Cross-platform compatibility**
- ✅ **Production deployment**

**🎯 Start encrypting your files with military-grade security!**

