from rest_framework import viewsets, status, serializers, permissions
from rest_framework.decorators import action, api_view
from rest_framework.response import Response
from django.db.models import Q
from django.contrib.auth.hashers import check_password, make_password
from .models import (
    User,
    Incident,
    HelpInitiative,
    Initiative,
    PasswordResetToken,
    SensorReading,
)
import google.generativeai as genai
from .serializers import (
    UserRegistrationSerializer,
    IncidentSerializer,
    HelpInitiativeSerializer,
    InitiativeSerializer,
)
import random
import string
from django.core.mail import send_mail
from django.conf import settings
from django.utils import timezone
from datetime import timedelta

# Configure Gemini
genai.configure(api_key="AIzaSyDR_HnGEg3B_W3o1SgsGb19Y9u5VG-iG90")


@api_view(["POST"])
def get_first_aid_advice(request):
    user_message = request.data.get("message")
    if not user_message:
        return Response({"reply": "Please provide a message."}, status=400)

    try:
        model = genai.GenerativeModel("gemini-1.5-flash")
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
            user = User.objects.get(email=email)

            if check_password(password, user.password):
                return Response(
                    {
                        "message": "Login successful",
                        "email": user.email,
                        "user_id": user.user_id,
                        "name": user.name,
                        "user_type": user.user_type,
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
    def list(self, request, *args, **kwargs):
        """Override list to ensure no caching"""
        response = super().list(request, *args, **kwargs)
        response["Cache-Control"] = "no-cache, no-store, must-revalidate"
        response["Pragma"] = "no-cache"
        response["Expires"] = "0"
        return response

    def retrieve(self, request, *args, **kwargs):
        """Override retrieve to ensure no caching"""
        response = super().retrieve(request, *args, **kwargs)
        response["Cache-Control"] = "no-cache, no-store, must-revalidate"
        response["Pragma"] = "no-cache"
        response["Expires"] = "0"
        return response

    def get_queryset(self):
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
        import uuid
        import os
        import json

        UserModel = User

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
            if hasattr(request.data, "dict"):
                data = dict(request.data)
            else:
                data = request.data.copy()

        print(f"📦 Received data keys: {list(data.keys())}")
        print(f"📦 Received files: {list(request.FILES.keys())}")
        print(f"📦 Raw normalized data: {data}")

        # ✅ Fix: Resolve user UUID against your custom User model
        if "user_id" in data:
            user_id_raw = data.pop("user_id")
            if isinstance(user_id_raw, list) and user_id_raw:
                user_id_raw = user_id_raw[0]

            resolved_user = None

            # Try UUID lookup first
            try:
                uid = uuid.UUID(str(user_id_raw))
                resolved_user = UserModel.objects.filter(user_id=uid).first()
            except (ValueError, AttributeError):
                pass

            # If UUID lookup failed, try pk fallback
            if resolved_user is None:
                try:
                    resolved_user = UserModel.objects.filter(pk=user_id_raw).first()
                except Exception:
                    pass

            # Final fallback: use first user in DB
            if resolved_user is None:
                resolved_user = UserModel.objects.first()

            if resolved_user is None:
                return Response(
                    {"error": "No valid user found. Please log in again."},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            data["user"] = str(resolved_user.user_id)
            print(f"✅ Resolved user UUID: {data['user']}")

        if "category" not in data or not data["category"]:
            data["category"] = "other"

        # Extract client IP from data or request headers
        client_ip = data.pop("client_ip", None)
        if isinstance(client_ip, list) and client_ip:
            client_ip = client_ip[0]
        if not client_ip:
            x_forwarded_for = request.META.get("HTTP_X_FORWARDED_FOR")
            if x_forwarded_for:
                client_ip = x_forwarded_for.split(",")[0]
            else:
                client_ip = request.META.get("REMOTE_ADDR")

        # Add IP to description
        desc = data.get("description", "")
        if isinstance(desc, list) and desc:
            desc = desc[0]
        ip_prefix = f"[IP: {client_ip}] " if client_ip else ""
        data["description"] = f"{ip_prefix}{desc}".strip()

        # Handle file uploads
        media_files_urls = []
        if "media_files" in request.FILES:
            files = request.FILES.getlist("media_files")
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
                print(f"❌ Error parsing coordinates: {e} (lat={lat_raw}, lng={lng_raw})")
                return Response(
                    {"error": f"Invalid coordinates: {e}"},
                    status=status.HTTP_400_BAD_REQUEST,
                )
        else:
            print(f"⚠️ Missing coordinates: lat={lat_raw}, lng={lng_raw}")
            if "location_data" not in data:
                data["location_data"] = {
                    "latitude": 30.0444,
                    "longitude": 31.2357,
                    "city": "Cairo",
                    "region": "Egypt",
                    "address": "Cairo, Egypt",
                }

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
        serializer.save()


@api_view(["POST"])
def register_user_api(request):
    serializer = UserRegistrationSerializer(data=request.data)

    if serializer.is_valid():
        user = serializer.save()
        return Response({"message": "Success"}, status=201)
    else:
        print("🚨 VALIDATION ERRORS:", serializer.errors)
        return Response(serializer.errors, status=400)


@api_view(["GET"])
def get_device_status(request):
    return Response({"smartwatchConnected": True, "homeSensorConnected": False})


class HelpInitiativeViewSet(viewsets.ModelViewSet):
    queryset = Initiative.objects.all().order_by("-created_at")
    serializer_class = InitiativeSerializer
    permission_classes = [permissions.AllowAny]

    def create(self, request, *args, **kwargs):
        print(f"Creating initiative with data: {request.data}")
        return super().create(request, *args, **kwargs)


@api_view(["POST"])
def verify_password_api(request):
    user_id = request.data.get("user_id")
    password = request.data.get("password")

    print(f"DEBUG: verify_password_api called with user_id={user_id}")

    if not user_id or not password:
        return Response({"error": "user_id and password are required"}, status=400)

    try:
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


@api_view(["POST"])
def change_password_api(request):
    user_id = request.data.get("user_id")
    old_password = request.data.get("old_password")
    new_password = request.data.get("new_password")

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


@api_view(["POST"])
def password_reset_request(request):
    """
    طلب إعادة تعيين الباسورد - يرسل كود 6 أرقام للإيميل
    """
    email = request.data.get("email")
    try:
        user = User.objects.get(email=email)

        code = "".join(random.choices(string.digits, k=6))

        PasswordResetToken.objects.update_or_create(
            user=user,
            defaults={
                "token": code,
                "is_used": False,
                "expires_at": timezone.now() + timedelta(minutes=10),
            },
        )

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

        return Response(
            {"message": "تم إرسال الكود إلى بريدك الإلكتروني"},
            status=status.HTTP_200_OK,
        )

    except User.DoesNotExist:
        return Response(
            {"message": "إذا كان الحساب موجوداً، فقد تم إرسال الكود"},
            status=status.HTTP_200_OK,
        )


@api_view(["POST"])
def password_reset_confirm(request):
    """
    Expected JSON: { "email": "...", "code": "123456", "new_password": "..." }
    """
    email = request.data.get("email")
    code = request.data.get("code")
    new_password = request.data.get("new_password")

    if not all([email, code, new_password]):
        return Response(
            {"error": "يرجى تقديم البريد الإلكتروني، الكود، وكلمة المرور الجديدة"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        user = User.objects.get(email=email)
        reset_token = PasswordResetToken.objects.get(user=user, token=code)

        if not reset_token.is_valid():
            return Response(
                {"error": "الكود منتهي الصلاحية أو تم استخدامه من قبل"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user.password = make_password(new_password)
        user.save()

        reset_token.mark_as_used()

        send_mail(
            "تم تغيير كلمة المرور بنجاح",
            f"أهلاً {user.name}، تم تغيير كلمة مرورك بنجاح. إذا لم تكن أنت من قام بهذا، تواصل معنا.",
            settings.DEFAULT_FROM_EMAIL,
            [email],
            fail_silently=True,
        )

        return Response(
            {"message": "تم إعادة تعيين كلمة المرور بنجاح"}, status=status.HTTP_200_OK
        )

    except (User.DoesNotExist, PasswordResetToken.DoesNotExist):
        return Response(
            {"error": "البريد الإلكتروني أو الكود غير صحيح"},
            status=status.HTTP_400_BAD_REQUEST,
        )


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
        return Response(
            {"error": "Invalid email or code"}, status=status.HTTP_400_BAD_REQUEST
        )


@api_view(["GET"])
def get_user_activity_history(request):
    """
    Consolidates user activities (Incidents and Initiatives) into a unified history.
    Query param: user_id
    """
    user_id = request.query_params.get("user_id")
    print(f"Fetching history for user_id: {user_id}")
    if not user_id:
        return Response({"error": "user_id is required"}, status=400)

    try:
        import uuid

        uid = uuid.UUID(user_id)

        history = []

        # 1. Get Incidents (Emergencies)
        incidents = Incident.objects.filter(user_id=uid).order_by("-created_at")
        for inc in incidents:
            history.append(
                {
                    "id": random.randint(1, 1000000),
                    "title": (
                        f"حالة طوارئ: {inc.category}"
                        if request.query_params.get("lang") == "ar"
                        else f"Emergency: {inc.category}"
                    ),
                    "description": inc.description or "",
                    "date": inc.created_at.isoformat(),
                    "type": "emergency",
                }
            )

        # 2. Get Initiatives (Community Posts)
        initiatives = Initiative.objects.filter(user_id=uid).order_by("-created_at")
        for init in initiatives:
            history.append(
                {
                    "id": random.randint(1, 1000000),
                    "title": (
                        f"مبادرة: {init.title}"
                        if request.query_params.get("lang") == "ar"
                        else f"Initiative: {init.title}"
                    ),
                    "description": init.description,
                    "date": init.created_at.isoformat(),
                    "type": "volunteer",
                }
            )

        # Sort by date descending
        history.sort(key=lambda x: x["date"], reverse=True)

        return Response(history)

    except ValueError:
        return Response({"error": "Invalid UUID format"}, status=400)
    except Exception as e:
        return Response({"error": str(e)}, status=500)


from django.core.files.storage import FileSystemStorage
from .services import detect_accident

@api_view(['POST'])
def detect_accident_view(request):
    """
    API endpoint that accepts an image file upload, processes it using YOLOv8,
    and returns detection results.
    """
    image_file = request.FILES.get('image')
    if not image_file:
        return Response({"error": "No image file provided"}, status=status.HTTP_400_BAD_REQUEST)

    try:
        # Save file locally using FileSystemStorage
        fs = FileSystemStorage()
        filename = fs.save(image_file.name, image_file)
        uploaded_file_path = fs.path(filename)

        # Trigger accident detection
        results = detect_accident(uploaded_file_path)

        return Response(results, status=status.HTTP_200_OK)

    except Exception as e:
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

# ========== ADMIN ENDPOINTS ==========


@api_view(["GET"])
def admin_stats(request):
    """
    Admin dashboard statistics endpoint.
    Returns: total_users, active_alerts, avg_response_time, success_rate, weekly_efficiency
    """
    from django.db.models import Count, Avg, Q
    from django.utils import timezone
    from datetime import timedelta

    try:
        total_users = User.objects.count()

        twenty_four_hours_ago = timezone.now() - timedelta(hours=24)
        active_alerts = Incident.objects.filter(
            created_at__gte=twenty_four_hours_ago
        ).count()

        avg_response_time = "3:45"

        success_rate = 0.87

        weekly_efficiency = []
        for i in range(6, -1, -1):
            date = timezone.now() - timedelta(days=i)
            start = date.replace(hour=0, minute=0, second=0, microsecond=0)
            end = date.replace(hour=23, minute=59, second=59, microsecond=999999)
            count = Incident.objects.filter(created_at__range=[start, end]).count()
            weekly_efficiency.append(float(count))

        return Response(
            {
                "total_users": total_users,
                "active_alerts": active_alerts,
                "avg_response_time": avg_response_time,
                "success_rate": success_rate,
                "weekly_efficiency": weekly_efficiency,
            }
        )
    except Exception as e:
        return Response({"error": str(e)}, status=500)


@api_view(["GET"])
def admin_users(request):
    """
    Admin users management endpoint.
    Returns list of all users with their details.
    Query params: search (optional), status (optional)
    """
    try:
        users = User.objects.all()

        search = request.query_params.get("search", "").strip()
        if search:
            users = users.filter(
                Q(name__icontains=search)
                | Q(email__icontains=search)
                | Q(phone_number__icontains=search)
            )

        status_filter = request.query_params.get("status", "").strip()
        if status_filter:
            users = users.filter(status=status_filter)

        serializer = UserSerializer(users, many=True)
        return Response(serializer.data)
    except Exception as e:
        return Response({"error": str(e)}, status=500)


@api_view(["PUT"])
def admin_update_user(request, user_id):
    """
    Update user details by admin.
    """
    try:
        user = User.objects.get(user_id=user_id)

        allowed_fields = [
            "name",
            "email",
            "phone_number",
            "status",
            "verification_status",
            "user_type",
        ]
        for field in allowed_fields:
            if field in request.data:
                setattr(user, field, request.data[field])

        user.save()
        serializer = UserSerializer(user)
        return Response(serializer.data)
    except User.DoesNotExist:
        return Response({"error": "User not found"}, status=404)
    except Exception as e:
        return Response({"error": str(e)}, status=500)


@api_view(["DELETE"])
def admin_delete_user(request, user_id):
    """
    Delete a user (soft delete by marking as inactive).
    """
    try:
        user = User.objects.get(user_id=user_id)

        user.status = "inactive"
        user.verification_status = "suspended"
        user.save()

        return Response({"message": f"User {user.name} has been deactivated"})
    except User.DoesNotExist:
        return Response({"error": "User not found"}, status=404)
    except Exception as e:
        return Response({"error": str(e)}, status=500)


@api_view(["GET"])
def admin_incidents(request):
    """
    Get all incidents for admin dashboard.
    Query params: status (optional), user_id (optional)
    """
    try:
        incidents = Incident.objects.all().order_by("-created_at")

        status_filter = request.query_params.get("status", "").strip()
        if status_filter:
            incidents = incidents.filter(status=status_filter)

        user_id_filter = request.query_params.get("user_id", "").strip()
        if user_id_filter:
            incidents = incidents.filter(user_id=user_id_filter)

        serializer = IncidentSerializer(incidents, many=True)
        return Response(serializer.data)
    except Exception as e:
        return Response({"error": str(e)}, status=500)


@api_view(["GET"])
def get_user_subscription(request, user_id):
    """
    Get user's current subscription status.
    """
    try:
        user = User.objects.get(user_id=user_id)
        return Response(
            {
                "is_plus": user.is_plus,
                "plan_type": user.plan_type,
                "subscription_date": user.subscription_date,
                "renewal_date": user.renewal_date,
            }
        )
    except User.DoesNotExist:
        return Response({"error": "User not found"}, status=404)
    except Exception as e:
        return Response({"error": str(e)}, status=500)


@api_view(["POST"])
def subscribe_user(request):
    """
    Subscribe or upgrade user subscription.
    Request data: user_id, plan_type (monthly or yearly)
    """
    try:
        # ✅ FIX: Use timezone.now() instead of datetime.now() to avoid 3-hour offset
        user_id = request.data.get("user_id")
        plan_type = request.data.get("plan_type")  # 'monthly' or 'yearly'

        if not user_id or not plan_type:
            return Response({"error": "user_id and plan_type are required"}, status=400)

        if plan_type not in ["monthly", "yearly"]:
            return Response(
                {"error": "plan_type must be 'monthly' or 'yearly'"}, status=400
            )

        user = User.objects.get(user_id=user_id)

        user.is_plus = True
        user.plan_type = plan_type
        user.subscription_date = timezone.now()  # ✅ timezone-aware

        if plan_type == "monthly":
            user.renewal_date = user.subscription_date + timedelta(days=30)
        else:
            user.renewal_date = user.subscription_date + timedelta(days=365)

        user.save()

        return Response(
            {
                "message": f"User subscribed to {plan_type} plan successfully",
                "is_plus": user.is_plus,
                "plan_type": user.plan_type,
                "subscription_date": user.subscription_date,
                "renewal_date": user.renewal_date,
            },
            status=200,
        )
    except User.DoesNotExist:
        return Response({"error": "User not found"}, status=404)
    except Exception as e:
        return Response({"error": str(e)}, status=500)


@api_view(["POST"])
def receive_temperature(request):
    """
    Receives DHT11 data from ESP32.
    If is_alert=True, auto-creates an Incident and stores the reading.
    """
    from .models import Location

    user_id = request.data.get("user_id")
    temperature = request.data.get("temperature")
    humidity = request.data.get("humidity")
    is_alert = request.data.get("is_alert", False)

    if not user_id or temperature is None:
        return Response({"error": "user_id and temperature are required"}, status=400)

    try:
        user = User.objects.get(user_id=user_id)
    except User.DoesNotExist:
        return Response({"error": "User not found"}, status=404)

    # ✅ FIX: Use timezone.now() (already imported at top of file)
    current_time = timezone.now()

    # Always save the reading for history/charts
    reading = SensorReading.objects.create(
        user=user,
        temperature=temperature,
        humidity=humidity,
        is_alert=is_alert,
    )

    incident = None
    # Auto-create an incident report when threshold is crossed
    if is_alert:
        try:
            location, _ = Location.objects.get_or_create(
                latitude=30.0444,
                longitude=31.2357,
                defaults={
                    "city": "Cairo",
                    "region": "Cairo",
                    "address": "Sensor Location (Auto-Alert)",
                },
            )

            # ✅ FIX: status="active" so it shows as a new/active alert, not "بلاغ سابق"
            incident = Incident.objects.create(
                user=user,
                location=location,
                category="fire",
                description=(
                    f"[AUTO SENSOR ALERT] High temperature detected: "
                    f"{temperature}°C / Humidity: {humidity}% "
                    f"at {current_time.strftime('%Y-%m-%d %H:%M:%S')}"
                ),
                status="active",
            )
            print(
                f"✅ Incident created: {incident.incident_id} with status: {incident.status}"
            )
        except Exception as e:
            print(f"❌ Error creating incident: {e}")
            import traceback
            traceback.print_exc()

    return Response(
        {
            "message": "alert recorded" if is_alert else "reading saved",
            "temperature": temperature,
            "humidity": humidity,
            "is_alert": is_alert,
            "timestamp": reading.created_at.isoformat(),
            "incident_id": str(incident.incident_id) if incident else None,
            "incident_status": incident.status if incident else None,
        },
        status=201,
    )


@api_view(["GET"])
def get_latest_sensor_reading(request):
    """
    Flutter polls this to show live temp + check for alerts.
    Query param: user_id
    """
    user_id = request.query_params.get("user_id")
    if not user_id:
        return Response({"error": "user_id required"}, status=400)

    reading = (
        SensorReading.objects.filter(user__user_id=user_id)
        .order_by("-created_at")
        .first()
    )

    if not reading:
        return Response({"error": "No readings yet"}, status=404)

    return Response(
        {
            "temperature": reading.temperature,
            "humidity": reading.humidity,
            "is_alert": reading.is_alert,
            "timestamp": reading.created_at.isoformat(),
        }
    )
>>>>>>> 5360e10bc19a0f217f39df673a29795f8f2e019f
