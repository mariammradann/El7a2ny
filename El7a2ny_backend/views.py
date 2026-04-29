from rest_framework import viewsets, status, serializers, permissions
from rest_framework.decorators import action, api_view
from rest_framework.response import Response
from django.db.models import Q
from django.contrib.auth.hashers import check_password
from .models import User, Incident
import google.generativeai as genai
from .serializers import UserRegistrationSerializer, IncidentSerializer

# Configure Gemini - REPLACE WITH YOUR FRESH API KEY
genai.configure(api_key="AIzaSyDca6bIEtgJT8CUZZR9XPKSaHdSe0pKq7E")

@api_view(['POST'])
def get_first_aid_advice(request):
    user_message = request.data.get('message')
    if not user_message:
        return Response({'reply': 'Please provide a message.'}, status=400)
        
    try:
        model = genai.GenerativeModel('gemini-2.5-flash')
        prompt = f"As a first aid expert, give short and clear advice in the user's language for: {user_message}"
        response = model.generate_content(prompt)
        return Response({'reply': response.text})
    except Exception as e:
        print(f"AI Error: {e}")
        return Response({'reply': 'Sorry, I am having trouble connecting to my brain right now.'}, status=500)

# 1. الـ Serializer الخاص باليوزر
class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = '__all__'

