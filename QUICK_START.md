# 🚀 Quick Start Guide

Get the NICC Calibration Assistant running in minutes!

## ⚡ Fast Setup (5 minutes)

### Step 1: Install Flutter
If you don't have Flutter installed:

**Windows:**
1. Download Flutter SDK from [flutter.dev](https://flutter.dev/docs/get-started/install/windows)
2. Extract to `C:\src\flutter`
3. Add to PATH: `C:\src\flutter\bin`
4. Run: `flutter doctor` to verify

### Step 2: Install Dependencies
Open PowerShell in the project directory:

```powershell
flutter pub get
```

This will download all required packages (may take 2-3 minutes).

### Step 3: Run the App

**Option A: Windows Desktop (Recommended for testing)**
```powershell
flutter run -d windows
```

**Option B: Android Emulator**
1. Start Android Emulator from Android Studio
2. Run: `flutter run`

**Option C: Connected Android Device**
1. Enable USB debugging on your phone
2. Connect via USB
3. Run: `flutter run`

That's it! The app will launch with a beautiful UI.

## 🤖 Optional: Enable AI Features

The app works without Ollama, but AI features enhance the experience.

### Install Ollama (Optional - 10 minutes)

1. **Download Ollama**
   - Visit [ollama.ai](https://ollama.ai/download)
   - Download for Windows
   - Run installer

2. **Pull a Model**
   ```powershell
   ollama pull llama2
   ```
   
3. **Verify Ollama is Running**
   ```powershell
   ollama list
   ```

4. **Restart the Flutter App**
   - The app will automatically detect Ollama
   - You'll see "AI Assistant Connected" banner

### Alternative Models (Optional)

For faster responses, try smaller models:
```powershell
ollama pull mistral      # Faster, still excellent
ollama pull phi          # Smallest, very fast
```

Then update `lib/services/ollama_service.dart`:
```dart
OllamaService({
  this.baseUrl = 'http://localhost:11434',
  this.model = 'mistral',  // Change this
});
```

## 📱 Using the App

### 1️⃣ Analyze an Estimate
- Tap **"Analyze Estimate"**
- Paste estimate text (or type repairs)
- Click **"Analyze with AI"**
- View required calibrations instantly!

### 2️⃣ Ask Questions
- Tap **"AI Assistant"**
- Ask: *"What calibrations for windshield replacement?"*
- Get instant expert answers

### 3️⃣ Browse Systems
- Tap **"Systems Library"**
- Search or filter by category
- Tap any system for full details

### 4️⃣ View History
- Tap **"History"**
- See all past analyses
- Track your calibration recommendations

## 🎨 Features Overview

| Feature | Description | Requires AI |
|---------|-------------|-------------|
| Estimate Analysis | Identify calibrations from text | ✅ Enhanced |
| AI Chat | Ask questions about calibrations | ✅ Yes |
| Systems Library | Browse 10+ calibration systems | ❌ No |
| History | Track past analyses | ❌ No |
| Search | Find systems by keyword | ❌ No |

## 🐛 Troubleshooting

### "Flutter command not found"
- Add Flutter to your PATH
- Restart PowerShell/Terminal

### "No devices found"
- For Windows: Run `flutter config --enable-windows-desktop`
- For Android: Start an emulator or connect a device

### "Ollama not connecting"
- Ensure Ollama is running: `ollama list`
- Check if port 11434 is accessible
- App works in fallback mode without Ollama

### "Dependencies error"
- Delete `pubspec.lock`
- Run `flutter clean`
- Run `flutter pub get`

### "Build errors"
- Run `flutter doctor` to check setup
- Ensure Flutter SDK is up to date: `flutter upgrade`

## 💡 Tips

1. **Performance**: Windows desktop app is fastest for testing
2. **Development**: Use hot reload (press 'r' in terminal) for quick updates
3. **AI Quality**: Llama2 gives best results but is slower; Mistral is good balance
4. **Offline Use**: App works without internet (except for Ollama downloads)

## 🎯 Example Workflow

```
1. Open app → Beautiful animated home screen
2. Tap "Analyze Estimate"
3. Paste: "Windshield replacement, front bumper repair"
4. Tap "Analyze with AI"
5. See results: ADAS Camera Calibration + Radar Sensor
6. View cost estimate: ~$250-500
7. Tap system card to see full details
8. Ask AI: "What equipment is needed?"
9. Get detailed answer with equipment list
```

## 📞 Support

**Can't get it running?**
1. Check `flutter doctor` output
2. Verify all dependencies installed
3. Try: `flutter clean && flutter pub get`
4. Contact IT support with error messages

## 🎉 You're Ready!

The app is now set up and ready to use. Explore the features and enjoy the stunning UI!

---

**Built with Flutter 💙**










