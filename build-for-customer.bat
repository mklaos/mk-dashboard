@echo off
echo ========================================
echo MK Dashboard - Build for Customer
echo ========================================
echo.

REM Build web version
echo Building Flutter web app...
cd /d D:\mk\parser\mobile
call flutter build web --release
if errorlevel 1 (
    echo.
    echo ❌ Build failed!
    pause
    exit /b 1
)

echo.
echo Copying to docs/web folder...
xcopy /E /I /Y build\web ..\..\docs\web

echo.
echo ========================================
echo ✅ Build complete!
echo ========================================
echo.
echo Files are in: D:\mk\docs\web
echo.
echo Next steps:
echo 1. Commit to YOUR GitHub:
echo    cd D:\mk
echo    git add docs/web
echo    git commit -m "Deploy dashboard update"
echo    git push origin main
echo.
echo 2. Customer pulls to their repo and pushes to their GitHub
echo    OR give them the docs/web folder to upload
echo.
echo Dashboard will be live at:
echo https://YOUR_USERNAME.github.io/mk-dashboard-production/
echo.
pause