# 2. الـ UserViewSet
class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer

    # تم إضافة methods=['post'] و url_path لضمان الربط مع Postman
    @action(detail=False, methods=['post'], url_path='check_user')
    def check_user(self, request):
        email = request.data.get('email')
        password = request.data.get('password')

        if not email or not password:
            return Response(
                {"error": "Please provide both email and password"}, 
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            # بنجيب اليوزر بالإيميل
            user = User.objects.get(email=email)
            
            # مقارنة الباسورد (تأكد إنها متخزنة Hash في الداتا بيز)
            if check_password(password, user.password):
                return Response({
                    "message": "Login successful",
                    "email": user.email,
                    "user_id": user.user_id,
                    "name": user.name
                }, status=status.HTTP_200_OK)
            else:
                return Response(
                    {"error": "الباسورد غلط يصاحبي"}, 
                    status=status.HTTP_401_UNAUTHORIZED
                )

        except User.DoesNotExist:
            return Response(
                {"error": "الاكونت ده مش موجود"}, 
                status=status.HTTP_404_NOT_FOUND
            )

    @action(detail=True, methods=['get'])
    def profile_by_id(self, request, user_id=None):
        try:
            user = User.objects.get(user_id=user_id)
            serializer = UserSerializer(user)
            return Response(serializer.data)
        except User.DoesNotExist:
            return Response({"error": "User not found"}, status=status.HTTP_404_NOT_FOUND)

    @action(detail=False, methods=['put'])
    def update_profile(self, request):
        user_id = request.data.get('user_id')
        if not user_id:
            return Response({"error": "user_id is required"}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            user = User.objects.get(user_id=user_id)
        except User.DoesNotExist:
            return Response({"error": "User not found"}, status=status.HTTP_404_NOT_FOUND)
            
        serializer = UserSerializer(user, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

# 3. الـ IncidentViewSet
class IncidentViewSet(viewsets.ModelViewSet):
    def get_queryset(self):
        # This function runs on EVERY request, ensuring data is fresh
        queryset = Incident.objects.all().order_by('-created_at')
        
        user_id = self.request.query_params.get('user_id')
        if user_id:
            queryset = queryset.filter(user_id=user_id)
            
        return queryset
    serializer_class = IncidentSerializer
    permission_classes = [permissions.AllowAny]

    def create(self, request, *args, **kwargs):
        from django.core.files.storage import default_storage
        from django.core.files.base import ContentFile
        import os
        import json

        # Normalize QueryDict values: flatten single-item lists to strings
        data = {}
        try:
            for key in request.data.keys():
                values = request.data.getlist(key)
                if len(values) == 1:
                    v = values[0]
                    if isinstance(v, bytes):
                        try:
                            v = v.decode()
                        except Exception:
                            pass
                    data[key] = v
                else:
                    data[key] = values
        except Exception:
            # Fallback
            if hasattr(request.data, 'dict'):
                data = dict(request.data)
            else:
                data = request.data.copy()

        print(f"📦 Received data keys: {list(data.keys())}")
        print(f"📦 Received files: {list(request.FILES.keys())}")
        print(f"📦 Raw normalized data: {data}")

        # user_id -> user
        if 'user_id' in data:
            user_id = data.pop('user_id')
            if isinstance(user_id, list) and user_id:
                user_id = user_id[0]
            data['user'] = user_id

        # Handle file uploads
        media_files_urls = []
        if 'media_files' in request.FILES:
            files = request.FILES.getlist('media_files')
            print(f"📦 Processing {len(files)} files")
            for file in files:
                try:
                    filename = f"reports/{data.get('user', 'unknown')}/{file.name}"
                    path = default_storage.save(filename, ContentFile(file.read()))
                    media_files_urls.append(f"/media/{path}")
                    print(f"✅ File saved: {path}")
                except Exception as e:
                    print(f"⚠️ Error saving file: {e}")
        else:
            print("⚠️ No media_files in request.FILES")

        # Parse coordinates (may be strings)
        lat_raw = data.pop('latitude', None)
        lng_raw = data.pop('longitude', None)
        if isinstance(lat_raw, list) and lat_raw:
            lat_raw = lat_raw[0]
        if isinstance(lng_raw, list) and lng_raw:
            lng_raw = lng_raw[0]

        if lat_raw is not None and lng_raw is not None:
            try:
                lat = round(float(lat_raw), 8)
                lng = round(float(lng_raw), 8)
                # ensure address is a string
                addr = data.get('address', None)
                if isinstance(addr, list) and addr:
                    addr = addr[0]
                data['location_data'] = {
                    'latitude': lat,
                    'longitude': lng,
                    'city': data.get('city', 'Unknown'),
                    'region': data.get('region', 'Unknown'),
                    'address': addr or 'Current Location',
                }
                print(f"✅ Coordinates parsed: lat={lat}, lng={lng}")
            except (ValueError, TypeError) as e:
                print(f"❌ Error parsing coordinates: {e} (lat={lat_raw}, lng={lng_raw})")
                return Response({"error": f"Invalid coordinates: {e}"}, status=status.HTTP_400_BAD_REQUEST)
        else:
            print(f"⚠️ Missing coordinates: lat={lat_raw}, lng={lng_raw}")

        # Flatten other string fields that may be lists
        if isinstance(data.get('category'), list) and data['category']:
            data['category'] = data['category'][0]
        if isinstance(data.get('description'), list) and data['description']:
            data['description'] = data['description'][0]
        if isinstance(data.get('address'), list) and data['address']:
            data['address'] = data['address'][0]

        data['media_files'] = media_files_urls

        print(f"📤 Sending to serializer: {data}")

        serializer = self.get_serializer(data=data)
        if not serializer.is_valid():
            print("🚨 Final Serializer Errors:", serializer.errors)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        self.perform_create(serializer)
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    
    def perform_create(self, serializer):
        # This will trigger the Location.save() logic automatically
        serializer.save()


# في ملف views.py
@api_view(['POST'])
def register_user_api(request):
    serializer = UserRegistrationSerializer(data=request.data)
    
    if serializer.is_valid():
        user = serializer.save()
        return Response({"message": "Success"}, status=201)
    else:
        # 🚨 السطر ده هو "المخبر" اللي هيقولك الحقل اللي ناقص إيه
        print("🚨 VALIDATION ERRORS:", serializer.errors) 
        return Response(serializer.errors, status=400)
    
@api_view(['GET'])
def get_device_status(request):
    return Response({
        "smartwatchConnected": True,
        "homeSensorConnected": False
    })