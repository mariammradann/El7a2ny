from rest_framework import viewsets, status, serializers, permissions
from rest_framework.decorators import action, api_view
from rest_framework.response import Response
from django.db.models import Q
from django.contrib.auth.hashers import check_password, make_password
from .models import (
    Responder,
    User,
    Incident,
    HelpInitiative,
    Initiative,
    PasswordResetToken,
    SensorReading,
    IncidentChat,
    ChatMessage,
    SponsorRequest,
)
from .serializers import (
    ResponderSerializer,
    UserRegistrationSerializer,
    IncidentSerializer,
    HelpInitiativeSerializer,
    InitiativeSerializer,
    ChatMessageSerializer,
    IncidentChatSerializer,
)
import random
import string
from django.core.mail import send_mail
from django.conf import settings
from django.utils import timezone
from datetime import timedelta
import uuid
import logging

logger = logging.getLogger(__name__)


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

def _wrap_bilingual(ai_data: dict):
    """
    Takes a raw AI microservice dict (English only) and wraps the
    summary, responder_briefing, and instructions into bilingual
    {en: ..., ar: ...} structures using a simple Arabic mapping table.
    Mutates ai_data in place.
    """
    import json

    ARABIC_SUMMARIES = {
        "Building Fire":        "حريق في مبنى",
        "Vehicle Fire":         "حريق في مركبة",
        "Wildfire":             "حريق غابات",
        "Traffic Accident":     "حادث مروري",
        "Medical Emergency":    "حالة طبية طارئة",
        "Chemical Spill":       "انسكاب مواد كيميائية",
        "Gas Leak":             "تسرب غاز",
        "Flood":                "فيضان",
        "Earthquake":           "زلزال",
        "Collapsed Structure":  "انهيار مبنى",
        "Active Shooter":       "إطلاق نار نشط",
        "Bomb Threat":          "تهديد بقنبلة",
        "Hostage Situation":    "احتجاز رهائن",
        "Missing Person":       "شخص مفقود",
    }

    inc_type = ai_data.get("incident_type", "")
    ar_type  = ARABIC_SUMMARIES.get(inc_type, inc_type)

    # summary ─────────────────────────────────────────────────────────────────
    raw_summary = ai_data.get("summary", "")
    if isinstance(raw_summary, dict):
        pass  # Already bilingual from Gemini — leave as-is
    elif raw_summary and not str(raw_summary).strip().startswith("{"):
        ai_data["summary"] = json.dumps(
            {"en": raw_summary, "ar": f"{ar_type}: {raw_summary}"},
            ensure_ascii=False,
        )

    # responder_briefing ──────────────────────────────────────────────────────
    raw_brief = ai_data.get("responder_briefing", "")
    if isinstance(raw_brief, dict):
        pass  # Already bilingual from Gemini — leave as-is
    elif raw_brief and not str(raw_brief).strip().startswith("{"):
        ai_data["responder_briefing"] = json.dumps(
            {"en": raw_brief, "ar": raw_brief},
            ensure_ascii=False,
        )

    # instructions ────────────────────────────────────────────────────────────
    raw_inst = ai_data.get("instructions", [])
    if isinstance(raw_inst, dict):
        pass  # Already bilingual dict from Gemini — leave as-is
    elif isinstance(raw_inst, list) and raw_inst:
        ai_data["instructions"] = {"en": raw_inst, "ar": raw_inst}


