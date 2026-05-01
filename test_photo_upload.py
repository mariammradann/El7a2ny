#!/usr/bin/env python
"""Test script to verify photo uploads work correctly"""

import os
import sys
import requests
from pathlib import Path
from PIL import Image
import io
import uuid


# Create a test image
def create_test_image(filename="test_photo.jpg"):
    """Create a simple test image"""
    img = Image.new("RGB", (100, 100), color=(255, 0, 0))
    img.save(filename)
    return filename


# Test photo upload
def test_photo_upload():
    # Server URL
    base_url = "http://127.0.0.1:8000"

    # Use existing user from database
    user_id = "a51fabd8-9752-4515-b53f-0ab508887064"
    test_image_path = create_test_image()

    try:
        # Prepare multipart form data
        with open(test_image_path, "rb") as img_file:
            files = {"media_files": (test_image_path, img_file, "image/jpeg")}
            data = {
                "user_id": user_id,
                "category": "test",
                "description": "Test photo upload",
                "latitude": 30.0444,
                "longitude": 31.2357,
                "address": "Test Location",
            }

            print("📤 Sending test photo upload...")
            print(f"   User ID: {user_id}")
            print(f"   Image: {test_image_path}")

            response = requests.post(
                f"{base_url}/api/incidents/", files=files, data=data
            )

            print(f"📥 Response Status: {response.status_code}")
            print(f"📥 Response: {response.json()}")

            if response.status_code in [200, 201]:
                print("✅ Upload successful!")
                result = response.json()
                if "media_files" in result:
                    print(f"✅ Media files in response: {result['media_files']}")
                else:
                    print("⚠️ No media_files in response")
            else:
                print(f"❌ Upload failed: {response.text}")

    finally:
        # Cleanup
        if os.path.exists(test_image_path):
            os.remove(test_image_path)
            print(f"🧹 Cleaned up test image")


if __name__ == "__main__":
    # Check if PIL is available
    try:
        import PIL
    except ImportError:
        print("Installing Pillow...")
        os.system(".\.venv\Scripts\python -m pip install pillow -q")

    test_photo_upload()
