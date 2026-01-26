# NICC Calibration Assistant - Setup Script
# PowerShell script to set up and run the Flutter app

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  NICC Calibration Assistant Setup  " -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Check if Flutter is installed
Write-Host "Checking Flutter installation..." -ForegroundColor Yellow
$flutterInstalled = Get-Command flutter -ErrorAction SilentlyContinue

if (-not $flutterInstalled) {
    Write-Host "❌ Flutter is not installed!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install Flutter from: https://flutter.dev/docs/get-started/install/windows" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "After installation, run this script again." -ForegroundColor Yellow
    pause
    exit
}

Write-Host "✅ Flutter is installed!" -ForegroundColor Green
Write-Host ""

# Check Flutter doctor
Write-Host "Running Flutter doctor..." -ForegroundColor Yellow
flutter doctor
Write-Host ""

# Install dependencies
Write-Host "Installing dependencies..." -ForegroundColor Yellow
flutter pub get

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Dependencies installed successfully!" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to install dependencies!" -ForegroundColor Red
    pause
    exit
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "         Setup Complete! 🎉          " -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Check Ollama installation
Write-Host "Checking for Ollama (AI features)..." -ForegroundColor Yellow
$ollamaInstalled = Get-Command ollama -ErrorAction SilentlyContinue

if ($ollamaInstalled) {
    Write-Host "✅ Ollama is installed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Available models:" -ForegroundColor Yellow
    ollama list
} else {
    Write-Host "⚠️  Ollama not found (optional)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "The app will work in fallback mode without AI." -ForegroundColor Yellow
    Write-Host "To enable AI features, install Ollama from: https://ollama.ai" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "        Ready to Launch! 🚀          " -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Ask user if they want to run the app
$runApp = Read-Host "Would you like to run the app now? (y/n)"

if ($runApp -eq 'y' -or $runApp -eq 'Y') {
    Write-Host ""
    Write-Host "Launching NICC Calibration Assistant..." -ForegroundColor Green
    Write-Host ""
    Write-Host "Tips:" -ForegroundColor Cyan
    Write-Host "  - Press 'r' for hot reload" -ForegroundColor White
    Write-Host "  - Press 'R' for hot restart" -ForegroundColor White
    Write-Host "  - Press 'q' to quit" -ForegroundColor White
    Write-Host ""
    
    # Try to run on Windows first, fall back to first available device
    $devices = flutter devices --machine | ConvertFrom-Json
    
    if ($devices | Where-Object { $_.platform -eq 'windows' }) {
        Write-Host "Running on Windows desktop..." -ForegroundColor Green
        flutter run -d windows
    } else {
        Write-Host "Running on first available device..." -ForegroundColor Green
        flutter run
    }
} else {
    Write-Host ""
    Write-Host "To run the app later, use:" -ForegroundColor Yellow
    Write-Host "  flutter run -d windows" -ForegroundColor White
    Write-Host ""
    Write-Host "Or open in VS Code and press F5" -ForegroundColor Yellow
    Write-Host ""
}

Write-Host ""
Write-Host "For help, see README.md or QUICK_START.md" -ForegroundColor Cyan
Write-Host ""