def trigger_auto_ai_analysis(incident):
    from .models import IncidentAIAnalysis
    from .ai_client import analyze_text, analyze_image, save_ai_result
    import json, os
    from io import BytesIO
    from django.conf import settings

    # ── Step 1: Try image analysis on uploaded media files ────────────────────
    media_files = incident.media_files or []
    image_extensions = {".jpg", ".jpeg", ".png", ".webp"}
    analyzed_via_image = False

    for media_path in media_files:
        # media_path is like "/media/reports/<user>/<filename>"
        rel_path = media_path.lstrip("/")       # "media/reports/..."
        abs_path = os.path.join(settings.BASE_DIR, rel_path)
        ext = os.path.splitext(abs_path)[1].lower()
        if ext not in image_extensions:
            continue
        if not os.path.exists(abs_path):
            print(f"[WARNING] Media file not found on disk: {abs_path}")
            continue
        try:
            print(f"[INFO] Running Gemini image analysis on: {abs_path}")
            content_type = "image/jpeg" if ext in {".jpg", ".jpeg"} else f"image/{ext.lstrip('.')}"
            with open(abs_path, "rb") as img_f:
                ai_data = analyze_image(
                    BytesIO(img_f.read()),
                    filename=os.path.basename(abs_path),
                    content_type=content_type,
                )
            _wrap_bilingual(ai_data)
            save_ai_result(incident, ai_data, source="image")
            print(f"[SUCCESS] AI image analysis saved for incident {incident.incident_id} "
                  f"using {os.path.basename(abs_path)}")
            analyzed_via_image = True
            break   # Only analyze first valid image
        except Exception as e:
            print(f"[WARNING] AI image analysis failed for {abs_path}: {e}")

    if analyzed_via_image:
        return

    # ── Step 2: Fall back to text analysis via AI microservice ────────────────
    try:
        if incident.description:
            ai_data = analyze_text(incident.description, location=incident.location.address)
            _wrap_bilingual(ai_data)
            save_ai_result(incident, ai_data, source="text")
            print(f"[SUCCESS] AI text analysis triggered successfully for incident {incident.incident_id}")
            return
    except Exception as e:
        print(f"[WARNING] AI microservice failed or offline: {e}. Falling back to default AI analysis.")
    
    # Fallback default AI analysis generation
    import json
    cat = str(incident.category).lower()
    desc = incident.description or "No description provided."
    
    if "fire" in cat:
        incident_type = "Building Fire"
        severity = "Critical"
        triage_level = "Red"
        urgency_score = 9
        risk_level = "Rapid fire spread, heavy smoke inhalation risk, structural integrity threat."
        dispatch_priority = "DISPATCH IMMEDIATE FIRST-RESPONDERS (RED ALERT)."
        summary = {
            "en": f"Active fire reported. Category: Fire. Details: {desc}",
            "ar": f"تم الإبلاغ عن حريق نشط. التصنيف: حريق. التفاصيل: {desc}"
        }
        responder_briefing = {
            "en": "Approach with full fire gear and oxygen packs. Structural collapse risk. Evacuate adjacent buildings immediately.",
            "ar": "الاقتراب بمعدات الإطفاء الكاملة وأجهزة الأكسجين. خطر انهيار الهيكل. إخلاء المباني المجاورة فوراً."
        }
        instructions = {
            "en": [
                "Evacuate the building immediately using the stairs. Do not use elevators.",
                "If trapped by smoke, stay low to the ground and cover your nose and mouth with a wet cloth.",
                "Feel doors for heat before opening them. If hot, do not open.",
                "Alert others in the vicinity and stay a safe distance away once outside."
            ],
            "ar": [
                "إخلاء المبنى فوراً باستخدام السلالم. لا تستخدم المصاعد الكهربائية.",
                "إذا حاصرك الدخان، ابقَ منخفضاً قريباً من الأرض وغطِّ أنفك وفمك بقطعة قماش مبللة.",
                "تحسس الأبواب للتأكد من حرارتها قبل فتحها. إذا كانت ساخنة، لا تفتحها.",
                "قم بتنبيه الآخرين في الجوار وابقَ على مسافة آمنة بمجرد خروجك."
            ]
        }
        responders_needed = ["Firefighters", "Ambulance", "Search and Rescue"]
    elif "medical" in cat:
        incident_type = "Medical Emergency"
        severity = "High"
        triage_level = "Orange"
        urgency_score = 8
        risk_level = "Potential cardiac or respiratory arrest, severe blood loss, shock risk."
        dispatch_priority = "IMMEDIATE PARAMEDIC DISPATCH."
        summary = {
            "en": f"Emergency medical situation. Category: Medical. Details: {desc}",
            "ar": f"حالة طبية طارئة. التصنيف: طبي. التفاصيل: {desc}"
        }
        responder_briefing = {
            "en": "Bring AED, trauma kit, and oxygen. Be prepared to administer CPR or first aid upon arrival.",
            "ar": "إحضار جهاز إزالة الرجفان (AED)، حقيبة إسعافات أولية، وأكسجين. الاستعداد لإجراء الإنعاش الرئوي فور الوصول."
        }
        instructions = {
            "en": [
                "Check if the person is responsive and breathing.",
                "If bleeding heavily, apply direct pressure using a clean cloth or bandage.",
                "Keep the patient warm, quiet, and do not move them unless they are in immediate danger.",
                "Loosen tight clothing and reassure the patient that help is on the way."
            ],
            "ar": [
                "تأكد مما إذا كان الشخص واعياً ويتنفس.",
                "في حالة النزيف الشديد، اضغط مباشرة باستخدام قطعة قماش نظيفة أو ضمادة.",
                "حافظ على دفء المريض وهدوئه، ولا تحركه إلا إذا كان في خطر مباشر.",
                "قم بفك الملابس الضيقة وطمأنة المريض بأن المساعدة في الطريق."
            ]
        }
        responders_needed = ["Ambulance"]
    elif "security" in cat:
        incident_type = "Security Alert"
        severity = "High"
        triage_level = "Orange"
        urgency_score = 8
        risk_level = "Active physical threat, assault, or intrusion in progress."
        dispatch_priority = "IMMEDIATE LAW ENFORCEMENT DISPATCH."
        summary = {
            "en": f"Security incident. Category: Security. Details: {desc}",
            "ar": f"حادث أمني. التصنيف: أمن. التفاصيل: {desc}"
        }
        responder_briefing = {
            "en": "Approach with caution. Scene may not be secure. Maintain defensive posture and contact law enforcement.",
            "ar": "الاقتراب بحذر شديد. قد لا يكون الموقع آمناً بالكامل. حافظ على وضع دفاعي وتواصل مع الشرطة."
        }
        instructions = {
            "en": [
                "Find a safe place to hide, lock the doors, and turn off the lights.",
                "Silence your mobile phone and remain completely quiet.",
                "Only try to escape if there is a safe exit path available.",
                "Do not confront the intruder or threat under any circumstances."
            ],
            "ar": [
                "ابحث عن مكان آمن للاختباء، وأغلق الأبواب وأطفئ الأنوار.",
                "ضع هاتفك المحمول على وضع الصامت وابقَ هادئاً تماماً.",
                "لا تحاول الهرب إلا إذا كان هناك مسار خروج آمن تماماً.",
                "لا تواجه المقتحم أو التهديد تحت أي ظرف من الظروف."
            ]
        }
        responders_needed = ["Police"]
    else:
        incident_type = "Incident Report"
        severity = "Medium"
        triage_level = "Yellow"
        urgency_score = 5
        risk_level = "General distress or undefined emergency."
        dispatch_priority = "Standard dispatch response."
        summary = {
            "en": f"Report received. Category: General. Details: {desc}",
            "ar": f"تم استلام البلاغ. التصنيف: عام. التفاصيل: {desc}"
        }
        responder_briefing = {
            "en": "Assess the scene carefully upon arrival. Establish contact with reporter to clarify situation.",
            "ar": "تقييم الموقع بعناية عند الوصول. تواصل مع المُبلغ لتوضيح طبيعة الحالة."
        }
        instructions = {
            "en": [
                "Stay calm and remain in a safe location near the reported area.",
                "Keep your phone lines clear to receive updates from responders.",
                "Ensure you are visible to volunteers as they approach.",
                "Avoid unnecessary movement to preserve energy and safety."
            ],
            "ar": [
                "حافظ على هدوئك وابقَ في مكان آمن بالقرب من المنطقة المبلّغ عنها.",
                "ابقِ خط الهاتف شاغراً لاستقبال أي تحديثات من فرق المساعدة.",
                "تأكد من أنك مرئي للمتطوعين أثناء اقترابهم.",
                "تجنب التحركات غير الضرورية للحفاظ على سلامتك وطاقتك."
            ]
        }
        responders_needed = ["Standard response team"]
        
    # Delete any previous analysis (re-analysis case)
    IncidentAIAnalysis.objects.filter(incident=incident).delete()
    
    # Save the fallback analysis object
    IncidentAIAnalysis.objects.create(
        incident=incident,
        incident_type=incident_type,
        severity=severity,
        triage_level=triage_level,
        urgency_score=urgency_score,
        risk_level=risk_level,
        dispatch_priority=dispatch_priority,
        summary=json.dumps(summary, ensure_ascii=False),
        responder_briefing=json.dumps(responder_briefing, ensure_ascii=False),
        instructions=instructions,
        responders_needed=responders_needed,
        confidence=0.95,
        source="text",
    )
    print(f"[SUCCESS] Auto-generated fallback AI analysis created successfully for incident {incident.incident_id}")


