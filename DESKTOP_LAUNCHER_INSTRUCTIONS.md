# 🖥️ Create Desktop Launcher

## Quick Method - Copy to Desktop

1. **Find the file** `NICC_Calibration_Launch.bat` in your project folder
2. **Right-click** on it
3. **Select** "Copy"
4. **Go to your Desktop**
5. **Right-click** on Desktop → "Paste"
6. **Double-click** the file on Desktop to launch the app!

---

## Better Method - Create a Shortcut

1. **Right-click** on `NICC_Calibration_Launch.bat`
2. **Select** "Create shortcut"
3. **Drag the shortcut** to your Desktop
4. **Optional**: Right-click shortcut → Properties → Change Icon
   - Browse to `C:\Windows\System32\imageres.dll`
   - Pick a car or wrench icon!

---

## Best Method - Build Release Version (Recommended!)

For a **professional standalone app** that's much faster:

### Build the Release:
```powershell
flutter clean
flutter build windows --release
```

### Find Your App:
Navigate to:
```
build\windows\x64\runner\Release\nicc_calibration_app.exe
```

### Create Shortcut:
1. **Right-click** on `nicc_calibration_app.exe`
2. **Select** "Create shortcut"
3. **Move shortcut** to Desktop
4. **Rename** to "NICC Calibration"

### Advantages:
- ✅ Starts instantly (no Flutter tools needed)
- ✅ ~50MB standalone executable
- ✅ Can be copied to any Windows PC
- ✅ Professional appearance
- ✅ No command window

---

## Command to Copy File to Desktop via PowerShell:

```powershell
Copy-Item "NICC_Calibration_Launch.bat" "$env:USERPROFILE\Desktop\NICC Calibration.bat"
```

---

## Icon Ideas

Want a custom icon for your app?

1. Find or create a `.ico` file
2. Place it in your project folder
3. Right-click shortcut → Properties → Change Icon
4. Browse to your `.ico` file

Free icon sites:
- https://icons8.com
- https://www.flaticon.com
- Search "car calibration icon"

---

## Quick Copy to Desktop Now:

Run this in PowerShell from your project folder:

```powershell
Copy-Item "NICC_Calibration_Launch.bat" "$env:USERPROFILE\Desktop\" -Force
Write-Host "✅ Launcher copied to Desktop!" -ForegroundColor Green
```

---

**Recommended**: Build the release version for best experience! 🚀










