# models.py
import uuid
from django.db import models
from django.utils import timezone
from datetime import timedelta
from geopy.geocoders import Nominatim


class User(models.Model):
    # الحقول الأساسية
    user_id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user_type = models.CharField(max_length=50, default="normal")
    trust_score = models.FloatField(default=1.0)
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
    status = models.CharField(max_length=50, default="active")
    verification_status = models.CharField(max_length=50, default="pending")
    banned_until = models.DateTimeField(null=True, blank=True)
    admin_id = models.UUIDField(null=True, blank=True)  # لو يوزر تبع أدمن معين

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

    # Subscription fields
    is_plus = models.BooleanField(default=False)
    plan_type = models.CharField(
        max_length=20,
        choices=[("monthly", "Monthly"), ("yearly", "Yearly")],
        null=True,
        blank=True,
    )  # 'monthly' or 'yearly'
    subscription_date = models.DateTimeField(null=True, blank=True)
    renewal_date = models.DateTimeField(null=True, blank=True)

    class Meta:
        managed = True
        db_table = 'ems_schema"."users'  # تأكد من كتابتها كده عشان الـ schema

    def __str__(self):
        return self.name


class Location(models.Model):
    location_id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    city = models.CharField(max_length=50, null=True, blank=True)
    region = models.CharField(max_length=50, null=True, blank=True)
    address = models.TextField(null=True, blank=True)
    latitude = models.DecimalField(
        max_digits=10, decimal_places=8
    )  # مطابق للصورة numeric(10,8)
    longitude = models.DecimalField(max_digits=11, decimal_places=8)  # مطابق للصورة

    class Meta:
        db_table = 'ems_schema"."locations'

    def save(self, *args, **kwargs):
        # Only search if address is empty/Unknown
        if not self.address or self.address == "Unknown":
            try:
                geolocator = Nominatim(user_agent="el7a2ny_app")
                # Search for the address using coordinates
                location = geolocator.reverse(
                    f"{self.latitude}, {self.longitude}", language="ar"
                )

                if location and location.raw:
                    self.address = location.address
                    addr = location.raw.get("address", {})
                    # Try to extract city/region from the raw data
                    self.city = (
                        addr.get("city") or addr.get("town") or addr.get("village")
                    )
                    self.region = addr.get("state") or addr.get("suburb")
            except Exception as e:
                print(f"Geocoding error: {e}")

        super().save(*args, **kwargs)


class Incident(models.Model):
    incident_id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, db_column="user_id")
    location = models.ForeignKey(
        Location, on_delete=models.CASCADE, db_column="location_id"
    )
    category = models.CharField(max_length=50)
    description = models.TextField(null=True, blank=True)
    media_files = models.JSONField(
        default=list, null=True, blank=True
    )  # Store list of file URLs/paths
    status = models.CharField(max_length=20, default="reported")
    created_at = models.DateTimeField(auto_now_add=True)
    admin_id = models.UUIDField(null=True, blank=True)
    daleel_id = models.UUIDField(null=True, blank=True)
    current_volunteers = models.IntegerField(default=0)
    total_volunteers = models.IntegerField(default=0)

    class Meta:
        db_table = 'ems_schema"."incidents'
        managed = True  # لو الجداول موجودة فعلياً وصحيحة


class HelpInitiative(models.Model):
    title = models.CharField(max_length=255)
    description = models.TextField()
    author_name = models.CharField(max_length=255)
    created_at = models.DateTimeField(auto_now_add=True)
    author_role = models.CharField(max_length=50, default="citizen")
    category = models.CharField(
        max_length=50
    )  # food, clothing, financial, medical, education, other

    class Meta:
        db_table = 'ems_schema"."help_initiatives'
        managed = True

    def __str__(self):
        return self.title