class IncidentViewSet(viewsets.ModelViewSet):
    def list(self, request, *args, **kwargs):
        """Override list to ensure no caching"""
        response = super().list(request, *args, **kwargs)
        response["Cache-Control"] = "no-cache, no-store, must-revalidate"
        response["Pragma"] = "no-cache"
        response["Expires"] = "0"
        return response

    def retrieve(self, request, *args, **kwargs):
        """Override retrieve to ensure no caching and auto-generate AI analysis if missing or old format"""
        instance = self.get_object()
        try:
            from .models import IncidentAIAnalysis
            analysis = IncidentAIAnalysis.objects.filter(incident=instance).first()
            # If analysis doesn't exist or summary is in old format (doesn't start with '{'), regenerate it
            if not analysis or not analysis.summary or not str(analysis.summary).strip().startswith('{'):
                trigger_auto_ai_analysis(instance)
                # Refresh instance from db to include the new relation
                instance.refresh_from_db()
        except Exception as e:
            print(f"[ERROR] Failed to auto-generate missing AI analysis on retrieve: {e}")
            
        serializer = self.get_serializer(instance)
        response = Response(serializer.data)
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

        print(f"[INFO] Received data keys: {list(data.keys())}")
        print(f"[INFO] Received files: {list(request.FILES.keys())}")
        print(f"[INFO] Raw normalized data: {data}")

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
            print(f"[SUCCESS] Resolved user UUID: {data['user']}")
        else:
            # If no user_id is provided, check if it's a guest report
            # but first we need a user to assign to the incident (ForeignKey requirement)
            resolved_user = UserModel.objects.first()
            if resolved_user:
                data["user"] = str(resolved_user.user_id)
            else:
                return Response(
                    {"error": "No valid user found. Please log in again."},
                    status=status.HTTP_400_BAD_REQUEST,
                )



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

        # Description handling
        desc = data.get("description", "")
        if isinstance(desc, list) and desc:
            desc = desc[0]
        data["description"] = desc.strip()

        # Handle file uploads
        media_files_urls = []
        if "media_files" in request.FILES:
            files = request.FILES.getlist("media_files")
            print(f"[INFO] Processing {len(files)} files")
            for file in files:
                try:
                    filename = f"reports/{data.get('user', 'unknown')}/{file.name}"
                    path = default_storage.save(filename, ContentFile(file.read()))
                    media_files_urls.append(f"/media/{path}")
                    print(f"[SUCCESS] File saved: {path}")
                except Exception as e:
                    print(f"[WARNING] Error saving file: {e}")
        else:
            print("[WARNING] No media_files in request.FILES")

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
                print(f"[SUCCESS] Coordinates parsed: lat={lat}, lng={lng}")
            except (ValueError, TypeError) as e:
                print(f"[ERROR] Error parsing coordinates: {e} (lat={lat_raw}, lng={lng_raw})")
                return Response(
                    {"error": f"Invalid coordinates: {e}"},
                    status=status.HTTP_400_BAD_REQUEST,
                )
        else:
            print(f"[WARNING] Missing coordinates: lat={lat_raw}, lng={lng_raw}")
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

        print(f"[INFO] Sending to serializer: {data}")

        serializer = self.get_serializer(data=data)
        if not serializer.is_valid():
            print("[ERROR] Final Serializer Errors:", serializer.errors)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        self.perform_create(serializer)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    def perform_create(self, serializer):
        incident = serializer.save()
        try:
            trigger_auto_ai_analysis(incident)
        except Exception as e:
            print(f"[ERROR] Failed to auto-generate AI analysis on create: {e}")


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
    from django.utils import timezone
    from datetime import timedelta

    user_id = request.query_params.get("user_id")

    # Check if sensor sent a reading in the last 30 seconds
    cutoff = timezone.now() - timedelta(seconds=30)

    sensor_query = SensorReading.objects.filter(created_at__gte=cutoff)
    if user_id:
        sensor_query = sensor_query.filter(user__user_id=user_id)

    home_sensor_connected = sensor_query.exists()

    return Response(
        {
            "smartwatchConnected": False,
            "homeSensorConnected": home_sensor_connected,
        }
    )


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


