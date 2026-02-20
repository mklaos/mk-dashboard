@echo off
echo ============================================
echo Building MK Agent Executable
echo ============================================
echo.

:: Add PyInstaller to PATH (adjust if needed for your Python version)
set PATH=%PATH%;%APPDATA%\Python\Python314\Scripts

:: Clean only PyInstaller's working folders
:: IMPORTANT: Do NOT delete config.json, credentials.enc, or dist folder
if exist build rmdir /s /q build
if exist MKAgent.spec del MKAgent.spec

:: Save existing config and credentials to temp location
set CONFIG_EXISTS=0
set CREDS_EXISTS=0

if exist config.json (
    set CONFIG_EXISTS=1
    copy config.json config.json.bak /Y >nul
)

if exist credentials.enc (
    set CREDS_EXISTS=1
    copy credentials.enc credentials.enc.bak /Y >nul
)

echo Running PyInstaller...
echo.

:: Run PyInstaller
pyinstaller --noconsole --onefile ^
    --name "MKAgent" ^
    --add-data "..\\parser;parser" ^
    --hidden-import "pandas" ^
    --hidden-import "pystray" ^
    --hidden-import "PIL._imagingtk" ^
    --hidden-import "PIL._tkinter_finder" ^
    --hidden-import "cryptography" ^
    --collect-all "supabase" ^
    --collect-all "httpx" ^
    "tray_app.py"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ============================================
    echo BUILD FAILED!
    echo ============================================
    echo Check error messages above.
    pause
    exit /b 1
)

echo.
echo ============================================
echo Build successful!
echo ============================================
echo.

:: Restore config and credentials if they existed
if %CONFIG_EXISTS%==1 (
    if exist config.json.bak copy config.json.bak config.json /Y >nul
)

if %CREDS_EXISTS%==1 (
    if exist credentials.enc.bak copy credentials.enc.bak credentials.enc /Y >nul
)

:: Cleanup backup files
if exist config.json.bak del config.json.bak
if exist credentials.enc.bak del credentials.enc.bak

:: NOTE: NOT copying config.json to dist (users can maintain their own test configurations)
:: BUT we DO copy credentials.enc because it's machine-specific encrypted data
if exist credentials.enc (
    copy credentials.enc dist\credentials.enc /Y >nul
    echo [OK] credentials.enc copied to dist folder
)

:: Copy data folder (product translations) to dist
if exist ..\data (
    if not exist dist\data mkdir dist\data
    xcopy ..\data\*.* dist\data\ /Y /E /I >nul
    echo [OK] data folder copied to dist folder
)

echo NOTE: Your config.json in 'dist' folder is preserved (not overwritten).
echo.

echo.
echo Executable location: dist\MKAgent.exe
echo.
echo IMPORTANT: Run MKAgent.exe from the 'dist' folder
echo (config.json and credentials.enc must be in the same folder)
echo.
echo ============================================
pause
