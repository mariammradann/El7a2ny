# models.py
import uuid
from django.db import models
import uuid
from django.db import models
from geopy.geocoders import Nominatim

class User(models.Model):
    # الحقول الأساسية
    user_id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user_type = models.CharField(max_length=50, default='normal')
    name = models.CharField(max_length=255)
    email = models.EmailField(unique=True)
    phone_number = models.CharField(max_length=20)
    password = models.CharField(max_length=255)
    
    # البيانات الشخصية
    blood_type = models.CharField(max_length=10, null=True, blank=True)
    gender = models.CharField(max_length=10, null=True, blank=True)
    date_of_birth = models.DateField(null=True, blank=True)
    national_id = models.CharField(max_length=14, unique=True, null=True, blank=True)
    
    # حقول الـ JSON (للتسهيل في فلاتر)
    emergency_contacts = models.JSONField(default=list, null=True, blank=True)
    connected_devices = models.JSONField(default=list, null=True, blank=True)
    
    # الصلاحيات (Permissions)
    share_location = models.BooleanField(default=False)
    camera = models.BooleanField(default=False)
    mic = models.BooleanField(default=False)
    
    # حقول الحالة والتوثيق
    status = models.CharField(max_length=50, default='active')
    verification_status = models.CharField(max_length=50, default='pending')
    admin_id = models.UUIDField(null=True, blank=True) # لو يوزر تبع أدمن معين
    
    # حقول إضافية
    field = models.CharField(max_length=255, null=True, blank=True)
    external_certificates = models.JSONField(default=list, null=True, blank=True)
    
    # مسارات الصور (Strings)
    # id_card_front = models.CharField(max_length=500, null=True, blank=True)
    # id_card_back = models.CharField(max_length=500, null=True, blank=True)
    
    has_vehicle = models.BooleanField(default=False)
    volunteer_enabled = models.BooleanField(default=False)
    skills = models.TextField(null=True, blank=True)
    smart_watch_model = models.CharField(max_length=255, null=True, blank=True)
    sensor_model = models.CharField(max_length=255, null=True, blank=True)

    class Meta:
        managed = True
        db_table = 'ems_schema"."users' # تأكد من كتابتها كده عشان الـ schema

    def __str__(self):
        return self.name
    
    
    
    
    


class Location(models.Model):
    location_id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    city = models.CharField(max_length=50, null=True, blank=True)
    region = models.CharField(max_length=50, null=True, blank=True)
    address = models.TextField(null=True, blank=True)
    latitude = models.DecimalField(max_digits=10, decimal_places=8) # مطابق للصورة numeric(10,8)
    longitude = models.DecimalField(max_digits=11, decimal_places=8) # مطابق للصورة
    class Meta:
        db_table = 'ems_schema"."locations'
    def save(self, *args, **kwargs):
        # Only search if address is empty/Unknown
        if not self.address or self.address == "Unknown":
            try:
                geolocator = Nominatim(user_agent="el7a2ny_app")
                # Search for the address using coordinates
                location = geolocator.reverse(f"{self.latitude}, {self.longitude}", language='ar')
                
                if location and location.raw:
                    self.address = location.address
                    addr = location.raw.get('address', {})
                    # Try to extract city/region from the raw data
                    self.city = addr.get('city') or addr.get('town') or addr.get('village')
                    self.region = addr.get('state') or addr.get('suburb')
            except Exception as e:
                print(f"Geocoding error: {e}")
        
        super().save(*args, **kwargs)

class Incident(models.Model):
    incident_id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, db_column='user_id')
    location = models.ForeignKey(Location, on_delete=models.CASCADE, db_column='location_id')
    category = models.CharField(max_length=50)
    description = models.TextField(null=True, blank=True)
    media_files = models.JSONField(default=list, null=True, blank=True)  # Store list of file URLs/paths
    status = models.CharField(max_length=20, default='reported')
    created_at = models.DateTimeField(auto_now_add=True) 
    admin_id = models.UUIDField(null=True, blank=True)
    daleel_id = models.UUIDField(null=True, blank=True)

    class Meta:
        db_table = 'ems_schema"."incidents'
        managed = True # لو الجداول موجودة فعلياً وصحيحة

class HelpInitiative(models.Model):
    title = models.CharField(max_length=255)
    description = models.TextField()
    author_name = models.CharField(max_length=255)
    created_at = models.DateTimeField(auto_now_add=True)
    author_role = models.CharField(max_length=50, default='citizen')
    category = models.CharField(max_length=50) # food, clothing, financial, medical, education, other
    location = models.CharField(max_length=255)
    latitude = models.DecimalField(max_digits=10, decimal_places=8, null=True, blank=True)
    longitude = models.DecimalField(max_digits=11, decimal_places=8, null=True, blank=True)
    image_url = models.CharField(max_length=500, null=True, blank=True)
    contact_info = models.JSONField(default=list)
    is_active = models.BooleanField(default=True)
    participants_count = models.IntegerField(default=0)

    class Meta:
        db_table = 'ems_schema"."initiatives'
        managed = True

    def __str__(self):
        return self.title