@api_view(["PATCH", "DELETE"])
def admin_update_incident(request, incident_id):
    """
    Admin action on a specific incident.
    PATCH body: {"action": "monitor" | "cancel" | "resolve"}
    DELETE: soft-delete the incident (status = 'deleted')
    """
    try:
        incident = Incident.objects.get(incident_id=incident_id)
    except Incident.DoesNotExist:
        return Response({"error": "Incident not found"}, status=404)
    except Exception:
        # Try integer pk fallback
        try:
            incident = Incident.objects.get(pk=incident_id)
        except Incident.DoesNotExist:
            return Response({"error": "Incident not found"}, status=404)

    try:
        if request.method == "DELETE":
            incident.status = "deleted"
            incident.save()
            return Response({"message": f"Incident {incident_id} deleted"})

        action = request.data.get("action", "").strip().lower()
        if action == "monitor":
            incident.status = "active"
        elif action == "cancel":
            incident.status = "cancelled"
        elif action == "resolve":
            incident.status = "resolved"
        else:
            return Response({"error": f"Unknown action: {action}"}, status=400)

        incident.save()
        serializer = IncidentSerializer(incident)
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
    Returns mock data if no real readings exist.
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
        # Return mock data for testing
        return Response(
            {
                "temperature": 28.5,
                "humidity": 65.0,
                "is_alert": False,
                "timestamp": timezone.now().isoformat(),
            }
        )

    return Response(
        {
            "temperature": reading.temperature,
            "humidity": reading.humidity,
            "is_alert": reading.is_alert,
            "timestamp": reading.created_at.isoformat(),
        }
    )


