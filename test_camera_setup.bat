@echo off
REM ============================================================================
REM Test Camera Setup - Diagnostic Tool
REM ============================================================================
REM This script tests if your camera and environment are set up correctly

setlocal enabledelayedexpansion

echo ============================================================================
echo Camera Setup Diagnostic Tool
echo ============================================================================
echo.

REM Get the directory where this script is located
set SCRIPT_DIR=%~dp0

REM Define paths
set VENV_PATH=%SCRIPT_DIR%.venv\Scripts\activate.bat

echo [1/4] Checking virtual environment...
if not exist "%VENV_PATH%" (
    echo [✗] Virtual environment not found at %VENV_PATH%
    echo Please run: python -m venv .venv
    pause
    exit /b 1
)
echo [✓] Virtual environment exists

echo.
echo [2/4] Activating virtual environment...
call "%VENV_PATH%"
echo [✓] Virtual environment activated

echo.
echo [3/4] Testing required Python packages...
echo.

python -c "import cv2; print('  [✓] OpenCV')" || echo [✗] OpenCV not found - run: pip install opencv-python
python -c "import insightface; print('  [✓] InsightFace')" || echo [✗] InsightFace not found - run: pip install insightface
python -c "import numpy; print('  [✓] NumPy')" || echo [✗] NumPy not found - run: pip install numpy
python -c "import requests; print('  [✓] Requests')" || echo [✗] Requests not found - run: pip install requests
python -c "import pickle; print('  [✓] Pickle')" || echo [✗] Pickle not found - built-in module

echo.
echo [4/4] Testing camera access...
python -c "import cv2; cap = cv2.VideoCapture(0); result = cap.isOpened(); cap.release(); exit(0 if result else 1)" && (
    echo [✓] Camera is accessible
) || (
    echo [✗] Camera not accessible
    echo Troubleshooting:
    echo   1. Check if camera is connected
    echo   2. Check if another app is using the camera
    echo   3. Try using Device Manager to verify camera is recognized
)

echo.
echo ============================================================================
echo Diagnostic complete. If all checks passed, you're ready to use the camera!
echo ============================================================================
echo.
pause
