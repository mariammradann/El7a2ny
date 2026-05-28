#!/usr/bin/env python3
"""
Simple camera test script - Just verify the camera works and displays video
No face recognition, no model loading - just raw camera feed.
"""

import cv2
import sys

def test_camera():
    print("[INFO] Testing camera access...")
    
    # Try to open the default camera (0)
    cap = cv2.VideoCapture(0)
    
    if not cap.isOpened():
        print("[ERROR] Failed to open camera!")
        print("[INFO] Troubleshooting:")
        print("  1. Check if camera is connected")
        print("  2. Check if another app is using the camera")
        print("  3. Try a different camera index (1, 2, etc.)")
        return False
    
    print("[✓] Camera opened successfully!")
    print("[INFO] Camera properties:")
    print(f"  Width: {int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))}")
    print(f"  Height: {int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))}")
    print(f"  FPS: {cap.get(cv2.CAP_PROP_FPS)}")
    
    print("\n[INFO] Starting live camera feed...")
    print("[INFO] Press Q to stop")
    print()
    
    frame_count = 0
    
    while True:
        ret, frame = cap.read()
        
        if not ret:
            print("[ERROR] Failed to capture frame!")
            break
        
        frame_count += 1
        
        # Add frame counter to the display
        cv2.putText(
            frame,
            f"Frame: {frame_count}",
            (10, 30),
            cv2.FONT_HERSHEY_SIMPLEX,
            1.0,
            (0, 255, 0),
            2,
        )
        
        # Show the frame
        cv2.imshow("Camera Test - Press Q to stop", frame)
        
        # Check for 'q' key press
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break
    
    cap.release()
    cv2.destroyAllWindows()
    
    print(f"\n[✓] Camera test completed. Captured {frame_count} frames.")
    return True

if __name__ == "__main__":
    try:
        success = test_camera()
        sys.exit(0 if success else 1)
    except Exception as e:
        print(f"[ERROR] Exception occurred: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
