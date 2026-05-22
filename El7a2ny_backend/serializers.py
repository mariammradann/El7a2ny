from rest_framework import serializers
from django.contrib.auth.hashers import make_password
from .models import (
    Responder,
    User,
    Incident,
    Location,
    Initiative,
    HelpInitiative,
    PasswordResetToken,
    IncidentChat,
    ChatMessage,
    IncidentAIAnalysis,
)


# 1. Serializer الخاص بالموقع
class LocationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Location
        # تأكد إن دي الحقول اللي الـ Flutter بيبعتها جوه الـ location_data
        fields = ["latitude", "longitude", "address", "city", "region"]
        extra_kwargs = {
            "address": {"read_only": True},
            "city": {"read_only": True},
            "region": {"read_only": True},
        }


# ═══════════════════════════════════════════════════════════════════════════════
# ═══════════════════ AI ANALYSIS SERIALIZERS ═══════════════════════════════════
# ═══════════════════════════════════════════════════════════════════════════════

class IncidentAIAnalysisSerializer(serializers.ModelSerializer):
    """
    Full serializer for IncidentAIAnalysis.
    Returned after analysis completes.
    """
    alert_level  = serializers.ReadOnlyField()
    triage_color = serializers.ReadOnlyField()

    class Meta:
        model  = IncidentAIAnalysis
        fields = [
            "analysis_id",
            "incident_id",
            "incident_type",
            "severity",
            "triage_level",
            "triage_color",
            "urgency_score",
            "alert_level",
            "risk_level",
            "dispatch_priority",
            "summary",
            "responder_briefing",
            "instructions",
            "responders_needed",
            "confidence",
            "source",
            "analyzed_at",
        ]


class IncidentAIAnalysisSummarySerializer(serializers.ModelSerializer):
    """
    Lightweight serializer — used when embedding analysis inside an Incident response.
    Excludes raw_response and heavy fields.
    """
    alert_level  = serializers.ReadOnlyField()
    triage_color = serializers.ReadOnlyField()

    class Meta:
        model  = IncidentAIAnalysis
        fields = [
            "incident_type",
            "severity",
            "triage_level",
            "triage_color",
            "urgency_score",
            "alert_level",
            "summary",
            "instructions",
            "responders_needed",
            "analyzed_at",
        ]


# 2. Serializer الخاص بالبلاغات (SOS)
class IncidentSerializer(serializers.ModelSerializer):
    # This is for incoming data from Flutter
    location_data = LocationSerializer(write_only=True)

    # These are for outgoing data (response)
    address = serializers.ReadOnlyField(source="location.address")
    lat = serializers.ReadOnlyField(source="location.latitude")
    lng = serializers.ReadOnlyField(source="location.longitude")
    reporter_name = serializers.ReadOnlyField(source="user.name")
    ai_analysis = IncidentAIAnalysisSerializer(read_only=True, allow_null=True)

    # media_files is a JSONField in your model, so this works perfectly
    media_files = serializers.JSONField(required=False, allow_null=True)
    user = serializers.PrimaryKeyRelatedField(queryset=User.objects.all())

    class Meta:
        model = Incident
        fields = [
            "incident_id",
            "user",
            "reporter_name",
            "location_data",
            "category",
            "description",
            "media_files",
            "status",
            "created_at",
            "admin_id",
            "daleel_id",
            "lat",
            "lng",
            "address",
            "current_volunteers",
            "total_volunteers",
            "ai_analysis",
            # "device_id",
        ]

    def create(self, validated_data):
        # 1. Pop 'location_data' so it doesn't go into the Incident constructor
        location_payload = validated_data.pop("location_data")

        # 2. Create the Location object first
        # This triggers your Nominatim geocoding logic in models.py
        new_location = Location.objects.create(**location_payload)

        # 3. Now validated_data only contains valid Incident fields
        # (user, category, description, media_files, etc.)
        incident = Incident.objects.create(location=new_location, **validated_data)
        return incident


# 3. Serializer الخاص بتسجيل اليوزر
class UserRegistrationSerializer(serializers.ModelSerializer):
    first_name = serializers.CharField(
        write_only=True, required=False, allow_blank=True
    )
    last_name = serializers.CharField(write_only=True, required=False, allow_blank=True)

    class Meta:
        model = User
        fields = "__all__"
        # 🚨 ضيف السطر ده عشان تضمن إن الحقول دي ما توقفش التسجيل
        extra_kwargs = {
            "name": {"required": False, "allow_null": True},
            "password": {"write_only": True},
            "user_id": {"read_only": True},
            "admin_id": {"required": False, "allow_null": True},
            "emergency_contacts": {"required": False},
            "connected_devices": {"required": False},
            "external_certificates": {"required": False},
            "field": {"required": False, "allow_null": True},
        }

    def validate_email(self, value):
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError(
                "This email is already in use by another user."
            )
        return value

    def validate_phone_number(self, value):
        if User.objects.filter(phone_number=value).exists():
            raise serializers.ValidationError(
                "This phone number is already registered."
            )
        return value

    def create(self, validated_data):
        print("Hi2")
        fname = validated_data.pop("first_name", "")
        lname = validated_data.pop("last_name", "")
        validated_data["name"] = f"{fname} {lname}".strip()

        if "password" in validated_data:
            validated_data["password"] = make_password(validated_data["password"])

        return User.objects.create(**validated_data)


