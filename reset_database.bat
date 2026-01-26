@echo off
echo ============================================
echo NICC Calibration Database Reset Tool
echo ============================================
echo.
echo This will delete the existing database file
echo so it can be recreated with the new schema.
echo.
echo Database location:
echo %USERPROFILE%\Documents\nicc_calibration.db
echo.

if exist "%USERPROFILE%\Documents\nicc_calibration.db" (
    echo [FOUND] Database file exists
    echo.
    choice /C YN /M "Do you want to delete it"
    if errorlevel 2 (
        echo.
        echo Operation cancelled.
        pause
        exit /b 0
    )
    
    del "%USERPROFILE%\Documents\nicc_calibration.db"
    
    if not exist "%USERPROFILE%\Documents\nicc_calibration.db" (
        echo.
        echo [SUCCESS] Database file deleted successfully!
        echo.
        echo The app will create a new database with:
        echo   - Pre-Qualifications for all systems
        echo   - Hyperlinks to calibration guides
        echo   - Enhanced ADAS keyword detection
        echo.
    ) else (
        echo.
        echo [ERROR] Failed to delete database file.
        echo Please close the app and try again.
        echo.
    )
) else (
    echo [NOT FOUND] No database file found at expected location
    echo.
    echo The app will create a new database on next run.
    echo.
)

echo.
echo You can now run the app using run_app.bat
echo.
pause