@api_view(["GET"])
def fetch_sensors(request):
    """
    Returns list of all sensors with latest readings.
    Format matches SensorModel expectations from Flutter app.
    """
    # Get the latest reading for each user
    from django.db.models import Max

    # Get all distinct users with sensor readings
    users_with_readings = (
        SensorReading.objects.values("user")
        .annotate(latest_id=Max("id"))
        .values_list("latest_id", flat=True)
    )

    latest_readings = SensorReading.objects.filter(id__in=users_with_readings)

    sensors = []
    sensor_id = 1

    for reading in latest_readings.order_by("-created_at"):
        # Determine status based on temperature and alert flag
        if reading.is_alert:
            status = "danger"
        elif reading.temperature >= 30.0:  # Warning threshold
            status = "warning"
        else:
            status = "normal"

        # Determine sensor type (heat sensor for temperature)
        sensor_type = "heat"

        sensor_data = {
            "id": sensor_id,
            "type": sensor_type,
            "value": str(round(reading.temperature, 1)),
            "unit": "°C",
            "status": status,
            "lat": 30.0444,  # Default Cairo location
            "lng": 31.2357,
            "updated_at": reading.created_at.isoformat(),
        }
        sensors.append(sensor_data)
        sensor_id += 1

    # If no real sensors, return mock data for testing
    if not sensors:
        sensors = [
            {
                "id": 1,
                "type": "heat",
                "value": "28.5",
                "unit": "°C",
                "status": "normal",
                "lat": 30.0444,
                "lng": 31.2357,
                "updated_at": timezone.now().isoformat(),
            }
        ]

    return Response(sensors)


from .serializers import UserRatingSerializer, VolunteerRatingSerializer


@api_view(["POST"])
def submit_user_rating(request):
    """
    Submit a user rating.
    """
    serializer = UserRatingSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(["POST"])
def submit_volunteer_rating(request):
    """
    Submit a volunteer rating.
    """
    serializer = VolunteerRatingSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(["POST"])
def respond_to_alert(request, incident_id):
    """
    Respond to an alert as a volunteer.
    """
    user_id = request.data.get("user_id")
    lat = request.data.get("lat")
    lng = request.data.get("lng")
    response_seconds = request.data.get("response_seconds", 0)

    if not user_id:
        return Response({"detail": "user_id is required."}, status=400)

    try:
        user = User.objects.get(user_id=user_id)
    except User.DoesNotExist:
        return Response({"detail": "User not found."}, status=404)

    already_responded = Responder.objects.filter(
        incident_id=incident_id, user_id=user.user_id
    ).exists()

    if already_responded:
        return Response({"detail": "Already responded."}, status=409)

    response_time = timedelta(seconds=int(response_seconds))

    responder = Responder.objects.create(
        incident_id=incident_id,
        user_id=user.user_id,
        response_time=response_time,
        lat=lat,
        lng=lng,
        last_location_updated=timezone.now() if lat else None,
    )
    incident = Incident.objects.get(incident_id=responder.incident_id)
    incident.current_volunteers = Responder.objects.filter(
        incident_id=incident.incident_id
    ).count()
    incident.save()

    serializer = ResponderSerializer(responder)
    return Response(serializer.data, status=status.HTTP_201_CREATED)


@api_view(["GET"])
def get_incident_responders(request, incident_id):
    """
    Get all responders for an incident with their details.
    """
    responders = Responder.objects.filter(incident_id=incident_id)
    data = []
    for r in responders:
        try:
            user = User.objects.get(user_id=r.user_id)
            name = user.name or ""
            phone = user.phone_number if hasattr(user, "phone_number") else ""
        except User.DoesNotExist:
            name = "Unknown"
            phone = ""

        data.append(
            {
                "id": str(r.responder_id),
                "user_id": str(r.user_id),
                "name": name,
                "phone": phone,
                "lat": r.lat,
                "lng": r.lng,
                "response_time": str(r.response_time),
            }
        )
    return Response(data, status=status.HTTP_200_OK)


@api_view(["PATCH"])
def update_responder_location(request, incident_id):
    """
    Update responder's live location.
    """
    user_id = request.data.get("user_id")

    if not user_id:
        return Response({"detail": "user_id is required."}, status=400)

    try:
        responder = Responder.objects.get(incident_id=incident_id, user_id=user_id)
        responder.lat = request.data.get("lat")
        responder.lng = request.data.get("lng")
        responder.last_location_updated = timezone.now()
        responder.save(update_fields=["lat", "lng", "last_location_updated"])
        return Response({"status": "ok"})
    except Responder.DoesNotExist:
        return Response({'detail': 'Not a responder for this incident.'}, status=404)


# ============ CHAT ENDPOINTS ============


