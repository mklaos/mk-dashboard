@echo off
echo ========================================
echo MK Agent - Building (One-Folder Mode)
echo ========================================
echo.
echo This will create a folder with all files (faster startup!)
echo.

REM Activate virtual environment
call ..\venv\Scripts\activate.bat

REM Install PyInstaller if not already installed
pip install pyinstaller --quiet

REM Clean previous builds
if exist "dist" rmdir /s /q dist
if exist "build" rmdir /s /q build
if exist "*.spec" del /q *.spec

echo Building executable (one-folder mode)...
echo.

REM Build with PyInstaller - ONEFOLDER mode (faster startup!)
pyinstaller --name=MK_Agent ^
    --windowed ^
    --onedir ^
    --add-data "config.json;." ^
    --add-data "..\parser;parser" ^
    --add-data "..\data;data" ^
    --hidden-import=pandas ^
    --hidden-import=xlrd ^
    --hidden-import=supabase ^
    --hidden-import=watchdog ^
    --hidden-import=pystray ^
    --hidden-import=PIL ^
    --hidden-import=tkinter ^
    --hidden-import=parser_complete ^
    --icon=NONE ^
    tray_app.py

echo.
echo ========================================
if exist "dist\MK_Agent" (
    echo ✅ Build Successful!
    echo Folder: dist\MK_Agent\
    echo.
    echo Files in dist\MK_Agent:
    dir /B dist\MK_Agent
    echo.
    echo Total size:
    for /D %%i in ("dist\MK_Agent") do @echo %%~zi bytes
    echo.
    echo To run:
    echo   dist\MK_Agent\MK_Agent.exe
    echo.
    echo To deploy:
    echo   Copy entire dist\MK_Agent folder to branch computer
) else (
    echo ❌ Build failed - check errors above
)
echo ========================================
echo.
pause
