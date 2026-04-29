from rest_framework import serializers
from django.contrib.auth.hashers import make_password
from .models import User, Incident, Location, Initiative

# 1. Serializer الخاص بالموقع
class LocationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Location
        # تأكد إن دي الحقول اللي الـ Flutter بيبعتها جوه الـ location_data
        fields = ['latitude', 'longitude', 'address', 'city', 'region']
        extra_kwargs = {
            'address': {'read_only': True},
            'city': {'read_only': True},
            'region': {'read_only': True},
        }

# 2. Serializer الخاص بالبلاغات (SOS)
class IncidentSerializer(serializers.ModelSerializer):
    # السطر ده هو اللي بيربط الـ Object اللي جاي من Flutter
    address = serializers.ReadOnlyField(source='location.address')
    location_data = LocationSerializer(write_only=True)
    lat = serializers.ReadOnlyField(source='location.latitude', default=0.0)
    lng = serializers.ReadOnlyField(source='location.longitude', default=0.0)
    media_files = serializers.JSONField(required=False, allow_null=True)
    
    # تأكد إن اليوزر بيتقري كـ UUID بشكل سليم
    user = serializers.PrimaryKeyRelatedField(queryset=User.objects.all())

    class Meta:
        model = Incident
        # ضفنا كل الأعمدة الـ 10 عشان الـ Serializer يشوفهم
        fields = [
            'incident_id', 'user', 'location_data', 'category', 
            'description', 'media_files', 'status', 'created_at', 
            'admin_id', 'daleel_id','lat',  
            'lng','address',
        ]
        # جعل بعض الحقول اختيارية عشان متعملش Bad Request لو متبعتتش
        extra_kwargs = {
            'media_files': {'required': False, 'allow_null': True},
            'admin_id': {'required': False, 'allow_null': True},
            'daleel_id': {'required': False, 'allow_null': True},
            'description': {'required': False, 'allow_null': True},
        }

    def create(self, validated_data):
        location_payload = validated_data.pop('location_data')
        # 1. إنشاء الموقع
        new_location = Location.objects.create(**location_payload)
        # 2. إنشاء البلاغ وربطه بالموقع
        incident = Incident.objects.create(location=new_location, **validated_data)
        return incident

# 3. Serializer الخاص بتسجيل اليوزر
class UserRegistrationSerializer(serializers.ModelSerializer):
    first_name = serializers.CharField(write_only=True, required=False, allow_blank=True)
    last_name = serializers.CharField(write_only=True, required=False, allow_blank=True)
    

    class Meta:
        model = User
        fields = '__all__'
        # 🚨 ضيف السطر ده عشان تضمن إن الحقول دي ما توقفش التسجيل
        extra_kwargs = {
            'name': {'required': False, 'allow_null': True},
            'password': {'write_only': True},
            'user_id': {'read_only': True},
            'admin_id': {'required': False, 'allow_null': True},
            'emergency_contacts': {'required': False},
            'connected_devices': {'required': False},
            'external_certificates': {'required': False},
            'field': {'required': False, 'allow_null': True},
        }

    def validate_email(self, value):
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError("This email is already in use by another user.")
        return value

    def validate_phone_number(self, value):
        if User.objects.filter(phone_number=value).exists():
            raise serializers.ValidationError("This phone number is already registered.")
        return value

    def create(self, validated_data):
        print("Hi2")
        fname = validated_data.pop('first_name', '')
        lname = validated_data.pop('last_name', '')
        validated_data['name'] = f"{fname} {lname}".strip()
        
        if 'password' in validated_data:
            validated_data['password'] = make_password(validated_data['password'])
            
        return User.objects.create(**validated_data)

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = '__all__'

class InitiativeSerializer(serializers.ModelSerializer):
    class Meta:
        model = Initiative
        fields = '__all__'