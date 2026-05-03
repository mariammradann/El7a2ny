from rest_framework import serializers
from django.contrib.auth.hashers import make_password
from .models import User, Incident, Location, Initiative, HelpInitiative, PasswordResetToken


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


# 2. Serializer الخاص بالبلاغات (SOS)
class IncidentSerializer(serializers.ModelSerializer):
    # This is for incoming data from Flutter
    location_data = LocationSerializer(write_only=True)

    # These are for outgoing data (response)
    address = serializers.ReadOnlyField(source="location.address")
    lat = serializers.ReadOnlyField(source="location.latitude")
    lng = serializers.ReadOnlyField(source="location.longitude")

    # media_files is a JSONField in your model, so this works perfectly
    media_files = serializers.JSONField(required=False, allow_null=True)
    user = serializers.PrimaryKeyRelatedField(queryset=User.objects.all())

    class Meta:
        model = Incident
        fields = [
            "incident_id",
            "user",
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
        queryset=User.objects.all(), source='user', required=False, allow_null=True
    )

    class Meta:
        model = Initiative
        fields = [
            'id', 'user_id', 'title', 'description', 'author_name', 
            'author_role', 'category', 'location', 'latitude', 
            'longitude', 'image_url', 'contact_info', 'is_active', 
            'participants_count', 'created_at'
        ]
