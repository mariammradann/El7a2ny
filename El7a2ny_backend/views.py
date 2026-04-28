from rest_framework import viewsets, status, serializers, permissions
from rest_framework.decorators import action, api_view
from rest_framework.response import Response
from django.db.models import Q
from django.contrib.auth.hashers import check_password, make_password
from .models import User, Incident, HelpInitiative
from .serializers import UserRegistrationSerializer, IncidentSerializer, HelpInitiativeSerializer

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
            data = request.data.copy()
            
            # 1. تصليح اسم اليوزر
            if 'user_id' in data:
                data['user'] = data.pop('user_id')
            
            # 2. لم وتقريب الإحداثيات (Rounding)
            if 'latitude' in data and 'longitude' in data:
                # هنقرب لـ 8 أرقام عشرية عشان تناسب الـ decimal_places=8
                lat = round(float(data.pop('latitude')), 8)
                lng = round(float(data.pop('longitude')), 8)
                
                data['location_data'] = {
                    'latitude': lat,
                    'longitude': lng,
                    'city': data.get('city', 'Unknown'),
                    'region': data.get('region', 'Unknown'),
                    'address': data.get('address', 'Current Location'),
                }

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

class HelpInitiativeViewSet(viewsets.ModelViewSet):
    queryset = HelpInitiative.objects.all().order_by('-created_at')
    serializer_class = HelpInitiativeSerializer
    permission_classes = [permissions.AllowAny]

@api_view(['POST'])
def verify_password_api(request):
    user_id = request.data.get('user_id')
    password = request.data.get('password')
    
    print(f"DEBUG: verify_password_api called with user_id={user_id}")
    
    if not user_id or not password:
        return Response({"error": "user_id and password are required"}, status=400)
    
    try:
        # Convert string user_id to UUID object to be safe
        import uuid
        uid = uuid.UUID(user_id)
        user = User.objects.get(user_id=uid)
        
        if check_password(password, user.password):
            return Response({"message": "Password verified"}, status=200)
        else:
            return Response({"error": "كلمة المرور الحالية غير صحيحة"}, status=401)
    except ValueError:
        return Response({"error": f"Invalid UUID format: {user_id}"}, status=400)
    except User.DoesNotExist:
        return Response({"error": f"User not found with id: {user_id}"}, status=404)
    except Exception as e:
        print(f"ERROR in verify_password_api: {str(e)}")
        return Response({"error": str(e)}, status=500)

@api_view(['POST'])
def change_password_api(request):
    user_id = request.data.get('user_id')
    old_password = request.data.get('old_password')
    new_password = request.data.get('new_password')
    
    print(f"DEBUG: change_password_api called for user_id={user_id}")
    
    if not user_id or not old_password or not new_password:
        return Response({"error": "Missing required fields"}, status=400)
    
    try:
        import uuid
        uid = uuid.UUID(user_id)
        user = User.objects.get(user_id=uid)
        
        if check_password(old_password, user.password):
            user.password = make_password(new_password)
            user.save()
            return Response({"message": "تم تغيير كلمة المرور بنجاح"}, status=200)
        else:
            return Response({"error": "كلمة المرور القديمة غير صحيحة"}, status=401)
    except ValueError:
        return Response({"error": "Invalid UUID format"}, status=400)
    except User.DoesNotExist:
        return Response({"error": "User not found"}, status=404)
    except Exception as e:
        print(f"ERROR in change_password_api: {str(e)}")
        return Response({"error": str(e)}, status=500)