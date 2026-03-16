@echo off
title CardioGuardian AI - Backend Launcher
color 0A
echo.
echo  ============================================
echo   CardioGuardian AI - Clinical Platform
echo   Starting Backend Server...
echo  ============================================
echo.

REM Auto-detect the local network IP
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /i "IPv4"') do (
    set "DETECTED_IP=%%a"
    goto :found
)
:found
set DETECTED_IP=%DETECTED_IP: =%

echo  Detected Local IP: %DETECTED_IP%
echo  Backend will be accessible at: http://%DETECTED_IP%:8000
echo.

REM Write the detected IP to config file for the Flutter app
echo {"server_ip": "%DETECTED_IP%", "port": 8000} > config.json
echo  Config saved to config.json

echo.
echo  Installing Python dependencies...
pip install fastapi uvicorn pandas joblib scikit-learn numpy openpyxl pydantic 2>nul

echo.
echo  Training ML model if not present...
python train_model.py

echo.
echo  Starting FastAPI server...
echo  Press CTRL+C to stop the server.
echo.
python main.py

pause
