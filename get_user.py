import os

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "El7a2ny_backend.settings")
import django

django.setup()
from El7a2ny_backend.models import User

users = User.objects.all()[:1]
if users:
    user = users[0]
    print(f"User ID: {user.user_id}")
    print(f"Name: {user.name}")
    print(f"Email: {user.email}")
else:
    print("No users found in database")