# 4. Password Reset Serializers
class PasswordResetRequestSerializer(serializers.Serializer):
    """Serializer for requesting a password reset"""

    email = serializers.EmailField()

    def validate_email(self, value):
        try:
            User.objects.get(email=value)
        except User.DoesNotExist:
            raise serializers.ValidationError("No user found with this email address.")
        return value


class PasswordResetVerifyTokenSerializer(serializers.Serializer):
    """Serializer for verifying password reset token"""

    email = serializers.EmailField()
    token = serializers.CharField()


class PasswordResetConfirmSerializer(serializers.Serializer):
    """Serializer for confirming password reset with new password"""

    email = serializers.EmailField()
    token = serializers.CharField()
    new_password = serializers.CharField(write_only=True, min_length=8)
    new_password_confirm = serializers.CharField(write_only=True, min_length=8)

    def validate(self, data):
        if data["new_password"] != data["new_password_confirm"]:
            raise serializers.ValidationError("Passwords do not match.")
        return data


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = "__all__"


class HelpInitiativeSerializer(serializers.ModelSerializer):
    class Meta:
        model = HelpInitiative
        fields = "__all__"


class InitiativeSerializer(serializers.ModelSerializer):
    user_id = serializers.PrimaryKeyRelatedField(
        queryset=User.objects.all(), source="user", required=False, allow_null=True
    )

    class Meta:
        model = Initiative
        fields = [
            "id",
            "user_id",
            "title",
            "description",
            "author_name",
            "author_role",
            "category",
            "location",
            "latitude",
            "longitude",
            "image_url",
            "contact_info",
            "is_active",
            "participants_count",
            "created_at",
        ]


from .models import UserRating, VolunteerRating


class UserRatingSerializer(serializers.ModelSerializer):
    user_id = serializers.PrimaryKeyRelatedField(
        queryset=User.objects.all(), source="user", required=False, allow_null=True
    )

    class Meta:
        model = UserRating
        fields = "__all__"


class VolunteerRatingSerializer(serializers.ModelSerializer):
    user_id = serializers.PrimaryKeyRelatedField(
        queryset=User.objects.all(), source="user", required=False, allow_null=True
    )

    class Meta:
        model = VolunteerRating
        fields = "__all__"


class ResponderSerializer(serializers.ModelSerializer):
    class Meta:
        model = Responder
        fields = [
            "responder_id",
            "incident_id",
            "user_id",
            "response_time",
            "lat",
            "lng",
            "last_location_updated",
        ]
        read_only_fields = ["responder_id"]

    def create(self, validated_data):
        return Responder.objects.create(**validated_data)


# Chat Serializers
class ChatMessageSerializer(serializers.ModelSerializer):
    class Meta:
        model = ChatMessage
        fields = [
            "message_id",
            "sender_id",
            "sender_name",
            "sender_type",
            "text",
            "created_at",
        ]
        read_only_fields = ["message_id", "created_at"]


class IncidentChatSerializer(serializers.ModelSerializer):
    messages = ChatMessageSerializer(many=True, read_only=True)

    class Meta:
        model = IncidentChat
        fields = ["chat_id", "incident_id", "messages", "created_at", "updated_at"]
        read_only_fields = ["chat_id", "created_at", "updated_at"]



class AnalyzeImageRequestSerializer(serializers.Serializer):
    """Validates incoming Flutter image-analysis requests."""
    incident_id = serializers.UUIDField()
    image       = serializers.ImageField()


class AnalyzeVideoRequestSerializer(serializers.Serializer):
    incident_id = serializers.UUIDField()
    video       = serializers.FileField()


class AnalyzeVoiceRequestSerializer(serializers.Serializer):
    incident_id = serializers.UUIDField()
    audio       = serializers.FileField()


class AnalyzeTextRequestSerializer(serializers.Serializer):
    incident_id = serializers.UUIDField()
    description = serializers.CharField(min_length=5)
    location    = serializers.CharField(required=False, allow_blank=True)
