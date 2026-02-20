@echo off
echo ========================================
echo MK Restaurants Local Agent
echo ========================================
echo.

REM Activate virtual environment
call ..\venv\Scripts\activate.bat

REM Run the tray app
python tray_app.py

pause
