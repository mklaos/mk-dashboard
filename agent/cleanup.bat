@echo off
echo ============================================
echo MK Agent - Cleanup Utility
echo ============================================
echo.

:: Clean timestamped duplicate files from source
echo Cleaning source folder...
cd /d "%~dp0..\source"
if exist "1*.*" (
    del "1*.*" /Q 2>nul
    echo   Removed timestamped files from source
) else (
    echo   No timestamped files found in source
)

:: Count remaining files
for /f %%i in ('dir /b *.xls* 2^>nul ^| find /c ".xls"') do set FILECOUNT=%%i
echo   Remaining files in source: %FILECOUNT%

:: Clean processed files log
echo.
echo Cleaning processed files log...
cd /d "%~dp0..\agent\dist"
if exist "processed_files.json" (
    del "processed_files.json" /Q
    echo   Removed processed_files.json
) else (
    echo   processed_files.json not found
)

echo.
echo ============================================
echo Cleanup complete!
echo ============================================
echo.
echo Next steps:
echo 1. Verify %FILECOUNT% files in source folder
echo 2. Start/restart MKAgent.exe
echo 3. Click "Sync Now" in tray menu
echo.
pause