class Initiative(models.Model):
    id = models.AutoField(primary_key=True)
    user = models.ForeignKey(
        User, on_delete=models.CASCADE, db_column="user_id", null=True, blank=True
    )
    title = models.CharField(max_length=255)
    description = models.TextField()
    author_name = models.CharField(max_length=255)
    author_role = models.CharField(max_length=50, default="citizen")
    category = models.CharField(max_length=50)  # food, clothing, etc.
    location = models.CharField(max_length=255)
    latitude = models.DecimalField(
        max_digits=10, decimal_places=8, null=True, blank=True
    )
    longitude = models.DecimalField(
        max_digits=11, decimal_places=8, null=True, blank=True
    )
    image_url = models.CharField(max_length=500, null=True, blank=True)
    contact_info = models.JSONField(default=list)
    is_active = models.BooleanField(default=True)
    participants_count = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'ems_schema"."initiatives'
        managed = True


class PasswordResetToken(models.Model):
    """Model to store password reset tokens for users"""

    token_id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name="password_reset_tokens"
    )
    token = models.CharField(max_length=100, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    is_used = models.BooleanField(default=False)

    class Meta:
        db_table = 'ems_schema"."password_reset_tokens'
        managed = True

    def is_valid(self):
        """Check if token is valid (not expired and not used)"""
        return not self.is_used and timezone.now() <= self.expires_at

    def mark_as_used(self):
        """Mark token as used"""
        self.is_used = True
        self.save()


class SensorReading(models.Model):
    ALERT_LEVELS = [
        ("NORMAL", "🟢 NORMAL"),
        ("WARNING", "⚠️ WARNING"),
        ("ALERT", "🚨 ALERT"),
        ("CRITICAL", "🔥 CRITICAL"),
    ]

    user = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name="sensor_readings"
    )
    temperature = models.FloatField()
    humidity = models.FloatField(null=True, blank=True)
    is_alert = models.BooleanField(default=False)
    alert_level = models.CharField(
        max_length=20,
        choices=ALERT_LEVELS,
        default="NORMAL",
        help_text="Temperature alert level: NORMAL (<40°C), WARNING (40-70°C), ALERT (70-120°C), CRITICAL (≥120°C)",
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'ems_schema"."sensor_readings'
        managed = True
        ordering = ["-created_at"]


class UserRating(models.Model):
    user = models.ForeignKey(
        User,
        related_name="user_ratings",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
    )
    app_rating = models.FloatField(default=0.0)
    police_rating = models.FloatField(default=0.0)
    ambulance_rating = models.FloatField(default=0.0)
    fire_dept_rating = models.FloatField(default=0.0)
    el7a2ny_plus_rating = models.FloatField(default=0.0)
    volunteers_helpful = models.BooleanField(null=True, blank=True)
    report_fake = models.BooleanField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'ems_schema"."user_ratings'
        managed = True
        ordering = ["-created_at"]


class VolunteerRating(models.Model):
    user = models.ForeignKey(
        User,
        related_name="volunteer_ratings",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
    )
    is_real_report = models.BooleanField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'ems_schema"."volunteer_ratings'
        managed = True
        ordering = ["-created_at"]


import uuid
from django.db import models


class Responder(models.Model):
    # Primary Key from image
    responder_id = models.UUIDField(
        primary_key=True, default=uuid.uuid4, editable=False
    )

    # Foreign Key / Reference fields from image
    incident_id = models.UUIDField()
    user_id = models.UUIDField()

    # Interval type from image (maps to DurationField)
    response_time = models.DurationField(null=True, blank=True)

    # New Location fields
    lat = models.FloatField(null=True, blank=True)
    lng = models.FloatField(null=True, blank=True)
    last_location_updated = models.DateTimeField(null=True, blank=True)

    class Meta:
        # We use just the table name here.
        # Ensure your search_path is set to 'ems_schema' in settings.py
        db_table = "responders"
        managed = True

    def __str__(self):
        return f"Responder {self.responder_id} (User: {self.user_id})"


class IncidentChat(models.Model):
    """Model for incident chat threads"""

    chat_id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    incident_id = models.UUIDField(
        db_index=True
    )  # Reference to incident without foreign key for flexibility
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "incident_chats"
        managed = True
        indexes = [
            models.Index(fields=["incident_id", "-updated_at"]),
        ]

    def __str__(self):
        return f"Chat for Incident {self.incident_id}"


class ChatMessage(models.Model):
    """Model for individual chat messages in an incident chat"""

    SENDER_TYPES = [
        ("user", "Report User"),
        ("volunteer", "Volunteer"),
        ("admin", "Admin"),
        ("system", "System"),
    ]

    message_id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    chat = models.ForeignKey(
        IncidentChat,
        on_delete=models.CASCADE,
        related_name="messages",
        db_column="chat_id",
    )
    sender_id = models.UUIDField()  # ID of the user sending the message
    sender_name = models.CharField(max_length=255)  # Cached sender name for display
    sender_type = models.CharField(
        max_length=20, choices=SENDER_TYPES
    )  # user, volunteer, admin, system
    text = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        db_table = "chat_messages"
        managed = True
        ordering = ["created_at"]
        indexes = [
            models.Index(fields=["chat", "-created_at"]),
        ]

    def __str__(self):
        return f"Message from {self.sender_name} in Chat {self.chat_id}"


class IncidentAIAnalysis(models.Model):
    """
    Stores the AI microservice result for a given Incident.
    One-to-one with Incident — one analysis per incident.
    """

    SEVERITY_CHOICES = [
        ("Critical", "Critical"),
        ("High", "High"),
        ("Medium", "Medium"),
        ("Low", "Low"),
        ("Unknown", "Unknown"),
    ]

    TRIAGE_CHOICES = [
        ("Red", "Red"),
        ("Orange", "Orange"),
        ("Yellow", "Yellow"),
        ("Green", "Green"),
        ("Black", "Black"),
    ]

    SOURCE_CHOICES = [
        ("image", "Image"),
        ("video", "Video"),
        ("voice", "Voice"),
        ("text", "Text"),
    ]

    analysis_id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    # Link to the existing Incident model
    incident = models.OneToOneField(
        Incident,
        on_delete=models.CASCADE,
        related_name="ai_analysis",
        db_column="incident_id",
    )

    # ── Core AI output fields ─────────────────────────────────────────────────
    incident_type = models.CharField(max_length=255)
    severity = models.CharField(
        max_length=20, choices=SEVERITY_CHOICES, default="Unknown"
    )
    triage_level = models.CharField(
        max_length=10, choices=TRIAGE_CHOICES, default="Yellow"
    )
    urgency_score = models.IntegerField(default=5)  # 1–10
    risk_level = models.CharField(max_length=255, null=True, blank=True)
    dispatch_priority = models.CharField(max_length=255, null=True, blank=True)

    # ── Authenticity & Verification ──
    is_real = models.BooleanField(default=True)
    fake_probability = models.FloatField(default=0.0)
    verification_methods = models.JSONField(default=dict, null=True, blank=True)
    community_votes_real = models.IntegerField(default=0)
    community_votes_fake = models.IntegerField(default=0)

    # ── YOLOv8 Detections ──
    raw_detections = models.JSONField(default=list, null=True, blank=True)
    detected_objects = models.JSONField(default=dict, null=True, blank=True)

    # ── Text outputs ──────────────────────────────────────────────────────────
    summary = models.TextField(null=True, blank=True)
    responder_briefing = models.TextField(null=True, blank=True)
    summary_en = models.TextField(null=True, blank=True)
    summary_ar = models.TextField(null=True, blank=True)

    # ── JSON arrays ───────────────────────────────────────────────────────────
    instructions      = models.JSONField(default=list)   # ["Evacuate", "Stay low", ...]
    responders_needed = models.JSONField(default=list)   # ["Firefighters", "Ambulance"]
    user_instructions_en = models.JSONField(default=list, null=True, blank=True)
    user_instructions_ar = models.JSONField(default=list, null=True, blank=True)
    volunteer_instructions_en = models.JSONField(default=list, null=True, blank=True)
    volunteer_instructions_ar = models.JSONField(default=list, null=True, blank=True)

    # ── Volunteer Recommendations ──
    volunteers_recommended = models.JSONField(default=dict, null=True, blank=True)

    # ── Metadata ──────────────────────────────────────────────────────────────
    confidence = models.FloatField(null=True, blank=True)  # 0.0 – 1.0
    source = models.CharField(
        max_length=10, choices=SOURCE_CHOICES, null=True, blank=True
    )
    raw_response = models.JSONField(
        null=True, blank=True
    )  # full AI JSON stored for debugging
    analyzed_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'ems_schema"."incident_ai_analyses'
        managed = True
        # ordering = ["-analyzed_at"]

    def __str__(self):
        return f"AI Analysis for Incident {self.incident_id} — {self.severity}"

    # ── Convenience properties for Flutter ───────────────────────────────────
    @property
    def alert_level(self) -> str:
        if self.urgency_score >= 9:
            return "CRITICAL ALERT"
        elif self.urgency_score >= 7:
            return "HIGH ALERT"
        elif self.urgency_score >= 4:
            return "MODERATE ALERT"
        return "LOW ALERT"

    @property
    def triage_color(self) -> str:
        colors = {
            "Red": "#FF0000",
            "Orange": "#FF6600",
            "Yellow": "#FFD700",
            "Green": "#00AA00",
            "Black": "#222222",
        }
        return colors.get(self.triage_level, "#888888")


class SponsorRequest(models.Model):
    request_id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    company_name = models.CharField(max_length=255)
    contact_person = models.CharField(max_length=255)
    phone_number = models.CharField(max_length=20)
    message = models.TextField()
    status = models.CharField(
        max_length=20,
        choices=[
            ("pending", "Pending"),
            ("approved", "Approved"),
            ("rejected", "Rejected"),
        ],
        default="pending",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="sponsor_requests",
        null=True,
        blank=True,
    )

    class Meta:
        db_table = 'ems_schema"."sponsor_requests'
        ordering = ["-created_at"]
        managed = True

    def __str__(self):
        return f"SponsorRequest {self.request_id} - {self.company_name} ({self.status})"


class VolunteerProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="volunteer_profile")
    is_online = models.BooleanField(default=False)
    current_lat = models.FloatField(null=True, blank=True)
    current_lng = models.FloatField(null=True, blank=True)
    
    # Skills and Credentials
    has_first_aid = models.BooleanField(default=False)
    has_firefighting = models.BooleanField(default=False)
    has_rescue_training = models.BooleanField(default=False)
    has_transportation = models.BooleanField(default=False)
    
    class Meta:
        db_table = 'ems_schema"."volunteer_profiles'
        managed = True

    def __str__(self):
        return f"Volunteer Profile: {self.user.name}"


class IncidentDispatch(models.Model):
    dispatch_id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    incident = models.ForeignKey(Incident, on_delete=models.CASCADE, related_name="dispatches")
    volunteer = models.ForeignKey(User, on_delete=models.CASCADE, related_name="assigned_dispatches")
    role_requested = models.CharField(max_length=50) # 'first_aid', 'fire_response', etc.
    status = models.CharField(max_length=20, choices=[
        ("pending", "Pending"), 
        ("accepted", "Accepted"), 
        ("declined", "Declined"), 
        ("completed", "Completed")
    ], default="pending")
    dispatched_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'ems_schema"."incident_dispatches'
        managed = True

    def __str__(self):
        return f"Dispatch {self.dispatch_id} of {self.role_requested} to Incident {self.incident_id}"


class AdminLog(models.Model):
    log_id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    action = models.CharField(max_length=500)
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'ems_schema"."admin_logs'
        ordering = ["-timestamp"]
        managed = True

    def __str__(self):
        return f"AdminLog {self.log_id} - {self.action}"
