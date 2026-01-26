@echo off
title NICC Calibration Assistant
color 0B

echo.
echo ================================================
echo     NICC Calibration Assistant Launcher
echo ================================================
echo.
echo Starting application...
echo.

REM Set Flutter path
set FLUTTER_PATH=%USERPROFILE%\Downloads\flutter_windows_3.35.5-stable\flutter\bin
set PATH=%FLUTTER_PATH%;%PATH%

REM Change to app directory
cd /d "%~dp0"

REM Run the app
flutter run -d windows

pause










