# 📦 NICC Calibration App - Deployment Guide

## 🚀 Distributing Your App with AI Features

Your NICC Calibration app now automatically detects and uses Ollama for AI features!

### ✨ How It Works

The app has **smart AI detection**:
1. 🔍 Checks if Ollama is installed on the system
2. ✅ If found: Automatically starts and uses it
3. ⚠️ If not found: Uses keyword matching fallback
4. 🎯 Works great either way!

---

## 📋 Deployment Options

### Option 1: App Only (Simple Distribution)
**Size**: ~50MB  
**AI**: Users install Ollama themselves  

1. Build your app:
   ```powershell
   flutter build windows --release
   ```

2. Find the executable:
   ```
   build\windows\x64\runner\Release\nicc_calibration_app.exe
   ```

3. Distribute to users with these instructions:
   - Run the app (works immediately with keyword matching)
   - For AI features: Install Ollama from https://ollama.ai
   - App auto-detects Ollama once installed!

### Option 2: App + Ollama Installer (Recommended)
**Size**: ~50MB + 500MB Ollama installer  
**AI**: Users run installer, then full AI features  

Create a deployment package:
```
NICC_Calibration_Setup/
├── nicc_calibration_app.exe
├── OllamaSetup.exe
└── INSTALL.txt
```

**INSTALL.txt:**
```
NICC Calibration Assistant - Installation

Step 1: Install Ollama (for AI features)
   - Double-click OllamaSetup.exe
   - Follow installer prompts
   - Wait for "Ollama installed successfully"

Step 2: Run the app
   - Double-click nicc_calibration_app.exe
   - App will auto-detect Ollama
   - AI features activate automatically!

Note: App works without Ollama using smart keyword matching.
```

### Option 3: Fully Bundled (Advanced)
**Size**: ~5GB (includes AI model)  
**AI**: Everything included, works offline  

**Steps:**

1. **Build the app**
   ```powershell
   flutter build windows --release
   ```

2. **Package Ollama executable**
   ```powershell
   # Copy Ollama to app directory
   Copy-Item "$env:LOCALAPPDATA\Programs\Ollama\*" `
             "build\windows\x64\runner\Release\ollama\" -Recurse
   ```

3. **Package the AI model** (optional, 4.4GB)
   ```powershell
   # Copy Ollama models
   Copy-Item "$env:USERPROFILE\.ollama\*" `
             "build\windows\x64\runner\Release\ollama_models\" -Recurse
   ```

4. **Create installer using Inno Setup or similar**

---

## 🎯 Recommended Deployment: Option 2

**Why**: Perfect balance of size and features
- Small initial download (~50MB app)
- Quick Ollama setup (~5 min)
- Full AI capabilities
- Professional user experience

---

## 📦 Building for Distribution

### Release Build
```powershell
# Clean build
flutter clean

# Build release version
flutter build windows --release

# Find executable
explorer build\windows\x64\runner\Release
```

### Create ZIP Package
```powershell
# Navigate to release directory
cd build\windows\x64\runner\Release

# Create package
Compress-Archive -Path * -DestinationPath NICC_Calibration_App.zip
```

---

## 🖥️ System Requirements

### Minimum Requirements
- **OS**: Windows 10 or later
- **RAM**: 4GB
- **Storage**: 500MB (app only) or 5GB (with AI model)
- **Internet**: Only for initial AI model download

### For AI Features (Ollama)
- **Additional RAM**: 4GB (8GB total recommended)
- **Storage**: +5GB for AI model
- **One-time download**: 4.4GB

---

## 👥 User Installation Flow

### First-Time Users (Without Ollama)

1. **Download** `nicc_calibration_app.exe`
2. **Run the app** - Works immediately!
3. **See notification**: "AI Assistant Offline - Using Fallback Analysis"
4. **App functions**: Keyword-based calibration detection

### Enabling AI (User Choice)

1. **In-app notification**: "Install Ollama for AI features"
2. **Click link** or download from https://ollama.ai
3. **Install Ollama** (2-minute process)
4. **Restart app** - AI automatically activates!
5. **First AI use**: Model downloads in background (5-10 min)

---

## 🔧 Configuration

### Change AI Model

Edit `lib/services/ollama_service.dart`:
```dart
OllamaService({
  this.baseUrl = 'http://localhost:11434',
  this.model = 'mistral',  // Change to 'llama2', 'phi', etc.
});
```

### Pre-download Model (for offline deployment)

```powershell
# On development machine
ollama pull mistral

# Copy model files
$modelPath = "$env:USERPROFILE\.ollama\models"
Copy-Item $modelPath "deployment\ollama_models" -Recurse
```

Then include in installer to place in user's `.ollama\models` folder.

---

## 📊 File Sizes Reference

| Component | Size | Notes |
|-----------|------|-------|
| Flutter App | ~50MB | Core application |
| Ollama Executable | ~500MB | AI runtime |
| Mistral Model | ~4.4GB | AI model (one-time download) |
| Llama2 Model | ~4.7GB | Alternative AI model |
| Phi Model | ~1.6GB | Smaller, faster model |

---

## ✅ Testing Deployment

### Test Without Ollama
1. Uninstall Ollama or use clean VM
2. Run app
3. Verify: "AI Assistant Offline" status
4. Test: Estimate analysis with keyword matching
5. Confirm: All features work (just no AI chat)

### Test With Ollama
1. Install Ollama
2. Run app
3. Verify: "AI Assistant Connected" (green)
4. Test: Ask AI question in chat
5. Verify: Intelligent responses

---

## 🚨 Troubleshooting for Users

### "AI features not working"
- Install Ollama from https://ollama.ai
- Restart the app
- Wait 5-10 min for model download on first AI use

### "App won't start"
- Ensure Windows 10 or later
- Install Visual C++ Redistributable if needed
- Check antivirus isn't blocking

### "Slow AI responses"
- Normal on first use (downloading model)
- After first use, responses are fast
- Consider using smaller 'phi' model

---

## 🎉 Distribution Checklist

- [ ] Build release version
- [ ] Test on clean Windows machine
- [ ] Test without Ollama installed
- [ ] Test with Ollama installed
- [ ] Create installation instructions
- [ ] Package with Ollama installer (Option 2)
- [ ] Create README for users
- [ ] Test full installation flow
- [ ] Verify all features work
- [ ] Document system requirements

---

## 📞 Support Information

Include in your distribution:

**For Users:**
- README with installation steps
- Link to Ollama website
- System requirements
- Contact for support

**For Developers:**
- See BUILD_SUMMARY.md
- See APP_OVERVIEW.md
- Check GitHub issues

---

**Your app is now ready for deployment with smart AI integration!** 🚀✨







