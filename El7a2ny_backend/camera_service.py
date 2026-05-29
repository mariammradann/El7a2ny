"""
Face Recognition Camera Service Manager
Handles starting and stopping the face recognition process
"""

import subprocess
import os
import psutil
import logging
from pathlib import Path

logger = logging.getLogger(__name__)

# Global process reference
_face_recognition_process = None


def get_script_directory():
    """Get the root project directory"""
    return Path(__file__).parent.parent


def get_batch_script_path():
    """Get the path to the batch script that starts face recognition"""
    return get_script_directory() / "start_face_recognition.bat"


def is_process_running(process_name="python", script_name="Face_recognition_insightface"):
    """
    Check if face recognition process is running
    
    Args:
        process_name: Name of the process to check (default: python)
        script_name: Name of the script to identify (default: Face_recognition_insightface)
    
    Returns:
        bool: True if process is running, False otherwise
    """
    try:
        for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
            try:
                cmdline_list = proc.info.get('cmdline') or []
                cmdline = ' '.join(cmdline_list)
                name = proc.info.get('name') or ''
                if process_name in name.lower() and script_name in cmdline:
                    return True
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                continue
    except Exception as e:
        logger.error(f"Error checking process status: {e}")
    
    return False


def start_face_recognition():
    """
    Start the face recognition process
    
    Returns:
        dict: Status response {'success': bool, 'message': str, 'pid': int or None}
    """
    global _face_recognition_process
    
    try:
        # Check if already running
        if is_process_running():
            logger.info("Face recognition process already running")
            return {
                'success': True,
                'message': 'Face recognition is already running',
                'status': 'already_running'
            }
        
        batch_script = get_batch_script_path()
        
        # Check if batch script exists
        if not batch_script.exists():
            error_msg = f"Batch script not found at {batch_script}"
            logger.error(error_msg)
            return {
                'success': False,
                'message': error_msg,
                'status': 'script_not_found'
            }
        
        # Start the process in the background (Windows)
        # Use CREATE_NEW_CONSOLE to open a new window
        CREATE_NEW_CONSOLE = 0x00000010
        
        _face_recognition_process = subprocess.Popen(
            [str(batch_script)],
            creationflags=CREATE_NEW_CONSOLE
        )
        
        logger.info(f"Face recognition process started with PID: {_face_recognition_process.pid}")
        
        return {
            'success': True,
            'message': 'Face recognition started successfully',
            'status': 'started',
            'pid': _face_recognition_process.pid
        }
    
    except Exception as e:
        error_msg = f"Failed to start face recognition: {str(e)}"
        logger.error(error_msg)
        return {
            'success': False,
            'message': error_msg,
            'status': 'error'
        }


def stop_face_recognition():
    """
    Stop the face recognition process
    
    Returns:
        dict: Status response {'success': bool, 'message': str}
    """
    global _face_recognition_process
    
    try:
        # Kill any running face recognition Python processes
        killed_any = False
        
        for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
            try:
                cmdline_list = proc.info.get('cmdline') or []
                cmdline = ' '.join(cmdline_list)
                name = proc.info.get('name') or ''
                if 'python' in name.lower() and 'Face_recognition_insightface' in cmdline:
                    proc.kill()
                    killed_any = True
                    logger.info(f"Killed face recognition process with PID: {proc.pid}")
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                continue
        
        # Clear global reference
        _face_recognition_process = None
        
        if killed_any:
            return {
                'success': True,
                'message': 'Face recognition stopped successfully',
                'status': 'stopped'
            }
        else:
            return {
                'success': True,
                'message': 'No running face recognition process found',
                'status': 'not_running'
            }
    
    except Exception as e:
        error_msg = f"Failed to stop face recognition: {str(e)}"
        logger.error(error_msg)
        return {
            'success': False,
            'message': error_msg,
            'status': 'error'
        }


def get_camera_status():
    """
    Get the current status of the face recognition camera
    
    Returns:
        dict: Status information {'running': bool, 'message': str}
    """
    running = is_process_running()
    return {
        'running': running,
        'message': 'Face recognition is running' if running else 'Face recognition is not running',
        'status': 'active' if running else 'inactive'
    }
