from rest_framework import serializers
from django.contrib.auth.hashers import make_password
from .models import User, Incident, Location

# 1. Serializer الخاص بالموقع
class LocationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Location
        # تأكد إن دي الحقول اللي الـ Flutter بيبعتها جوه الـ location_data
        fields = ['latitude', 'longitude', 'address', 'city', 'region']

# 2. Serializer الخاص بالبلاغات (SOS)
class IncidentSerializer(serializers.ModelSerializer):
    # السطر ده هو اللي بيربط الـ Object اللي جاي من Flutter
    location_data = LocationSerializer(write_only=True)
    
    # تأكد إن اليوزر بيتقري كـ UUID بشكل سليم
    user = serializers.PrimaryKeyRelatedField(queryset=User.objects.all())

    class Meta:
        model = Incident
        # ضفنا كل الأعمدة الـ 10 عشان الـ Serializer يشوفهم
        fields = [
            'incident_id', 'user', 'location_data', 'category', 
            'description', 'media', 'status', 'created_at', 
            'admin_id', 'daleel_id'
        ]
        # جعل بعض الحقول اختيارية عشان متعملش Bad Request لو متبعتتش
        extra_kwargs = {
            'media': {'required': False, 'allow_null': True},
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
    first_name = serializers.CharField(write_only=True)
    last_name = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = '__all__'
        extra_kwargs = {
            'name': {'required': False},
            'password': {'write_only': True}
        }

    def create(self, validated_data):
        fname = validated_data.pop('first_name', '')
        lname = validated_data.pop('last_name', '')
        validated_data['name'] = f"{fname} {lname}".strip()
        # تشفير الباسورد قبل الحفظ
        validated_data['password'] = make_password(validated_data['password'])
        return super().create(validated_data)

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = '__all__'