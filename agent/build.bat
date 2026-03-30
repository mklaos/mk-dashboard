@echo off
echo ========================================
echo MK Agent - Building Executable
echo ========================================
echo.

REM Activate virtual environment
call ..\venv\Scripts\activate.bat

REM Install PyInstaller if not already installed
pip install pyinstaller --quiet

echo Building executable...
echo.

REM Build with PyInstaller - include parser module and data files
pyinstaller --name=MK_Agent ^
    --windowed ^
    --onefile ^
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
if exist "dist\MK_Agent.exe" (
    echo ✅ Build Successful!
    echo Executable: dist\MK_Agent.exe
    echo.
    echo Files in dist:
    dir /B dist
) else (
    echo ❌ Build failed - check errors above
)
echo ========================================
echo.
pause
