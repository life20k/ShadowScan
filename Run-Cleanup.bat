@echo off
:: ShadowScan - PC Cleanup Launcher
:: Right-click this file and select "Run as Administrator"

echo.
echo  ============================================
echo   ShadowScan - PC Cleanup
echo   Scan for shadows. Remove the threats.
echo  ============================================
echo.
echo  This will clean up your PC for better performance.
echo.
echo  Options:
echo    1. Full cleanup (all 17 features - recommended)
echo    2. Quick cleanup (temp files and orphan detection only)
echo    3. WiFi optimization only
echo    4. Performance boost only (startup, services, visual effects)
echo    5. Dry-run mode (preview all changes without deleting)
echo    6. Exit
echo.

set /p choice="  Select option (1-6): "

if "%choice%"=="1" (
    powershell -ExecutionPolicy Bypass -File "%~dp0ShadowScan.ps1" -All
) else if "%choice%"=="2" (
    powershell -ExecutionPolicy Bypass -File "%~dp0ShadowScan.ps1" -SkipDownloads -SkipAccessibility -SkipWiFi -SkipShadowAccounts -SkipRegistry -SkipProcessScan -SkipSystemRepair -SkipStartup -SkipServices -SkipBrowsers -SkipVisualEffects -SkipDevCleanup
) else if "%choice%"=="3" (
    powershell -ExecutionPolicy Bypass -File "%~dp0ShadowScan.ps1" -SkipTemp -SkipDownloads -SkipOrphans -SkipAccessibility -SkipShadowAccounts -SkipRegistry -SkipSystem -SkipProcessScan -SkipSystemRepair -SkipStartup -SkipServices -SkipBrowsers -SkipVisualEffects -SkipDevCleanup
) else if "%choice%"=="4" (
    powershell -ExecutionPolicy Bypass -File "%~dp0ShadowScan.ps1" -SkipTemp -SkipDownloads -SkipOrphans -SkipAccessibility -SkipWiFi -SkipShadowAccounts -SkipRegistry -SkipProcessScan -SkipSystemRepair -SkipBrowsers -SkipDevCleanup
) else if "%choice%"=="5" (
    powershell -ExecutionPolicy Bypass -File "%~dp0ShadowScan.ps1" -All -DryRun
) else (
    echo.
    echo  Exiting...
    exit /b
)

echo.
echo  Press any key to exit...
pause >nul
