import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'El7a2ny_backend.settings')
django.setup()

from El7a2ny_backend.models import Initiative

try:
    count = Initiative.objects.count()
    print(f"Total Initiatives: {count}")
    for init in Initiative.objects.all()[:5]:
        print(f"- {init.title} by {init.author_name} at {init.created_at}")
except Exception as e:
    print(f"Error: {e}")
