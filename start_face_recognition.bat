@echo off
REM ============================================================================
REM Start Face Recognition Camera Service
REM ============================================================================
REM This batch script activates the virtual environment and runs the face recognition script

setlocal enabledelayedexpansion

REM Define absolute paths (NOT relative to batch file location)
set VENV_ACTIVATE=C:\Users\yahme\El7a2ny AI\venv\Scripts\activate.bat
set VENV_PYTHON=C:\Users\yahme\El7a2ny AI\venv\Scripts\python.exe
set FACE_RECOG_SCRIPT=C:\Users\yahme\El7a2ny AI\Face_recognition_insightface.py
set WORK_DIR=C:\Users\yahme\El7a2ny AI

echo ============================================================================
echo Face Recognition Camera Service Startup
echo ============================================================================
echo.
echo Timestamp: %date% %time%
echo.

REM Check if venv exists
if not exist "%VENV_ACTIVATE%" (
    echo [ERROR] Virtual environment not found at:
    echo %VENV_ACTIVATE%
    echo.
    echo Please ensure venv is created in the El7a2ny AI folder.
    pause
    exit /b 1
)

echo [OK] Virtual environment path found
echo.

REM Check if the face recognition script exists
if not exist "%FACE_RECOG_SCRIPT%" (
    echo [ERROR] Face recognition script not found at:
    echo %FACE_RECOG_SCRIPT%
    echo.
    pause
    exit /b 1
)

echo [OK] Face recognition script found
echo.

REM Change to the AI project directory so relative paths (known_faces/, snapshots/) work
cd /d "%WORK_DIR%"

REM Activate venv
echo [INFO] Activating virtual environment...
call "%VENV_ACTIVATE%"

echo [OK] Virtual environment activated
echo.

REM Run the face recognition script directly (no tee — Windows doesn't have it)
echo [INFO] Starting face recognition...
echo [INFO] To stop, press Q in the camera window or close this window.
echo ============================================================================
echo.

python "%FACE_RECOG_SCRIPT%"

if errorlevel 1 (
    echo.
    echo [ERROR] Face recognition script exited with error code: %errorlevel%
    echo.
    pause
    exit /b 1
)

echo.
echo [OK] Face recognition stopped normally
pause

endlocal