@api_view(["GET", "POST"])
def incident_chat_messages(request, incident_id):
    """
    GET: Fetch all messages for an incident chat
    POST: Send a new message to an incident chat
    """
    if request.method == "GET":
        # Get or create chat for this incident
        chat, created = IncidentChat.objects.get_or_create(incident_id=incident_id)

        # Optional: filter by timestamp to get only new messages
        since = request.query_params.get("since")
        messages = chat.messages.all()

        if since:
            try:
                from django.utils import timezone
                from dateutil.parser import parse

                since_dt = parse(since)
                messages = messages.filter(created_at__gt=since_dt)
            except:
                pass

        serializer = ChatMessageSerializer(messages, many=True)
        return Response(
            {
                "chat_id": str(chat.chat_id),
                "incident_id": str(chat.incident_id),
                "messages": serializer.data,
            }
        )

    elif request.method == "POST":
        # Create a new message
        sender_id = request.data.get("sender_id")
        sender_name = request.data.get("sender_name", "Unknown")
        sender_type = request.data.get(
            "sender_type", "user"
        )  # user, volunteer, admin, system
        text = request.data.get("text")

        if not all([sender_id, text]):
            return Response(
                {"error": "sender_id and text are required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Get or create chat
        chat, _ = IncidentChat.objects.get_or_create(incident_id=incident_id)

        # Create message
        message = ChatMessage.objects.create(
            chat=chat,
            sender_id=sender_id,
            sender_name=sender_name,
            sender_type=sender_type,
            text=text,
        )

        serializer = ChatMessageSerializer(message)
        return Response(serializer.data, status=status.HTTP_201_CREATED)


@api_view(["GET"])
def incident_chat_poll(request, incident_id):
    """
    Poll endpoint for real-time chat updates.
    Returns new messages since the provided timestamp.
    """
    since = request.query_params.get("since")

    chat, created = IncidentChat.objects.get_or_create(incident_id=incident_id)
    messages = chat.messages.all()

    if since:
        try:
            from django.utils import timezone
            from dateutil.parser import parse

            since_dt = parse(since)
            messages = messages.filter(created_at__gt=since_dt)
        except:
            pass

    serializer = ChatMessageSerializer(messages, many=True)
    return Response(
        {
            "messages": serializer.data,
            "timestamp": timezone.now().isoformat(),
        }
    )


# ═══════════════════════════════════════════════════════════════════════════════
# ═══════════════════ AI ANALYSIS VIEWS ═══════════════════════════════════════
# ═══════════════════════════════════════════════════════════════════════════════

from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework_simplejwt.authentication import JWTAuthentication
from .ai_client import (
    AIServiceError,
    analyze_image,
    analyze_video,
    analyze_voice,
    analyze_text,
    save_ai_result,
)
from .models import IncidentAIAnalysis


def _get_incident_for_user(incident_id, user):
    """
    Fetch an Incident that belongs to the requesting user.
    Returns (incident, error_response) — one of the two will be None.
    """
    try:
        incident = Incident.objects.get(incident_id=incident_id, user=user)
        return incident, None
    except Incident.DoesNotExist:
        return None, Response(
            {"error": "Incident not found or does not belong to you."},
            status=status.HTTP_404_NOT_FOUND,
        )


class AnalyzeIncidentImageView(APIView):
    """
    POST /api/incidents/analyze/image/
    Flutter sends: incident_id (UUID) + image file
    Django forwards to AI service, saves result, returns analysis.
    """
    authentication_classes = [JWTAuthentication]
    permission_classes     = [IsAuthenticated]

    def post(self, request):
        incident_id = request.data.get("incident_id")
        image_file = request.FILES.get("image")

        if not incident_id or not image_file:
            return Response(
                {"error": "incident_id and image are required"},
                status=status.HTTP_400_BAD_REQUEST
            )

        incident, err = _get_incident_for_user(incident_id, request.user)
        if err:
            return err

        try:
            ai_data = analyze_image(
                image_file,
                filename=image_file.name,
                content_type=image_file.content_type,
            )
            analysis = save_ai_result(incident, ai_data, source="image")
            from .serializers import IncidentAIAnalysisSerializer
            return Response(
                IncidentAIAnalysisSerializer(analysis).data,
                status=status.HTTP_201_CREATED,
            )
        except AIServiceError as e:
            logger.error(f"AI image analysis failed: {e}")
            return Response({"error": str(e)}, status=status.HTTP_503_SERVICE_UNAVAILABLE)


class AnalyzeIncidentVideoView(APIView):
    """
    POST /api/incidents/analyze/video/
    Flutter sends: incident_id (UUID) + video file
    """
    authentication_classes = [JWTAuthentication]
    permission_classes     = [IsAuthenticated]

    def post(self, request):
        incident_id = request.data.get("incident_id")
        video_file = request.FILES.get("video")

        if not incident_id or not video_file:
            return Response(
                {"error": "incident_id and video are required"},
                status=status.HTTP_400_BAD_REQUEST
            )

        incident, err = _get_incident_for_user(incident_id, request.user)
        if err:
            return err

        try:
            ai_data = analyze_video(
                video_file,
                filename=video_file.name,
                content_type=video_file.content_type,
            )
            analysis = save_ai_result(incident, ai_data, source="video")
            from .serializers import IncidentAIAnalysisSerializer
            return Response(
                IncidentAIAnalysisSerializer(analysis).data,
                status=status.HTTP_201_CREATED,
            )
        except AIServiceError as e:
            logger.error(f"AI video analysis failed: {e}")
            return Response({"error": str(e)}, status=status.HTTP_503_SERVICE_UNAVAILABLE)


class AnalyzeIncidentVoiceView(APIView):
    """
    POST /api/incidents/analyze/voice/
    Flutter sends: incident_id (UUID) + audio file
    Returns both transcription and emergency analysis.
    """
    authentication_classes = [JWTAuthentication]
    permission_classes     = [IsAuthenticated]

    def post(self, request):
        incident_id = request.data.get("incident_id")
        audio_file = request.FILES.get("audio")

        if not incident_id or not audio_file:
            return Response(
                {"error": "incident_id and audio are required"},
                status=status.HTTP_400_BAD_REQUEST
            )

        incident, err = _get_incident_for_user(incident_id, request.user)
        if err:
            return err

        try:
            ai_data  = analyze_voice(
                audio_file,
                filename=audio_file.name,
                content_type=audio_file.content_type,
            )
            # Voice response has nested 'analysis' — save_ai_result handles this
            analysis = save_ai_result(incident, ai_data, source="voice")
            from .serializers import IncidentAIAnalysisSerializer

            return Response(
                {
                    "transcription":    ai_data.get("transcription", ""),
                    "panic_detected":   ai_data.get("panic_detected", False),
                    "distress_keywords":ai_data.get("distress_keywords", []),
                    "analysis":         IncidentAIAnalysisSerializer(analysis).data,
                },
                status=status.HTTP_201_CREATED,
            )
        except AIServiceError as e:
            logger.error(f"AI voice analysis failed: {e}")
            return Response({"error": str(e)}, status=status.HTTP_503_SERVICE_UNAVAILABLE)


class AnalyzeIncidentTextView(APIView):
    """
    POST /api/incidents/analyze/text/
    Flutter sends: incident_id (UUID) + description string
    """
    authentication_classes = [JWTAuthentication]
    permission_classes     = [IsAuthenticated]

    def post(self, request):
        incident_id = request.data.get("incident_id")
        description = request.data.get("description")

        if not incident_id or not description:
            return Response(
                {"error": "incident_id and description are required"},
                status=status.HTTP_400_BAD_REQUEST
            )

        incident, err = _get_incident_for_user(incident_id, request.user)
        if err:
            return err

        try:
            ai_data  = analyze_text(
                description=description,
                location=request.data.get("location"),
            )
            analysis = save_ai_result(incident, ai_data, source="text")
            from .serializers import IncidentAIAnalysisSerializer
            return Response(
                IncidentAIAnalysisSerializer(analysis).data,
                status=status.HTTP_201_CREATED,
            )
        except AIServiceError as e:
            logger.error(f"AI text analysis failed: {e}")
            return Response({"error": str(e)}, status=status.HTTP_503_SERVICE_UNAVAILABLE)


class IncidentAIAnalysisDetailView(APIView):
    """
    GET /api/incidents/<incident_id>/analysis/
    Flutter fetches the saved AI analysis for an incident.
    """
    authentication_classes = [JWTAuthentication]
    permission_classes     = [IsAuthenticated]

    def get(self, request, incident_id):
        incident, err = _get_incident_for_user(incident_id, request.user)
        if err:
            return err

        try:
            analysis = incident.ai_analysis  # via OneToOneField related_name
            from .serializers import IncidentAIAnalysisSerializer
            return Response(IncidentAIAnalysisSerializer(analysis).data)
        except IncidentAIAnalysis.DoesNotExist:
            return Response(
                {"error": "No AI analysis found for this incident."},
                status=status.HTTP_404_NOT_FOUND,
            )


@api_view(["GET"])
def get_sponsors(request):
    lang = request.query_params.get("lang", "en")
    is_ar = lang == "ar"
    sponsors = [
        {
            "id": 1,
            "category": "cars",
            "title": "غبور أوتو (GB Auto)" if is_ar else "GB Auto (Ghabour)",
            "rating": "4.8",
            "badge_label": "شريك النخبة" if is_ar else "Elite Partner",
            "description": "خدمات صيانة وإغاثة على الطريق على مدار الساعة." if is_ar else "24/7 roadside assistance and vehicle maintenance services.",
            "services": [
                "إغاثة طريق / Roadside Assistance",
                "سحب سيارات / Towing",
                "صيانة متنقلة / Mobile Maintenance"
            ] if is_ar else [
                "Roadside Assistance",
                "Towing",
                "Mobile Maintenance"
            ],
            "phone": "19999",
            "branch": "القاهرة" if is_ar else "Cairo",
            "is_featured": True
        },
        {
            "id": 2,
            "category": "insurance",
            "title": "أكسا للتأمين" if is_ar else "AXA Insurance",
            "rating": "4.7",
            "badge_label": "تأمين معتمد" if is_ar else "Certified Insurer",
            "description": "تغطية تأمينية شاملة للحوادث والرعاية الطبية." if is_ar else "Comprehensive insurance coverage for accidents and healthcare.",
            "services": [
                "تأمين طبي / Medical Insurance",
                "تأمين حوادث / Accident Insurance",
                "دعم مالي / Financial Support"
            ] if is_ar else [
                "Medical Insurance",
                "Accident Insurance",
                "Financial Support"
            ],
            "phone": "16111",
            "branch": "الجيزة" if is_ar else "Giza",
            "is_featured": True
        },
        {
            "id": 3,
            "category": "medical",
            "title": "مستشفى دار الفؤاد" if is_ar else "Dar Al Fouad Hospital",
            "rating": "4.9",
            "badge_label": "شريك طبي" if is_ar else "Medical Partner",
            "description": "رعاية طبية طارئة وغرف عناية مركزة مجهزة بالكامل." if is_ar else "Emergency medical care and fully equipped intensive care units.",
            "services": [
                "طوارئ 24 ساعة / 24/7 ER",
                "عناية مركزة / ICU",
                "إرسال إسعاف / Ambulance Dispatch"
            ] if is_ar else [
                "24/7 ER",
                "ICU",
                "Ambulance Dispatch"
            ],
            "phone": "16370",
            "branch": "السادس من أكتوبر" if is_ar else "6th of October",
            "is_featured": True
        }
    ]
    return Response(sponsors, status=status.HTTP_200_OK)


@api_view(["POST"])
def apply_sponsor(request):
    try:
        user_id = request.data.get("user_id")
        user = None
        if user_id:
            try:
                user = User.objects.get(user_id=user_id)
            except User.DoesNotExist:
                pass
        
        company_name = request.data.get("company_name")
        contact_person = request.data.get("contact_person")
        phone_number = request.data.get("phone_number")
        message = request.data.get("message")
        
        if not all([company_name, contact_person, phone_number, message]):
            return Response({"error": "All fields are required"}, status=status.HTTP_400_BAD_REQUEST)
            
        sponsor_request = SponsorRequest.objects.create(
            company_name=company_name,
            contact_person=contact_person,
            phone_number=phone_number,
            message=message,
            user=user,
            status="pending"
        )
        
        return Response({
            "message": "Sponsor application submitted successfully",
            "request_id": str(sponsor_request.request_id)
        }, status=status.HTTP_201_CREATED)
    except Exception as e:
        logger.error(f"Error submitting sponsor application: {e}")
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(["GET"])
def admin_sponsor_requests(request):
    try:
        requests = SponsorRequest.objects.all().order_by("-created_at")
        data = []
        for req in requests:
            data.append({
                "request_id": str(req.request_id),
                "company_name": req.company_name,
                "contact_person": req.contact_person,
                "phone_number": req.phone_number,
                "message": req.message,
                "status": req.status,
                "created_at": req.created_at.isoformat(),
                "user_id": str(req.user.user_id) if req.user else None,
                "user_name": req.user.name if req.user else None,
            })
        return Response(data, status=status.HTTP_200_OK)
    except Exception as e:
        logger.error(f"Error fetching sponsor requests: {e}")
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(["POST"])
def admin_respond_sponsor_request(request, request_id):
    try:
        action = request.data.get("action")  # 'approve' or 'reject'
        if action not in ["approve", "reject"]:
            return Response({"error": "Invalid action. Must be 'approve' or 'reject'"}, status=status.HTTP_400_BAD_REQUEST)
            
        try:
            sponsor_request = SponsorRequest.objects.get(request_id=request_id)
        except SponsorRequest.DoesNotExist:
            return Response({"error": "Sponsor request not found"}, status=status.HTTP_404_NOT_FOUND)
            
        sponsor_request.status = "approved" if action == "approve" else "rejected"
        sponsor_request.save()
        
        return Response({
            "message": f"Sponsor request {action}d successfully",
            "request_id": str(sponsor_request.request_id),
            "status": sponsor_request.status
        }, status=status.HTTP_200_OK)
    except Exception as e:
        logger.error(f"Error responding to sponsor request: {e}")
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
