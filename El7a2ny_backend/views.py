from rest_framework import viewsets, status, serializers, permissions
from rest_framework.decorators import action, api_view
from rest_framework.response import Response
from django.db.models import Q
from django.contrib.auth.hashers import check_password
from .models import User, Incident
from .serializers import UserRegistrationSerializer, IncidentSerializer

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
    def profile_by_id(self, request, pk=None):
        try:
            user = User.objects.get(pk=pk)
            serializer = UserSerializer(user)
            return Response(serializer.data)
        except User.DoesNotExist:
            return Response({"error": "User not found"}, status=status.HTTP_404_NOT_FOUND)

# 3. الـ IncidentViewSet
class IncidentViewSet(viewsets.ModelViewSet):
    queryset = Incident.objects.all().order_by('-created_at')
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

    def get_queryset(self):
            user_id = self.request.query_params.get('user_id')
            if user_id:
                return self.queryset.filter(user_id=user_id)
            return self.queryset

# 4. دالة التسجيل (خارج الـ ViewSet)
@api_view(['POST'])
def register_user_api(request):
    serializer = UserRegistrationSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.save()
        return Response({
            "message": "User registered successfully",
            "user_id": user.user_id,
            "status": "success"
        }, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)