#!/usr/bin/env python
"""
Quick script to create an admin user in the database.
Run this from the project root: python create_admin_user.py
"""

import os
import sys
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'El7a2ny_backend.settings')
django.setup()

from El7a2ny_backend.models import User
from django.contrib.auth.hashers import make_password

def create_admin():
    # Check if admin already exists
    if User.objects.filter(email="admin@el7a2ny.com").exists():
        print("⚠️  Admin user with email 'admin@el7a2ny.com' already exists!")
        response = input("Do you want to create a different admin user? (y/n): ")
        if response.lower() != 'y':
            return
    
    # Get input from user
    print("\n=== Creating Admin User ===\n")
    
    name = input("Admin name (default: 'System Admin'): ").strip() or "System Admin"
    email = input("Admin email: ").strip()
    phone = input("Phone number: ").strip() or "01200000000"
    password = input("Password (min 8 chars, default: 'Admin@123'): ").strip() or "Admin@123"
    
    # Validate inputs
    if not email or '@' not in email:
        print("❌ Invalid email!")
        return
    
    if len(password) < 8:
        print("❌ Password must be at least 8 characters!")
        return
    
    if User.objects.filter(email=email).exists():
        print(f"❌ User with email '{email}' already exists!")
        return
    
    # Create admin user
    try:
        admin_user = User.objects.create(
            name=name,
            email=email,
            phone_number=phone,
            password=make_password(password),
            user_type="admin",
            status="active",
            verification_status="verified"
        )
        
        print("\n✅ Admin user created successfully!")
        print(f"   Name: {admin_user.name}")
        print(f"   Email: {admin_user.email}")
        print(f"   User ID: {admin_user.user_id}")
        print(f"   User Type: {admin_user.user_type}")
        print(f"\n🔐 Test these credentials in the Flutter app:")
        print(f"   Email: {email}")
        print(f"   Password: {password}")
        
    except Exception as e:
        print(f"❌ Error creating admin user: {e}")
        return

if __name__ == "__main__":
    create_admin()
