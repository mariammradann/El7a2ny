@echo off
REM ============================================================================
REM Simple Camera Test - No Face Recognition
REM ============================================================================
REM This batch script just tests if the camera works with a simple video feed

setlocal enabledelayedexpansion

set SCRIPT_DIR=%~dp0
set VENV_PATH=%SCRIPT_DIR%.venv\Scripts\activate.bat
set TEST_SCRIPT=%SCRIPT_DIR%test_camera_simple.py

echo ============================================================================
echo Simple Camera Test
echo ============================================================================
echo.
echo This will open a simple camera feed WITHOUT face recognition.
echo This helps verify your camera is working correctly.
echo.

if not exist "%VENV_PATH%" (
    echo [ERROR] Virtual environment not found
    pause
    exit /b 1
)

echo [INFO] Activating virtual environment...
call "%VENV_PATH%"

echo [INFO] Checking OpenCV...
python -c "import cv2" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] OpenCV not installed. Run: pip install opencv-python
    pause
    exit /b 1
)

echo [✓] OpenCV found
echo.
echo [INFO] Starting camera test...
echo [INFO] Press Q in the camera window to stop
echo.

python "%TEST_SCRIPT%"

if errorlevel 1 (
    echo.
    echo [ERROR] Camera test failed
    pause
    exit /b 1
)

echo.
echo [✓] Camera test completed successfully!
pause
