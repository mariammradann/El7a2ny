import random
import string
from rest_framework import viewsets, status, serializers, permissions
from rest_framework.decorators import action, api_view
from rest_framework.response import Response
from django.db.models import Q
from django.contrib.auth.hashers import check_password, make_password
from django.core.mail import send_mail
from django.conf import settings
from django.utils import timezone
from datetime import timedelta
import secrets
from .models import User, Incident, PasswordResetToken
import google.generativeai as genai
from .serializers import (
    UserRegistrationSerializer,
    IncidentSerializer,
    PasswordResetRequestSerializer,
    PasswordResetVerifyTokenSerializer,
    PasswordResetConfirmSerializer,
)


# Configure Gemini - REPLACE WITH YOUR FRESH API KEY
genai.configure(api_key="AIzaSyDca6bIEtgJT8CUZZR9XPKSaHdSe0pKq7E")


@api_view(["POST"])
def get_first_aid_advice(request):
    user_message = request.data.get("message")
    if not user_message:
        return Response({"reply": "Please provide a message."}, status=400)

    try:
        model = genai.GenerativeModel("gemini-2.5-flash")
        prompt = f"As a first aid expert, give short and clear advice in the user's language for: {user_message}"
        response = model.generate_content(prompt)
        return Response({"reply": response.text})
    except Exception as e:
        print(f"AI Error: {e}")
        return Response(
            {"reply": "Sorry, I am having trouble connecting to my brain right now."},
            status=500,
        )


# 1. الـ Serializer الخاص باليوزر
class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = "__all__"


