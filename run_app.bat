@echo off
echo.
echo =======================================
echo   NICC Calibration App Launcher
echo =======================================
echo.

set FLUTTER_PATH=%USERPROFILE%\Downloads\flutter_windows_3.35.5-stable\flutter\bin
set PATH=%FLUTTER_PATH%;%PATH%

echo Starting NICC Calibration App...
echo.

flutter run -d windows

pause










