# Admin Page Setup Guide

## Overview
You now have a fully functional admin page accessible through admin credentials from the normal login screen. Admin users will be automatically routed to the AdminScreen instead of the regular MainShellScreen.

## What Was Changed

### Backend (Django)
1. **Modified `El7a2ny_backend/views.py`**
   - Updated the `check_user` endpoint to include `user_type` in the login response
   - Now returns: `email`, `user_id`, `name`, and **`user_type`**

### Frontend (Flutter)

1. **Updated `lib/core/auth/auth_token_store.dart`**
   - Added `_userType` static variable to store the user type
   - Added `userType` getter
   - Updated `init()` method to load user_type from SharedPreferences
   - Updated `saveUserData()` to accept and store `userType`
   - Updated `clear()` to clear user_type on logout

2. **Updated `lib/data/repositories/auth_repository.dart`**
   - Modified `login()` method to extract `user_type` from backend response
   - Now passes `userType` to `AuthTokenStore.saveUserData()`

3. **Updated `lib/pages/login_screen.dart`**
   - Added imports for `AdminScreen` and `AuthTokenStore`
   - Modified `_login()` method to check user type after successful login
   - Routes to `AdminScreen` if `user_type == "admin"`
   - Routes to `MainShellScreen` for normal users

## How to Create Admin Users

### Using Django Admin Interface
```bash
# Access Django shell
python manage.py shell

# Create an admin user
from El7a2ny_backend.models import User
from django.contrib.auth.hashers import make_password

admin_user = User.objects.create(
    name="Admin User",
    email="admin@example.com",
    phone_number="01000000000",
    password=make_password("admin_password"),
    user_type="admin",  # This is the key field
    status="active",
    verification_status="verified"
)
print(f"Admin user created: {admin_user.user_id}")
```

### Using Python Script
Create a file `create_admin.py` in your project root:

```python
import os
import django
from django.contrib.auth.hashers import make_password

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'El7a2ny_backend.settings')
django.setup()

from El7a2ny_backend.models import User

# Create admin user
admin_user = User.objects.create(
    name="System Admin",
    email="system.admin@el7a2ny.com",
    phone_number="01200000000",
    password=make_password("secure_admin_password_123"),
    user_type="admin",
    status="active",
    verification_status="verified"
)

print(f"✅ Admin user created successfully!")
print(f"Email: {admin_user.email}")
print(f"User ID: {admin_user.user_id}")
print(f"User Type: {admin_user.user_type}")
```

Then run:
```bash
python create_admin.py
```

### Via Postman or API
```
POST /users/
{
    "name": "Admin User",
    "email": "admin@el7a2ny.com",
    "phone_number": "01000000000",
    "password": "hashed_password",
    "user_type": "admin",
    "status": "active",
    "verification_status": "verified"
}
```

## Testing the Admin Login

1. **Start your backend server:**
   ```bash
   python manage.py runserver
   ```

2. **Run the Flutter app**

3. **Go to Login Screen**

4. **Enter admin credentials:**
   - Email: `admin@example.com`
   - Password: `admin_password`

5. **Expected Result:**
   - You should be automatically routed to the **AdminScreen** instead of the regular app shell

## User Type Values

The system currently supports:
- `"admin"` - Admins are routed to AdminScreen
- `"normal"` (or any other value) - Regular users are routed to MainShellScreen

## Existing AdminScreen Features

The AdminScreen (already in your codebase) includes:
- Admin statistics dashboard
- User management
- Incident analysis
- Sponsors management
- Premium subscription management

## Additional Security Considerations

For production, consider:
1. ✅ Use environment variables for admin credentials
2. ✅ Implement role-based access control (RBAC)
3. ✅ Add admin verification/approval workflow
4. ✅ Log all admin actions
5. ✅ Implement IP whitelisting for admin accounts
6. ✅ Use OAuth2/JWT for token management

## Troubleshooting

**Issue: Admin user still routes to MainShellScreen**
- Clear the app cache: `flutter clean && flutter pub get`
- Verify `user_type="admin"` is correctly set in the database
- Check backend response includes `user_type`

**Issue: AdminScreen not found error**
- Ensure `lib/pages/admin_screen.dart` exists
- Check all imports are correct in `login_screen.dart`

**Issue: SharedPreferences not saving user_type**
- Verify `shared_preferences` package is installed
- Check `pubspec.yaml` has `shared_preferences: ^2.1.0` or higher

## Next Steps

1. Create admin users using one of the methods above
2. Test login with admin credentials
3. Verify AdminScreen loads correctly
4. Implement additional admin features as needed