# 2. الـ UserViewSet
class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer

    # تم إضافة methods=['post'] و url_path لضمان الربط مع Postman
    @action(detail=False, methods=["post"], url_path="check_user")
    def check_user(self, request):
        email = request.data.get("email")
        password = request.data.get("password")

        if not email or not password:
            return Response(
                {"error": "Please provide both email and password"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            # بنجيب اليوزر بالإيميل
            user = User.objects.get(email=email)

            # مقارنة الباسورد (تأكد إنها متخزنة Hash في الداتا بيز)
            if check_password(password, user.password):
                return Response(
                    {
                        "message": "Login successful",
                        "email": user.email,
                        "user_id": user.user_id,
                        "name": user.name,
                    },
                    status=status.HTTP_200_OK,
                )
            else:
                return Response(
                    {"error": "الباسورد غلط يصاحبي"},
                    status=status.HTTP_401_UNAUTHORIZED,
                )

        except User.DoesNotExist:
            return Response(
                {"error": "الاكونت ده مش موجود"}, status=status.HTTP_404_NOT_FOUND
            )

    @action(detail=True, methods=["get"])
    def profile_by_id(self, request, user_id=None):
        try:
            user = User.objects.get(user_id=user_id)
            serializer = UserSerializer(user)
            return Response(serializer.data)
        except User.DoesNotExist:
            return Response(
                {"error": "User not found"}, status=status.HTTP_404_NOT_FOUND
            )

    @action(detail=False, methods=["put"])
    def update_profile(self, request):
        user_id = request.data.get("user_id")
        if not user_id:
            return Response(
                {"error": "user_id is required"}, status=status.HTTP_400_BAD_REQUEST
            )

        try:
            user = User.objects.get(user_id=user_id)
        except User.DoesNotExist:
            return Response(
                {"error": "User not found"}, status=status.HTTP_404_NOT_FOUND
            )

        serializer = UserSerializer(user, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# 3. الـ IncidentViewSet
class IncidentViewSet(viewsets.ModelViewSet):
    def get_queryset(self):
        # This function runs on EVERY request, ensuring data is fresh
        queryset = Incident.objects.all().order_by("-created_at")

        user_id = self.request.query_params.get("user_id")
        if user_id:
            queryset = queryset.filter(user_id=user_id)

        return queryset

    serializer_class = IncidentSerializer
    permission_classes = [permissions.AllowAny]

    def create(self, request, *args, **kwargs):
        from django.core.files.storage import default_storage
        from django.core.files.base import ContentFile
        from django.conf import settings
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
            if hasattr(request.data, "dict"):
                data = dict(request.data)
            else:
                data = request.data.copy()

        print(f"📦 Received data keys: {list(data.keys())}")
        print(f"📦 Received files: {list(request.FILES.keys())}")
        print(f"📦 Raw normalized data: {data}")

        # user_id -> user
        if "user_id" in data:
            user_id = data.pop("user_id")
            if isinstance(user_id, list) and user_id:
                user_id = user_id[0]
            data["user"] = user_id

        # Handle file uploads
        media_files_urls = []
        if "media_files" in request.FILES:
            files = request.FILES.getlist("media_files")
            print(f"📦 Processing {len(files)} files")
            for file in files:
                try:
                    print(f"📝 Saving file: {file.name} (size: {file.size} bytes)")
                    file_content = file.read()
                    filename = f"reports/{data.get('user', 'unknown')}/{file.name}"
                    path = default_storage.save(filename, ContentFile(file_content))
                    # Construct proper URL using Django settings
                    media_url = f"{settings.MEDIA_URL}{path}".replace("\\", "/")
                    media_files_urls.append(media_url)
                    print(f"✅ File saved to: {path}")
                    print(f"✅ Media URL: {media_url}")
                    # Verify file exists
                    from django.core.files.storage import default_storage

                    if default_storage.exists(path):
                        print(f"✅ File verified to exist at: {path}")
                    else:
                        print(f"⚠️ WARNING: File not found after save: {path}")
                except Exception as e:
                    import traceback

                    print(f"⚠️ Error saving file {file.name}: {e}")
                    traceback.print_exc()
        else:
            print("⚠️ No media_files in request.FILES")
            print(f"📦 Available fields: {list(request.FILES.keys())}")

        # Parse coordinates (may be strings)
        lat_raw = data.pop("latitude", None)
        lng_raw = data.pop("longitude", None)
        if isinstance(lat_raw, list) and lat_raw:
            lat_raw = lat_raw[0]
        if isinstance(lng_raw, list) and lng_raw:
            lng_raw = lng_raw[0]

        if lat_raw is not None and lng_raw is not None:
            try:
                lat = round(float(lat_raw), 8)
                lng = round(float(lng_raw), 8)
                # ensure address is a string
                addr = data.get("address", None)
                if isinstance(addr, list) and addr:
                    addr = addr[0]
                data["location_data"] = {
                    "latitude": lat,
                    "longitude": lng,
                    "city": data.get("city", "Unknown"),
                    "region": data.get("region", "Unknown"),
                    "address": addr or "Current Location",
                }
                print(f"✅ Coordinates parsed: lat={lat}, lng={lng}")
            except (ValueError, TypeError) as e:
                print(
                    f"❌ Error parsing coordinates: {e} (lat={lat_raw}, lng={lng_raw})"
                )
                return Response(
                    {"error": f"Invalid coordinates: {e}"},
                    status=status.HTTP_400_BAD_REQUEST,
                )
        else:
            print(f"⚠️ Missing coordinates: lat={lat_raw}, lng={lng_raw}")

        # Flatten other string fields that may be lists
        if isinstance(data.get("category"), list) and data["category"]:
            data["category"] = data["category"][0]
        if isinstance(data.get("description"), list) and data["description"]:
            data["description"] = data["description"][0]
        if isinstance(data.get("address"), list) and data["address"]:
            data["address"] = data["address"][0]

        data["media_files"] = media_files_urls

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
@api_view(["POST"])
def register_user_api(request):
    serializer = UserRegistrationSerializer(data=request.data)

    if serializer.is_valid():
        user = serializer.save()
        return Response({"message": "Success"}, status=201)
    else:
        # 🚨 السطر ده هو "المخبر" اللي هيقولك الحقل اللي ناقص إيه
        print("🚨 VALIDATION ERRORS:", serializer.errors)
        return Response(serializer.errors, status=400)


@api_view(["GET"])
def get_device_status(request):
    return Response({"smartwatchConnected": True, "homeSensorConnected": False})


from django.contrib.auth.hashers import make_password
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from django.core.mail import send_mail
from django.conf import settings
from .models import User, PasswordResetToken
# تأكد من استيراد الـ Serializers بتاعتك
# from .serializers import PasswordResetRequestSerializer, PasswordResetConfirmSerializer 

@api_view(["POST"])
def password_reset_request(request):
    """
    طلب إعادة تعيين الباسورد - يرسل كود 6 أرقام للإيميل
    """
    email = request.data.get("email")
    try:
        user = User.objects.get(email=email)
        
        # 1. توليد كود رقمي
        code = ''.join(random.choices(string.digits, k=6))
        
        # 2. حفظ الكود في الداتابيز (تحديث أو إنشاء جديد)
        PasswordResetToken.objects.update_or_create(
            user=user,
            defaults={'token': code, 'is_used': False} # تأكد أن الموديل يدعم هذه الحقول
        )

        # 3. إرسال الكود بالإيميل
        subject = "كود إعادة تعيين كلمة المرور - El7a2ny"
        message = f"""
        أهلاً {user.name}،
        
        كود إعادة تعيين كلمة المرور الخاص بك هو: {code}
        
        هذا الكود صالح لمدة 10 دقائق فقط. لا تشارك هذا الكود مع أحد.
        
        تحياتنا،
        فريق El7a2ny
        """
        send_mail(
            subject, message, settings.DEFAULT_FROM_EMAIL, [email], fail_silently=False
        )
        
        return Response({"message": "تم إرسال الكود إلى بريدك الإلكتروني"}, status=status.HTTP_200_OK)
    
    except User.DoesNotExist:
        # للأمان، نرجع نفس الرسالة حتى لو الإيميل مش موجود
        return Response({"message": "إذا كان الحساب موجوداً، فقد تم إرسال الكود"}, status=status.HTTP_200_OK)


@api_view(["POST"])
def password_reset_confirm(request):
    """
    تغيير الباسورد باستخدام الكود المباشر
    Expected JSON: { "email": "...", "code": "123456", "new_password": "..." }
    """
    email = request.data.get("email")
    code = request.data.get("code") # أو اسم الحقل "token" حسب الـ Serializer
    new_password = request.data.get("new_password")

    if not all([email, code, new_password]):
        return Response({"error": "يرجى تقديم البريد الإلكتروني، الكود، وكلمة المرور الجديدة"}, status=status.HTTP_400_BAD_REQUEST)

    try:
        user = User.objects.get(email=email)
        reset_token = PasswordResetToken.objects.get(user=user, token=code)

        # التحقق من صلاحية الكود (Expired or Used)
        if not reset_token.is_valid():
            return Response({"error": "الكود منتهي الصلاحية أو تم استخدامه من قبل"}, status=status.HTTP_400_BAD_REQUEST)

        # تحديث كلمة المرور
        user.password = make_password(new_password)
        user.save()

        # مارك الكود كـ "مستخدم"
        reset_token.mark_as_used() # تأكد أن الدالة دي موجودة في الموديل عندك

        # إرسال إيميل تأكيد النجاح
        send_mail(
            "تم تغيير كلمة المرور بنجاح",
            f"أهلاً {user.name}، تم تغيير كلمة مرورك بنجاح. إذا لم تكن أنت من قام بهذا، تواصل معنا.",
            settings.DEFAULT_FROM_EMAIL,
            [email],
            fail_silently=True
        )

        return Response({"message": "تم إعادة تعيين كلمة المرور بنجاح"}, status=status.HTTP_200_OK)

    except (User.DoesNotExist, PasswordResetToken.DoesNotExist):
        return Response({"error": "البريد الإلكتروني أو الكود غير صحيح"}, status=status.HTTP_400_BAD_REQUEST)

@api_view(["POST"])
def password_reset_verify_token(request):
    """
    تأكيد صحة الكود (OTP)
    """
    email = request.data.get("email")
    code = request.data.get("token") or request.data.get("code")
    
    try:
        user = User.objects.get(email=email)
        reset_token = PasswordResetToken.objects.get(user=user, token=code)
        
        if reset_token.is_valid():
            return Response({"message": "Code is valid"}, status=status.HTTP_200_OK)
        
        return Response({"error": "Code expired"}, status=status.HTTP_400_BAD_REQUEST)
    except (User.DoesNotExist, PasswordResetToken.DoesNotExist):
        return Response({"error": "Invalid email or code"}, status=status.HTTP_400_BAD_REQUEST)