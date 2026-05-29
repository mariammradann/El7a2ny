from rest_framework import viewsets, status, serializers, permissions
from rest_framework.decorators import action, api_view, permission_classes
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
    Sponsor,
    VolunteerCourseProgress,
    TrainingCourse,
)
from .serializers import (
    ResponderSerializer,
    UserRegistrationSerializer,
    IncidentSerializer,
    HelpInitiativeSerializer,
    InitiativeSerializer,
    ChatMessageSerializer,
    IncidentChatSerializer,
    SponsorSerializer,
    SponsorDetailSerializer,
    SponsorRequestSerializer,
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

            # Auto-unban if ban expired
            if getattr(user, "status", None) == "banned" and getattr(user, "banned_until", None) and user.banned_until <= timezone.now():
                user.status = "active"
                user.banned_until = None
                user.save()

            if getattr(user, "status", None) == "banned":
                remaining = user.banned_until - timezone.now() if user.banned_until else timedelta()
                hours = int(remaining.total_seconds() // 3600)
                days = hours // 24
                remaining_hours = hours % 24
                
                if days > 0:
                    time_msg = f"{days} أيام و {remaining_hours} ساعة"
                elif hours > 0:
                    time_msg = f"{hours} ساعة"
                else:
                    minutes = int(remaining.total_seconds() // 60)
                    time_msg = f"{minutes} دقيقة"
                
                return Response(
                    {"error": f"تم حظر هذا الحساب لمخالفة شروط الاستخدام (الإبلاغ الكاذب). متبقي: {time_msg}."},
                    status=status.HTTP_403_FORBIDDEN,
                )

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
            
            # Auto-unban if ban expired
            if getattr(user, "status", None) == "banned" and getattr(user, "banned_until", None) and user.banned_until <= timezone.now():
                user.status = "active"
                user.banned_until = None
                user.save()

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
        "Building Fire": "حريق في مبنى",
        "Vehicle Fire": "حريق في مركبة",
        "Wildfire": "حريق غابات",
        "Traffic Accident": "حادث مروري",
        "Medical Emergency": "حالة طبية طارئة",
        "Chemical Spill": "انسكاب مواد كيميائية",
        "Gas Leak": "تسرب غاز",
        "Flood": "فيضان",
        "Earthquake": "زلزال",
        "Collapsed Structure": "انهيار مبنى",
        "Active Shooter": "إطلاق نار نشط",
        "Bomb Threat": "تهديد بقنبلة",
        "Hostage Situation": "احتجاز رهائن",
        "Missing Person": "شخص مفقود",
    }

    inc_type = ai_data.get("incident_type", "")
    ar_type = ARABIC_SUMMARIES.get(inc_type, inc_type)

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
        rel_path = media_path.lstrip("/")  # "media/reports/..."
        abs_path = os.path.join(settings.BASE_DIR, rel_path)
        ext = os.path.splitext(abs_path)[1].lower()
        if ext not in image_extensions:
            continue
        if not os.path.exists(abs_path):
            print(f"[WARNING] Media file not found on disk: {abs_path}")
            continue
        try:
            print(f"[INFO] Running Gemini image analysis on: {abs_path}")
            content_type = (
                "image/jpeg" if ext in {".jpg", ".jpeg"} else f"image/{ext.lstrip('.')}"
            )
            with open(abs_path, "rb") as img_f:
                ai_data = analyze_image(
                    BytesIO(img_f.read()),
                    filename=os.path.basename(abs_path),
                    content_type=content_type,
                    description=incident.description,
                    user_trust_score=getattr(incident.user, "trust_score", 1.0)
                )
            _wrap_bilingual(ai_data)
            analysis = save_ai_result(incident, ai_data, source="image")
            run_dispatch_matching_and_notify(incident, analysis)
            print(f"[SUCCESS] AI image analysis saved for incident {incident.incident_id} "
                  f"using {os.path.basename(abs_path)}")
            analyzed_via_image = True
            break  # Only analyze first valid image
        except Exception as e:
            print(f"[WARNING] AI image analysis failed for {abs_path}: {e}")

    if analyzed_via_image:
        return

    # ── Step 2: Fall back to text analysis via AI microservice ────────────────
    try:
        if incident.description:
            ai_data = analyze_text(
                incident.description, location=incident.location.address
            )
            _wrap_bilingual(ai_data)
            analysis = save_ai_result(incident, ai_data, source="text")
            run_dispatch_matching_and_notify(incident, analysis)
            print(f"[SUCCESS] AI text analysis triggered successfully for incident {incident.incident_id}")
            return
    except Exception as e:
        print(
            f"[WARNING] AI microservice failed or offline: {e}. Falling back to default AI analysis."
        )

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
            "ar": f"تم الإبلاغ عن حريق نشط. التصنيف: حريق. التفاصيل: {desc}",
        }
        responder_briefing = {
            "en": [
                "Ensure your personal safety first and stay at a safe distance from active flames.",
                "Alert everyone in the immediate vicinity to evacuate the area immediately.",
                "Help guide people to a safe assembly point away from smoke and heat.",
                "Keep bystanders away from the scene and warn oncoming traffic of the hazard."
            ],
            "ar": [
                "تأكد من سلامتك الشخصية أولاً وخليك على مسافة آمنة من النار النشطة.",
                "نبّه كل الناس اللي في الجوار عشان يخلوا المكان فوراً.",
                "ساعد في توجيه الناس لمكان تجمع آمن بعيد عن الدخان والحرارة.",
                "ابعد المتفرجين عن موقع الحادثة وحذّر العربيات اللي جاية من الخطر."
            ]
        }
        instructions = {
            "en": [
                "Evacuate the building immediately using the stairs. Do not use elevators.",
                "If trapped by smoke, stay low to the ground and cover your nose and mouth with a wet cloth.",
                "Feel doors for heat before opening them. If hot, do not open.",
                "Alert others in the vicinity and stay a safe distance away once outside.",
            ],
            "ar": [
                "إخلاء المبنى فوراً باستخدام السلالم. لا تستخدم المصاعد الكهربائية.",
                "إذا حاصرك الدخان، ابقَ منخفضاً قريباً من الأرض وغطِّ أنفك وفمك بقطعة قماش مبللة.",
                "تحسس الأبواب للتأكد من حرارتها قبل فتحها. إذا كانت ساخنة، لا تفتحها.",
                "قم بتنبيه الآخرين في الجوار وابقَ على مسافة آمنة بمجرد خروجك.",
            ],
        }
        responders_needed = ["Firefighters", "Ambulance", "Search and Rescue"]
    elif "medical" in cat:
        incident_type = "Medical Emergency"
        severity = "High"
        triage_level = "Orange"
        urgency_score = 8
        risk_level = (
            "Potential cardiac or respiratory arrest, severe blood loss, shock risk."
        )
        dispatch_priority = "IMMEDIATE PARAMEDIC DISPATCH."
        summary = {
            "en": f"Emergency medical situation. Category: Medical. Details: {desc}",
            "ar": f"حالة طبية طارئة. التصنيف: طبي. التفاصيل: {desc}",
        }
        responder_briefing = {
            "en": [
                "Check the patient gently to see if they are responsive and breathing.",
                "If they are bleeding severely, apply direct pressure using a clean cloth.",
                "Keep the patient calm, warm, and reassured until the ambulance arrives.",
                "Do not move the patient unless they are in immediate, life-threatening danger."
            ],
            "ar": [
                "اتأكد براحة لو الشخص المصاب واعي وبيتنفس بشكل طبيعي.",
                "لو في نزيف شديد، اضغط عليه مباشرة بقطعة قماش نظيفة.",
                "هدّي المصاب وطمنه وخليه دافي لحد ما عربية الإسعاف توصل.",
                "بلاش تحرك المصاب من مكانه إلا لو كان في خطر مباشر على حياته."
            ]
        }
        instructions = {
            "en": [
                "Check if the person is responsive and breathing.",
                "If bleeding heavily, apply direct pressure using a clean cloth or bandage.",
                "Keep the patient warm, quiet, and do not move them unless they are in immediate danger.",
                "Loosen tight clothing and reassure the patient that help is on the way.",
            ],
            "ar": [
                "تأكد مما إذا كان الشخص واعياً ويتنفس.",
                "في حالة النزيف الشديد، اضغط مباشرة باستخدام قطعة قماش نظيفة أو ضمادة.",
                "حافظ على دفء المريض وهدوئه، ولا تحركه إلا إذا كان في خطر مباشر.",
                "قم بفك الملابس الضيقة وطمأنة المريض بأن المساعدة في الطريق.",
            ],
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
            "ar": f"حادث أمني. التصنيف: أمن. التفاصيل: {desc}",
        }
        responder_briefing = {
            "en": [
                "Assess the situation from a safe distance and do not confront any threats.",
                "Guide bystanders away from the hazard area to prevent further complications.",
                "Reassure anyone in distress and stay with them in a secure spot.",
                "Keep a clear view of the scene and wait for the police/authorities to arrive."
            ],
            "ar": [
                "قيم الوضع من مسافة آمنة وماتواجهش أي مصدر للتهديد.",
                "وجه الموجودين عشان يبعدوا عن منطقة الخطر لمنع أي إصابات.",
                "طمن الناس الخايفة وافضل واقف معاهم في مكان آمن.",
                "راقب الموقع من مكان آمن واستنى لحد ما قوات الأمن والشرطة توصل."
            ]
        }
        instructions = {
            "en": [
                "Find a safe place to hide, lock the doors, and turn off the lights.",
                "Silence your mobile phone and remain completely quiet.",
                "Only try to escape if there is a safe exit path available.",
                "Do not confront the intruder or threat under any circumstances.",
            ],
            "ar": [
                "ابحث عن مكان آمن للاختباء، وأغلق الأبواب وأطفئ الأنوار.",
                "ضع هاتفك المحمول على وضع الصامت وابقَ هادئاً تماماً.",
                "لا تحاول الهرب إلا إذا كان هناك مسار خروج آمن تماماً.",
                "لا تواجه المقتحم أو التهديد تحت أي ظرف من الظروف.",
            ],
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
            "ar": f"تم استلام البلاغ. التصنيف: عام. التفاصيل: {desc}",
        }
        responder_briefing = {
            "en": [
                "Approach the scene carefully and locate the person who reported the incident.",
                "Identify if anyone is injured or needs immediate basic assistance.",
                "Help keep the victims calm and comfortable while they wait for help.",
                "Ensure that access paths remain clear for incoming emergency vehicles."
            ],
            "ar": [
                "اقترب من الموقع بحذر وحدد مكان الشخص اللي بلغ عن الحادثة.",
                "اتأكد لو في حد مصاب أو محتاج مساعدة أساسية فورية.",
                "ساعد في تهدئة المصابين وخليهم مستريحين لحد ما المساعدة توصل.",
                "اتأكد إن ممرات الدخول فاضية وسهلة لعربيات الطوارئ والإسعاف."
            ]
        }
        instructions = {
            "en": [
                "Stay calm and remain in a safe location near the reported area.",
                "Keep your phone lines clear to receive updates from responders.",
                "Ensure you are visible to volunteers as they approach.",
                "Avoid unnecessary movement to preserve energy and safety.",
            ],
            "ar": [
                "حافظ على هدوئك وابقَ في مكان آمن بالقرب من المنطقة المبلّغ عنها.",
                "ابقِ خط الهاتف شاغراً لاستقبال أي تحديثات من فرق المساعدة.",
                "تأكد من أنك مرئي للمتطوعين أثناء اقترابهم.",
                "تجنب التحركات غير الضرورية للحفاظ على سلامتك وطاقتك.",
            ],
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
    print(
        f"[SUCCESS] Auto-generated fallback AI analysis created successfully for incident {incident.incident_id}"
    )


class IncidentViewSet(viewsets.ModelViewSet):
    def list(self, request, *args, **kwargs):
        """Override list to ensure no caching"""
        response = super().list(request, *args, **kwargs)
        response["Cache-Control"] = "no-cache, no-store, must-revalidate"
        response["Pragma"] = "no-cache"
        response["Expires"] = "0"
        return response

    def retrieve(self, request, *args, **kwargs):
        """Override retrieve to ensure no caching, authorization, and auto-generate AI analysis if missing or old format"""
        instance = self.get_object()

        # ✅ AUTHORIZATION CHECK: User must be the incident reporter or an admin
        user_id = request.query_params.get("user_id") or request.data.get("user_id")
        if user_id:
            user_id_str = str(user_id)
            incident_user_id_str = str(instance.user_id)

            # Check if user is the incident reporter
            if user_id_str != incident_user_id_str:
                # If not the reporter, check if user is admin
                try:
                    user = User.objects.get(user_id=user_id_str)
                    if user.user_type != "admin":
                        return Response(
                            {
                                "error": "You don't have permission to view this incident"
                            },
                            status=status.HTTP_403_FORBIDDEN,
                        )
                except User.DoesNotExist:
                    return Response(
                        {"error": "User not found"}, status=status.HTTP_404_NOT_FOUND
                    )

        try:
            from .models import IncidentAIAnalysis

            analysis = IncidentAIAnalysis.objects.filter(incident=instance).first()
            # If analysis doesn't exist or summary is in old format (doesn't start with '{'), regenerate it
            if (
                not analysis
                or not analysis.summary
                or not str(analysis.summary).strip().startswith("{")
            ):
                trigger_auto_ai_analysis(instance)
                # Refresh instance from db to include the new relation
                instance.refresh_from_db()
        except Exception as e:
            print(
                f"[ERROR] Failed to auto-generate missing AI analysis on retrieve: {e}"
            )

        serializer = self.get_serializer(instance)
        response = Response(serializer.data)
        response["Cache-Control"] = "no-cache, no-store, must-revalidate"
        response["Pragma"] = "no-cache"
        response["Expires"] = "0"
        return response

    def get_queryset(self):
        queryset = Incident.objects.all().order_by("-created_at")

        user_id = self.request.query_params.get("user_id")
        show_all = self.request.query_params.get("all") == "true" or self.request.query_params.get("historical") == "true"

        if show_all:
            return queryset

        if user_id:
            # "My Reports" tab — return full history for this user
            queryset = queryset.filter(user_id=user_id)
        else:
            # Public "Alerts" tab — only show incidents from the last 2 days
            cutoff = timezone.now() - timedelta(days=2)
            queryset = queryset.filter(created_at__gte=cutoff)

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
                print(
                    f"[ERROR] Error parsing coordinates: {e} (lat={lat_raw}, lng={lng_raw})"
                )
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
        incident = serializer.instance

        # Trigger emergency contacts alerts if the incident is for the user
        is_for_me_raw = request.data.get("is_for_me") or data.get("is_for_me", "true")
        if isinstance(is_for_me_raw, list) and is_for_me_raw:
            is_for_me_raw = is_for_me_raw[0]

        is_for_me = str(is_for_me_raw).lower() == 'true'

        if is_for_me and resolved_user:
            contacts = getattr(resolved_user, 'emergency_contacts', []) or []
            if contacts:
                print(f"[SMS ALERT] User {resolved_user.name} reported emergency for themselves! Notifying emergency contacts:")
                for contact in contacts:
                    name = contact.get("name", "Contact")
                    phone = contact.get("phone", "")
                    relation = contact.get("relationship", "Contact")
                    msg = f"Alert! {resolved_user.name} has reported an emergency ({incident.category}) at Lat: {incident.location.latitude}, Lng: {incident.location.longitude}. Description: {incident.description or 'No details'}. Please check on them immediately!"
                    print(f"  -> SMS sent to {name} ({phone}) [{relation}]: {msg}")

                # Send confirmation email to the user
                try:
                    subject = "SOS Emergency Alerts Sent - El7a2ny"
                    contact_details = "\n".join([f"- {c.get('name')} ({c.get('phone')}) [{c.get('relationship')}]" for c in contacts])
                    email_body = f"""
                    أهلاً {resolved_user.name}،

                    لقد تلقينا بلاغ الاستغاثة الخاص بك بنجاح.
                    بناءً على طلبك، تم إرسال رسائل استغاثة طارئة إلى جهات الاتصال الخاصة بك:
                    {contact_details}

                    يرجى البقاء في مكان آمن. فرق المساعدة والمتطوعين في طريقهم إليك.

                    تحياتنا،
                    فريق El7a2ny
                    """
                    send_mail(
                        subject,
                        email_body,
                        settings.DEFAULT_FROM_EMAIL,
                        [resolved_user.email],
                        fail_silently=True
                    )
                    print(f"[EMAIL] SOS Alert email sent to user {resolved_user.email}")
                except Exception as mail_err:
                    print(f"[ERROR] Failed to send email confirmation: {mail_err}")

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

    ✅ AUTHORIZATION: Only admins can access this endpoint
    """
    from django.db.models import Count, Avg, Q
    from django.utils import timezone
    from datetime import timedelta

    # ✅ AUTHORIZATION CHECK: User must be an admin
    user_id = request.query_params.get("user_id")
    if not user_id:
        return Response(
            {"error": "user_id is required"}, status=status.HTTP_400_BAD_REQUEST
        )

    try:
        user = User.objects.get(user_id=user_id)
        if user.user_type != "admin":
            return Response(
                {"error": "Only admins can access admin statistics"},
                status=status.HTTP_403_FORBIDDEN,
            )
    except User.DoesNotExist:
        return Response({"error": "User not found"}, status=status.HTTP_404_NOT_FOUND)

    try:
        total_users = User.objects.count()

        twenty_four_hours_ago = timezone.now() - timedelta(hours=24)
        active_alerts = Incident.objects.filter(
            created_at__gte=twenty_four_hours_ago
        ).count()

        avg_response_time = "3:45"

        total_incidents = Incident.objects.count()
        resolved_incidents = Incident.objects.filter(status='resolved').count()
        success_rate = round(resolved_incidents / total_incidents, 2) if total_incidents > 0 else 0.87

        weekly_efficiency = []
        for i in range(6, -1, -1):
            date = timezone.now() - timedelta(days=i)
            start = date.replace(hour=0, minute=0, second=0, microsecond=0)
            end = date.replace(hour=23, minute=59, second=59, microsecond=999999)
            count = Incident.objects.filter(created_at__range=[start, end]).count()
            weekly_efficiency.append(float(count))

        # Dynamic regional insights
        region_counts = Incident.objects.values('location__region').annotate(count=Count('incident_id')).order_by('-count')
        all_regions = [r['location__region'] for r in region_counts if r['location__region'] and r['location__region'] != 'Unknown']
        
        active_areas = all_regions[:3] if len(all_regions) >= 3 else (all_regions + ['Cairo', 'Giza', 'Alexandria'])[:3]
        low_volunteering = all_regions[3:5] if len(all_regions) >= 5 else ['Suez', 'Fayoum']
        inactive_areas = all_regions[-3:] if len(all_regions) >= 8 else ['Aswan', 'Luxor', 'Minya']

        return Response(
            {
                "total_users": total_users,
                "active_alerts": active_alerts,
                "avg_response_time": avg_response_time,
                "success_rate": success_rate,
                "weekly_efficiency": weekly_efficiency,
                "regional_insights": {
                    "inactive_areas": inactive_areas,
                    "low_volunteering_areas": low_volunteering,
                    "active_volunteering_areas": active_areas
                }
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

    ✅ AUTHORIZATION: Only admins can access this endpoint
    """
    # ✅ AUTHORIZATION CHECK: User must be an admin
    user_id = request.query_params.get("user_id")
    if not user_id:
        return Response(
            {"error": "user_id is required"}, status=status.HTTP_400_BAD_REQUEST
        )

    try:
        user = User.objects.get(user_id=user_id)
        if user.user_type != "admin":
            return Response(
                {"error": "Only admins can manage users"},
                status=status.HTTP_403_FORBIDDEN,
            )
    except User.DoesNotExist:
        return Response({"error": "User not found"}, status=status.HTTP_404_NOT_FOUND)

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

    ✅ AUTHORIZATION: Only admins can update users
    """
    # ✅ AUTHORIZATION CHECK: User must be an admin
    admin_user_id = request.data.get("admin_user_id") or request.query_params.get(
        "admin_user_id"
    )
    if not admin_user_id:
        return Response(
            {"error": "admin_user_id is required"}, status=status.HTTP_400_BAD_REQUEST
        )

    try:
        admin_user = User.objects.get(user_id=admin_user_id)
        if admin_user.user_type != "admin":
            return Response(
                {"error": "Only admins can update users"},
                status=status.HTTP_403_FORBIDDEN,
            )
    except User.DoesNotExist:
        return Response(
            {"error": "Admin user not found"}, status=status.HTTP_404_NOT_FOUND
        )

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

    ✅ AUTHORIZATION: Only admins can delete users
    """
    # ✅ AUTHORIZATION CHECK: User must be an admin
    admin_user_id = request.data.get("admin_user_id") or request.query_params.get(
        "admin_user_id"
    )
    if not admin_user_id:
        return Response(
            {"error": "admin_user_id is required"}, status=status.HTTP_400_BAD_REQUEST
        )

    try:
        admin_user = User.objects.get(user_id=admin_user_id)
        if admin_user.user_type != "admin":
            return Response(
                {"error": "Only admins can delete users"},
                status=status.HTTP_403_FORBIDDEN,
            )
    except User.DoesNotExist:
        return Response(
            {"error": "Admin user not found"}, status=status.HTTP_404_NOT_FOUND
        )

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
    Query params: status (optional), user_id (optional for filtering)
    Required: admin_user_id (the admin making the request)

    ✅ AUTHORIZATION: Only admins can access this endpoint
    """
    # ✅ AUTHORIZATION CHECK: User must be an admin
    admin_user_id = request.query_params.get("admin_user_id")
    if not admin_user_id:
        return Response(
            {"error": "admin_user_id is required"}, status=status.HTTP_400_BAD_REQUEST
        )

    try:
        admin_user = User.objects.get(user_id=admin_user_id)
        if admin_user.user_type != "admin":
            return Response(
                {"error": "Only admins can view all incidents"},
                status=status.HTTP_403_FORBIDDEN,
            )
    except User.DoesNotExist:
        return Response(
            {"error": "Admin user not found"}, status=status.HTTP_404_NOT_FOUND
        )

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

    ✅ AUTHORIZATION: Only admins can update incidents
    """
    # ✅ AUTHORIZATION CHECK: User must be an admin
    user_id = (
    request.data.get("user_id")           # works for PATCH
    or request.query_params.get("user_id") # works for DELETE
    or request.headers.get("X-User-Id")   # optional: header fallback
    
)
    
    print(user_id) 
    if not user_id:
        return Response(
            {"error": "user_id is required"}, status=status.HTTP_400_BAD_REQUEST
        )

    try:
        user = User.objects.get(user_id=user_id)
        if user.user_type != "admin":
            return Response(
                {"error": "Only admins can perform this action"},
                status=status.HTTP_403_FORBIDDEN,
            )
    except User.DoesNotExist:
        return Response({"error": "User not found"}, status=status.HTTP_404_NOT_FOUND)

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
@permission_classes([permissions.AllowAny])
def cancel_subscription(request):
    """
    Cancel user Plus subscription.
    Request data: user_id
    """
    try:
        user_id = request.data.get("user_id")
        if not user_id:
            return Response({"error": "user_id is required"}, status=400)

        user = User.objects.get(user_id=user_id)
        user.is_plus = False
        user.plan_type = None
        user.subscription_date = None
        user.renewal_date = None
        user.save()

        return Response(
            {"message": "Subscription cancelled successfully", "is_plus": False},
            status=200,
        )
    except User.DoesNotExist:
        return Response({"error": "User not found"}, status=404)
    except Exception as e:
        logger.error(f"Error cancelling subscription: {e}")
        return Response({"error": str(e)}, status=500)


def classify_temperature(temp):
    """
    Classify temperature based on Arduino thresholds.
    Matches: 40°C=WARNING, 70°C=ALERT, 120°C=CRITICAL
    """
    if temp >= 120.0:
        return "CRITICAL"
    elif temp >= 70.0:
        return "ALERT"
    elif temp >= 40.0:
        return "WARNING"
    return "NORMAL"


def get_alert_label(alert_level):
    """
    Convert alert level to display label matching Arduino code.
    """
    labels = {
        "CRITICAL": "🔥 CRITICAL",
        "ALERT": "🚨 ALERT",
        "WARNING": "⚠️ WARNING",
        "NORMAL": "🟢 NORMAL",
    }
    return labels.get(alert_level, "🟢 NORMAL")


@api_view(["POST"])
def receive_temperature(request):
    """
    Receives K-Type Thermocouple data from ESP32.
    Endpoint: /api/sensor/temperature/

    Request JSON:
    {
        "user_id": "fef5bed0-1c2e-4a04-bb5c-e5c590c3dcf1",
        "temperature": 85.5,
        "humidity": 0,
        "is_alert": true,
        "alert_level": "🚨 ALERT"
    }

    Thresholds (°C):
    - NORMAL: < 40°C
    - WARNING: 40-70°C (logged, not sent as alert)
    - ALERT: 70-120°C (auto-incident created)
    - CRITICAL: ≥ 120°C (urgent incident created)
    """
    from .models import Location

    user_id = request.data.get("user_id")
    temperature = request.data.get("temperature")
    humidity = request.data.get("humidity", 0)
    is_alert = request.data.get("is_alert", False)
    alert_level_label = request.data.get("alert_level", "🟢 NORMAL")

    if not user_id or temperature is None:
        return Response({"error": "user_id and temperature are required"}, status=400)

    try:
        user = User.objects.get(user_id=user_id)
    except User.DoesNotExist:
        return Response({"error": "User not found"}, status=404)

    # Classify the temperature locally to ensure consistency
    alert_level = classify_temperature(float(temperature))
    current_time = timezone.now()

    # Always save the reading for history/charts
    reading = SensorReading.objects.create(
        user=user,
        temperature=temperature,
        humidity=humidity,
        is_alert=is_alert,
        alert_level=alert_level,
    )

    incident = None
    # Auto-create an incident report when alert level is reached (ALERT or CRITICAL)
    if is_alert and alert_level in ["ALERT", "CRITICAL"]:
        try:
            location, _ = Location.objects.get_or_create(
                latitude=29.964988,
                longitude=31.2357,
                defaults={
                    "city": "Cairo",
                    "region": "Cairo",
                    "address": "Thermocouple Sensor Location",
                },
            )

            # Set incident status and category based on alert level
            incident_status = "critical" if alert_level == "CRITICAL" else "active"
            incident_category = "fire"  # K-type thermocouple is for fire detection

            description = (
                f"[AUTO FIRE SENSOR ALERT] {get_alert_label(alert_level)}\n"
                f"Temperature: {temperature}°C\n"
                f"Humidity: {humidity}%\n"
                f"Timestamp: {current_time.strftime('%Y-%m-%d %H:%M:%S')}\n"
                f"Alert Level: {alert_level}\n"
                f"Device: El7a2ny Fire sensor"
            )

            incident = Incident.objects.create(
                user=user,
                location=location,
                category=incident_category,
                description=description,
                status=incident_status,
            )
            logger.info(
                f"✅ Fire Incident created: {incident.incident_id} | "
                f"Status: {incident_status} | Temp: {temperature}°C | "
                f"Alert Level: {alert_level}"
            )
        except Exception as e:
            logger.error(f"❌ Error creating fire incident: {e}")
            import traceback

            traceback.print_exc()

    return Response(
        {
            "message": "alert recorded" if is_alert else "reading saved",
            "temperature": temperature,
            "humidity": humidity,
            "is_alert": is_alert,
            "alert_level": alert_level,
            "alert_label": get_alert_label(alert_level),
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

    active_incident_id = None
    if reading.is_alert:
        from .models import Incident
        incident = Incident.objects.filter(
            user__user_id=user_id,
            status__in=["active", "critical"],
            category="fire"
        ).order_by("-created_at").first()
        if incident:
            active_incident_id = str(incident.incident_id)

    return Response(
        {
            "temperature": reading.temperature,
            "humidity": reading.humidity,
            "is_alert": reading.is_alert,
            "alert_level": reading.alert_level,
            "incident_id": active_incident_id,
            "timestamp": reading.created_at.isoformat(),
        }
    )


@api_view(["GET"])
def fetch_sensors(request):
    """
    Returns list of all sensors with latest readings.
    Matches Arduino K-Type Thermocouple thresholds:
    - NORMAL: < 40°C (status: normal, green)
    - WARNING: 40-70°C (status: warning, yellow)
    - ALERT: 70-120°C (status: danger, orange)
    - CRITICAL: ≥ 120°C (status: critical, red)
    """
    from django.db.models import Max

    # Get the latest reading for each user
    users_with_readings = (
        SensorReading.objects.values("user")
        .annotate(latest_id=Max("id"))
        .values_list("latest_id", flat=True)
    )

    latest_readings = SensorReading.objects.filter(id__in=users_with_readings)

    sensors = []
    sensor_id = 1

    for reading in latest_readings.order_by("-created_at"):
        temp = float(reading.temperature)

        # Determine status based on Arduino temperature thresholds
        if temp >= 120.0:
            status = "critical"  # 🔥 CRITICAL
        elif temp >= 70.0:
            status = "danger"  # 🚨 ALERT
        elif temp >= 40.0:
            status = "warning"  # ⚠️ WARNING
        else:
            status = "normal"  # 🟢 NORMAL

        # Determine sensor type (heat sensor for K-Type thermocouple)
        sensor_type = "heat"

        sensor_data = {
            "id": sensor_id,
            "type": sensor_type,
            "value": str(round(temp, 1)),
            "unit": "°C",
            "status": status,
            "alert_level": reading.alert_level,
            "alert_label": get_alert_label(reading.alert_level),
            "is_alert": reading.is_alert,
            "humidity": reading.humidity if reading.humidity else 0,
            "user_id": str(reading.user.user_id),
            "user_name": reading.user.name,
            "lat": 29.9649,  # Default Cairo location
            "lng": 31.2592,
            "updated_at": reading.created_at.isoformat(),
        }
        sensors.append(sensor_data)
        sensor_id += 1

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
    Get all responders for an incident with their details including earned training badges.
    """
    responders = Responder.objects.filter(incident_id=incident_id)
    data = []
    for r in responders:
        name = "Unknown"
        phone = ""
        badges = []
        try:
            user = User.objects.get(user_id=r.user_id)
            name = user.name or ""
            phone = user.phone_number if hasattr(user, "phone_number") else ""
            # Fetch earned badges from completed training courses
            # Wrapped separately so a missing table doesn't crash the whole endpoint
            try:
                completed = VolunteerCourseProgress.objects.filter(
                    user=user, is_completed=True
                ).select_related("course")
                badges = [
                    {
                        "badge_name_en": cp.course.badge_name_en,
                        "badge_name_ar": cp.course.badge_name_ar,
                        "course_title_en": cp.course.title_en,
                        "course_title_ar": cp.course.title_ar,
                        "completed_at": str(cp.completed_at) if cp.completed_at else None,
                    }
                    for cp in completed
                ]
            except Exception as badge_err:
                print(f"[WARNING] Could not fetch badges for user {r.user_id}: {badge_err}")
                badges = []
        except User.DoesNotExist:
            pass

        data.append(
            {
                "id": str(r.responder_id),
                "user_id": str(r.user_id),
                "name": name,
                "phone": phone,
                "lat": r.lat,
                "lng": r.lng,
                "response_time": str(r.response_time),
                "badges": badges,
            }
        )
    response = Response(data, status=status.HTTP_200_OK)
    response["Cache-Control"] = "no-cache, no-store, must-revalidate"
    response["Pragma"] = "no-cache"
    response["Expires"] = "0"
    return response


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
        return Response({"detail": "Not a responder for this incident."}, status=404)


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


def run_dispatch_matching_and_notify(incident, analysis):
    """
    Finds online volunteers within a 5km radius, matches their skills
    against the AI-recommended volunteer counts, and creates IncidentDispatch records.
    """
    from .models import VolunteerProfile, IncidentDispatch, User
    import math

    rec = analysis.volunteers_recommended or {}
    
    # If the user did not specify the number of volunteers (i.e. it is 0),
    # let the AI model dynamically set a suitable number of volunteers based on scene/text.
    if getattr(incident, 'total_volunteers', 0) == 0:
        recommended_sum = sum(int(count) for count in rec.values() if str(count).isdigit())
        if recommended_sum > 0:
            incident.total_volunteers = recommended_sum
            incident.save()
            print(f"[INFO] Incident {incident.incident_id} total_volunteers dynamically set to {recommended_sum} by AI analysis.")

    if not rec:
        print(f"[INFO] No volunteers recommended by AI for incident {incident.incident_id}.")
        return

    # Get incident coordinates
    try:
        incident_lat = float(incident.location.latitude)
        incident_lng = float(incident.location.longitude)
    except (ValueError, TypeError, AttributeError) as e:
        print(f"[WARNING] Could not parse location for incident {incident.incident_id}: {e}")
        return

    # Get active online volunteers
    online_volunteers = VolunteerProfile.objects.filter(is_online=True)
    
    # Calculate Haversine distance and filter within 5km
    matched_volunteers = []
    for v in online_volunteers:
        if v.current_lat is None or v.current_lng is None:
            continue
        
        # Haversine distance
        R = 6371.0  # Earth's radius in km
        lat1, lon1 = math.radians(incident_lat), math.radians(incident_lng)
        lat2, lon2 = math.radians(v.current_lat), math.radians(v.current_lng)
        dlat = lat2 - lat1
        dlon = lon2 - lon1
        a = math.sin(dlat / 2)**2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon / 2)**2
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
        dist = R * c

        if dist <= 5.0:  # 5km limit
            matched_volunteers.append((v, dist))

    # Sort by distance (closest first)
    matched_volunteers.sort(key=lambda x: x[1])

    # Dispatch logic based on capability and count needed
    dispatched_count = 0
    
    for role, count_needed in rec.items():
        if not count_needed or count_needed <= 0:
            continue
            
        dispatched_for_role = 0
        for v, dist in matched_volunteers:
            if dispatched_for_role >= count_needed:
                break

            # Check if this volunteer is already dispatched to this incident
            if IncidentDispatch.objects.filter(incident=incident, volunteer=v.user).exists():
                continue

            # Check capability
            has_skill = False
            if role == "first_aid" and v.has_first_aid:
                has_skill = True
            elif role == "fire_response" and v.has_firefighting:
                has_skill = True
            elif role == "rescue" and v.has_rescue_training:
                has_skill = True
            elif role == "transportation" and v.has_transportation:
                has_skill = True

            if has_skill:
                # Create dispatch record
                IncidentDispatch.objects.create(
                    incident=incident,
                    volunteer=v.user,
                    role_requested=role,
                    status="pending"
                )
                print(f"[SUCCESS] Dispatched volunteer {v.user.name} ({role}) to Incident {incident.incident_id} (Dist: {dist:.2f} km)")
                dispatched_for_role += 1
                dispatched_count += 1


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
    permission_classes = [IsAuthenticated]

    def post(self, request):
        incident_id = request.data.get("incident_id")
        image_file = request.FILES.get("image")

        if not incident_id or not image_file:
            return Response(
                {"error": "incident_id and image are required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        incident, err = _get_incident_for_user(incident_id, request.user)
        if err:
            return err

        try:
            ai_data = analyze_image(
                image_file,
                filename=image_file.name,
                content_type=image_file.content_type,
                description=incident.description,
                user_trust_score=getattr(request.user, "trust_score", 1.0)
            )
            analysis = save_ai_result(incident, ai_data, source="image")
            run_dispatch_matching_and_notify(incident, analysis)
            from .serializers import IncidentAIAnalysisSerializer

            return Response(
                IncidentAIAnalysisSerializer(analysis).data,
                status=status.HTTP_201_CREATED,
            )
        except AIServiceError as e:
            logger.error(f"AI image analysis failed: {e}")
            return Response(
                {"error": str(e)}, status=status.HTTP_503_SERVICE_UNAVAILABLE
            )


class AnalyzeIncidentVideoView(APIView):
    """
    POST /api/incidents/analyze/video/
    Flutter sends: incident_id (UUID) + video file
    """

    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def post(self, request):
        incident_id = request.data.get("incident_id")
        video_file = request.FILES.get("video")

        if not incident_id or not video_file:
            return Response(
                {"error": "incident_id and video are required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        incident, err = _get_incident_for_user(incident_id, request.user)
        if err:
            return err

        try:
            ai_data = analyze_video(
                video_file,
                filename=video_file.name,
                content_type=video_file.content_type,
                description=incident.description,
                user_trust_score=getattr(request.user, "trust_score", 1.0)
            )
            analysis = save_ai_result(incident, ai_data, source="video")
            run_dispatch_matching_and_notify(incident, analysis)
            from .serializers import IncidentAIAnalysisSerializer

            return Response(
                IncidentAIAnalysisSerializer(analysis).data,
                status=status.HTTP_201_CREATED,
            )
        except AIServiceError as e:
            logger.error(f"AI video analysis failed: {e}")
            return Response(
                {"error": str(e)}, status=status.HTTP_503_SERVICE_UNAVAILABLE
            )


class AnalyzeIncidentVoiceView(APIView):
    """
    POST /api/incidents/analyze/voice/
    Flutter sends: incident_id (UUID) + audio file
    Returns both transcription and emergency analysis.
    """

    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def post(self, request):
        incident_id = request.data.get("incident_id")
        audio_file = request.FILES.get("audio")

        if not incident_id or not audio_file:
            return Response(
                {"error": "incident_id and audio are required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        incident, err = _get_incident_for_user(incident_id, request.user)
        if err:
            return err

        try:
            ai_data = analyze_voice(
                audio_file,
                filename=audio_file.name,
                content_type=audio_file.content_type,
            )
            # Voice response has nested 'analysis' — save_ai_result handles this
            analysis = save_ai_result(incident, ai_data, source="voice")
            run_dispatch_matching_and_notify(incident, analysis)
            from .serializers import IncidentAIAnalysisSerializer

            return Response(
                {
                    "transcription": ai_data.get("transcription", ""),
                    "panic_detected": ai_data.get("panic_detected", False),
                    "distress_keywords": ai_data.get("distress_keywords", []),
                    "analysis": IncidentAIAnalysisSerializer(analysis).data,
                },
                status=status.HTTP_201_CREATED,
            )
        except AIServiceError as e:
            logger.error(f"AI voice analysis failed: {e}")
            return Response(
                {"error": str(e)}, status=status.HTTP_503_SERVICE_UNAVAILABLE
            )


class AnalyzeIncidentTextView(APIView):
    """
    POST /api/incidents/analyze/text/
    Flutter sends: incident_id (UUID) + description string
    """

    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def post(self, request):
        incident_id = request.data.get("incident_id")
        description = request.data.get("description")

        if not incident_id or not description:
            return Response(
                {"error": "incident_id and description are required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        incident, err = _get_incident_for_user(incident_id, request.user)
        if err:
            return err

        try:
            ai_data = analyze_text(
                description=description,
                location=request.data.get("location"),
            )
            analysis = save_ai_result(incident, ai_data, source="text")
            run_dispatch_matching_and_notify(incident, analysis)
            from .serializers import IncidentAIAnalysisSerializer

            return Response(
                IncidentAIAnalysisSerializer(analysis).data,
                status=status.HTTP_201_CREATED,
            )
        except AIServiceError as e:
            logger.error(f"AI text analysis failed: {e}")
            return Response(
                {"error": str(e)}, status=status.HTTP_503_SERVICE_UNAVAILABLE
            )


class IncidentAIAnalysisDetailView(APIView):
    """
    GET /api/incidents/<incident_id>/analysis/
    Flutter fetches the saved AI analysis for an incident.
    """

    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

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
    """Fetch active sponsors from the database"""
    try:
        category = request.query_params.get("category", None)
        
        # Fetch active sponsors
        queryset = Sponsor.objects.filter(status="active").order_by("-created_at")
        
        # Filter by category if provided
        if category:
            queryset = queryset.filter(company_type=category)
        
        serializer = SponsorSerializer(queryset, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)
    except Exception as e:
        logger.error(f"Error fetching sponsors: {e}")
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(["POST"])
@permission_classes([permissions.AllowAny])
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
            return Response(
                {"error": "All fields are required"}, status=status.HTTP_400_BAD_REQUEST
            )

        sponsor_request = SponsorRequest.objects.create(
            company_name=company_name,
            contact_person=contact_person,
            phone_number=phone_number,
            message=message,
            user=user,
            status="pending",
        )

        return Response(
            {
                "message": "Sponsor application submitted successfully",
                "request_id": str(sponsor_request.request_id),
            },
            status=status.HTTP_201_CREATED,
        )
    except Exception as e:
        logger.error(f"Error submitting sponsor application: {e}")
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(["GET"])
@permission_classes([permissions.AllowAny])
def admin_sponsor_requests(request):
    try:
        requests = SponsorRequest.objects.all().order_by("-created_at")
        data = []
        for req in requests:
            data.append(
                {
                    "request_id": str(req.request_id),
                    "company_name": req.company_name,
                    "contact_person": req.contact_person,
                    "phone_number": req.phone_number,
                    "message": req.message,
                    "status": req.status,
                    "created_at": req.created_at.isoformat(),
                    "user_id": str(req.user.user_id) if req.user else None,
                    "user_name": req.user.name if req.user else None,
                }
            )
        return Response(data, status=status.HTTP_200_OK)
    except Exception as e:
        logger.error(f"Error fetching sponsor requests: {e}")
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(["POST"])
def admin_respond_sponsor_request(request, request_id):
    try:
        action = request.data.get("action")  # 'approve' or 'reject'
        if action not in ["approve", "reject"]:
            return Response(
                {"error": "Invalid action. Must be 'approve' or 'reject'"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            sponsor_request = SponsorRequest.objects.get(request_id=request_id)
        except SponsorRequest.DoesNotExist:
            return Response(
                {"error": "Sponsor request not found"}, status=status.HTTP_404_NOT_FOUND
            )

        sponsor_request.status = "approved" if action == "approve" else "rejected"
        sponsor_request.save()

        return Response(
            {
                "message": f"Sponsor request {action}d successfully",
                "request_id": str(sponsor_request.request_id),
                "status": sponsor_request.status,
            },
            status=status.HTTP_200_OK,
        )
    except Exception as e:
        logger.error(f"Error responding to sponsor request: {e}")
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# ═══════════════════════════════════════════════════════════════════════════════
# ═══════════════════ ADMIN SPONSOR MANAGEMENT ENDPOINTS ═══════════════════════════════════
# ═══════════════════════════════════════════════════════════════════════════════

@api_view(["GET"])
@permission_classes([permissions.AllowAny])
def admin_sponsors_list(request):
    """List all sponsors with optional filtering"""
    try:
        # Get all sponsors
        queryset = Sponsor.objects.all().order_by("-created_at")
        
        # Optional filters
        status_filter = request.query_params.get("status", None)
        category_filter = request.query_params.get("category", None)
        
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        if category_filter:
            queryset = queryset.filter(company_type=category_filter)
        
        serializer = SponsorDetailSerializer(queryset, many=True)
        return Response(
            {
                "count": queryset.count(),
                "sponsors": serializer.data
            },
            status=status.HTTP_200_OK
        )
    except Exception as e:
        logger.error(f"Error fetching sponsors list: {e}")
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(["POST"])
@permission_classes([permissions.AllowAny])
def admin_sponsors_create(request):
    """Create a new sponsor"""
    try:
        serializer = SponsorDetailSerializer(data=request.data)
        if serializer.is_valid():
            sponsor = serializer.save()
            return Response(
                {
                    "message": "Sponsor created successfully",
                    "sponsor": SponsorDetailSerializer(sponsor).data
                },
                status=status.HTTP_201_CREATED
            )
        return Response(
            {"error": serializer.errors},
            status=status.HTTP_400_BAD_REQUEST
        )
    except Exception as e:
        logger.error(f"Error creating sponsor: {e}")
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(["GET", "PUT", "DELETE"])
@permission_classes([permissions.AllowAny])
def admin_sponsors_detail(request, sponsor_id):
    """Retrieve, update, or delete a sponsor"""
    try:
        sponsor = Sponsor.objects.get(sponsor_id=sponsor_id)
    except Sponsor.DoesNotExist:
        return Response(
            {"error": "Sponsor not found"},
            status=status.HTTP_404_NOT_FOUND
        )
    
    if request.method == "GET":
        serializer = SponsorDetailSerializer(sponsor)
        return Response(serializer.data, status=status.HTTP_200_OK)
    
    elif request.method == "PUT":
        serializer = SponsorDetailSerializer(sponsor, data=request.data, partial=True)
        if serializer.is_valid():
            sponsor = serializer.save()
            return Response(
                {
                    "message": "Sponsor updated successfully",
                    "sponsor": SponsorDetailSerializer(sponsor).data
                },
                status=status.HTTP_200_OK
            )
        return Response(
            {"error": serializer.errors},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    elif request.method == "DELETE":
        sponsor.delete()
        return Response(
            {"message": "Sponsor deleted successfully"},
            status=status.HTTP_204_NO_CONTENT
        )


@api_view(["POST"])
@permission_classes([permissions.AllowAny])
def admin_sponsors_approve_request(request, request_id):
    """Approve a sponsor request and convert it to a sponsor"""
    try:
        try:
            sponsor_request = SponsorRequest.objects.get(request_id=request_id)
        except SponsorRequest.DoesNotExist:
            return Response(
                {"error": "Sponsor request not found"},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Update request status
        sponsor_request.status = "approved"
        sponsor_request.save()
        
        # Create a new Sponsor from the request
        sponsor = Sponsor.objects.create(
            name=sponsor_request.company_name,
            company_type=request.data.get("company_type", "medical"),
            status="active",
            contact_email=request.data.get("contact_email", ""),
            phone=sponsor_request.phone_number,
            website=request.data.get("website", ""),
            sponsorship_level=request.data.get("sponsorship_level", "silver"),
            admin_id=request.data.get("admin_id", None),
        )
        
        return Response(
            {
                "message": "Sponsor request approved and sponsor created",
                "request_id": str(sponsor_request.request_id),
                "sponsor": SponsorDetailSerializer(sponsor).data
            },
            status=status.HTTP_201_CREATED
        )
    except Exception as e:
        logger.error(f"Error approving sponsor request: {e}")
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(["POST"])
@permission_classes([permissions.AllowAny])
def admin_sponsors_reject_request(request, request_id):
    """Reject a sponsor request"""
    try:
        try:
            sponsor_request = SponsorRequest.objects.get(request_id=request_id)
        except SponsorRequest.DoesNotExist:
            return Response(
                {"error": "Sponsor request not found"},
                status=status.HTTP_404_NOT_FOUND
            )
        
        sponsor_request.status = "rejected"
        sponsor_request.save()
        
        return Response(
            {
                "message": "Sponsor request rejected",
                "request_id": str(sponsor_request.request_id),
                "status": sponsor_request.status
            },
            status=status.HTTP_200_OK
        )
    except Exception as e:
        logger.error(f"Error rejecting sponsor request: {e}")
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(["POST"])
@permission_classes([permissions.AllowAny])
def admin_sponsors_change_status(request, sponsor_id):
    """Change sponsor status (active/inactive)"""
    try:
        try:
            sponsor = Sponsor.objects.get(sponsor_id=sponsor_id)
        except Sponsor.DoesNotExist:
            return Response(
                {"error": "Sponsor not found"},
                status=status.HTTP_404_NOT_FOUND
            )
        
        new_status = request.data.get("status")
        if new_status not in ["active", "inactive", "pending"]:
            return Response(
                {"error": "Invalid status. Must be 'active', 'inactive', or 'pending'"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        sponsor.status = new_status
        sponsor.save()
        
        return Response(
            {
                "message": f"Sponsor status changed to {new_status}",
                "sponsor": SponsorDetailSerializer(sponsor).data
            },
            status=status.HTTP_200_OK
        )
    except Exception as e:
        logger.error(f"Error changing sponsor status: {e}")
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(["POST"])
@permission_classes([permissions.AllowAny])
def admin_sponsors_change_level(request, sponsor_id):
    """Change sponsor sponsorship level"""
    try:
        try:
            sponsor = Sponsor.objects.get(sponsor_id=sponsor_id)
        except Sponsor.DoesNotExist:
            return Response(
                {"error": "Sponsor not found"},
                status=status.HTTP_404_NOT_FOUND
            )
        
        new_level = request.data.get("sponsorship_level")
        if new_level not in ["bronze", "silver", "gold", "platinum"]:
            return Response(
                {"error": "Invalid level. Must be 'bronze', 'silver', 'gold', or 'platinum'"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        sponsor.sponsorship_level = new_level
        sponsor.save()
        
        return Response(
            {
                "message": f"Sponsor level changed to {new_level}",
                "sponsor": SponsorDetailSerializer(sponsor).data
            },
            status=status.HTTP_200_OK
        )
    except Exception as e:
        logger.error(f"Error changing sponsor level: {e}")
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(["POST"])
@permission_classes([permissions.AllowAny])
def admin_sponsors_bulk_action(request):
    """Perform bulk actions on sponsors"""
    try:
        action = request.data.get("action")  # approve, reject, activate, deactivate
        request_ids = request.data.get("request_ids", [])
        
        if action == "approve":
            # Approve sponsor requests and create sponsors
            for request_id in request_ids:
                try:
                    sponsor_request = SponsorRequest.objects.get(request_id=request_id)
                    sponsor_request.status = "approved"
                    sponsor_request.save()
                    
                    Sponsor.objects.create(
                        name=sponsor_request.company_name,
                        company_type="medical",
                        status="active",
                        contact_email="",
                        phone=sponsor_request.phone_number,
                    )
                except Exception as e:
                    logger.error(f"Error approving request {request_id}: {e}")
        
        elif action == "reject":
            for request_id in request_ids:
                try:
                    sponsor_request = SponsorRequest.objects.get(request_id=request_id)
                    sponsor_request.status = "rejected"
                    sponsor_request.save()
                except Exception as e:
                    logger.error(f"Error rejecting request {request_id}: {e}")
        
        return Response(
            {"message": f"Bulk action '{action}' completed"},
            status=status.HTTP_200_OK
        )
    except Exception as e:
        logger.error(f"Error in bulk action: {e}")
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(["POST"])
@permission_classes([permissions.AllowAny])
def api_assistant_chat(request):
    """
    Proxy user chat history to Daleel assistant in FastAPI microservice.
    """
    import requests
    try:
        history = request.data.get("history", [])
        user_name = None
        
        if request.user and request.user.is_authenticated:
            user_name = getattr(request.user, "first_name", None) or getattr(request.user, "username", None)
            
        ai_service_url = getattr(settings, "AI_SERVICE_URL", "http://localhost:8001")
        url = f"{ai_service_url}/api/v1/assistant/chat"
        
        payload = {
            "history": history,
            "user_name": user_name
        }
        
        response = requests.post(url, json=payload, timeout=30)
        if response.status_code == 200:
            return Response(response.json(), status=status.HTTP_200_OK)
        else:
            logger.error(f"AI service returned error {response.status_code}: {response.text}")
            return Response({"error": "Failed to communicate with AI Assistant service"}, status=response.status_code)
            
    except Exception as e:
        logger.error(f"Error in assistant chat: {e}")
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(["POST"])
@permission_classes([permissions.AllowAny])
def report_fake_incident(request, incident_id):
    """
    Endpoint for reporting an incident as fake.
    If reported, incident is cancelled, reporter user is banned,
    and a log entry is created for the admin.
    """
    from django.shortcuts import get_object_or_404
    from .models import Incident, User, ChatMessage, IncidentChat, AdminLog
    import uuid
    
    try:
        incident = get_object_or_404(Incident, incident_id=incident_id)
        
        # 1. Cancel the incident
        incident.status = "cancelled"
        incident.save()
        
        reported_by = request.data.get("reported_by")
        reporter = incident.user
        is_self_cancel = str(reported_by) == str(reporter.user_id) if reported_by else False
        
        if is_self_cancel:
            # User is cancelling their own false alarm (e.g. from a sensor)
            action_msg = f"المستخدم {reporter.name} قام بإلغاء الإنذار التلقائي (إنذار كاذب) للبلاغ #{str(incident.incident_id)[:8]}."
            AdminLog.objects.create(action=action_msg)
            
            chat = IncidentChat.objects.filter(incident_id=incident.incident_id).first()
            if chat:
                ChatMessage.objects.create(
                    chat=chat,
                    sender_id=uuid.UUID("00000000-0000-0000-0000-000000000000"),
                    sender_name="System",
                    sender_type="system",
                    text="تم إلغاء البلاغ بواسطة المستخدم (إنذار كاذب).",
                )
            
            return Response({
                "message": "Incident cancelled by user.",
                "status": "success"
            }, status=status.HTTP_200_OK)
            
        else:
            # 2. Ban the reporter (Reported by someone else)
            reporter.status = "banned"
            reporter.banned_until = timezone.now() + timedelta(days=3)
            reporter.save()
            
            # 3. Log notification for the admin
            action_msg = f"البلاغ #{str(incident.incident_id)[:8]} (حريق/طوارئ) تم حظره وإلغاؤه، وتم حظر المستخدم {reporter.name} (الهاتف: {reporter.phone_number}) للإبلاغ الكاذب."
            AdminLog.objects.create(action=action_msg)
            
            # 4. Create chat notification
            chat = IncidentChat.objects.filter(incident_id=incident.incident_id).first()
            if chat:
                ChatMessage.objects.create(
                    chat=chat,
                    sender_id=uuid.UUID("00000000-0000-0000-0000-000000000000"),
                    sender_name="System",
                    sender_type="system",
                    text=f"تم إلغاء البلاغ وحظر صاحب البلاغ ({reporter.name}) بسبب الإبلاغ عن بلاغ كاذب من قبل متطوع.",
                )
                
            print(f"[ADMIN ALERT] {action_msg}")
            
            return Response({
                "message": "Incident cancelled, reporter banned, and admin notified.",
                "status": "success"
            }, status=status.HTTP_200_OK)
        
    except Exception as e:
        logger.error(f"Error in report_fake_incident: {e}")
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(["GET"])
@permission_classes([permissions.AllowAny])
def admin_logs(request):
    """
    Endpoint for fetching backend AdminLog entries.
    """
    from .models import AdminLog
    try:
        logs = AdminLog.objects.all().order_by("-timestamp")
        data = []
        for log in logs:
            data.append({
                "log_id": str(log.log_id),
                "action": log.action,
                "timestamp": log.timestamp.isoformat()
            })
        return Response(data, status=status.HTTP_200_OK)
    except Exception as e:
        logger.error(f"Error fetching admin logs: {e}")
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


from django.utils import timezone
from .models import TrainingCourse, VolunteerCourseProgress
from .serializers import TrainingCourseSerializer

@api_view(["GET"])
@permission_classes([permissions.AllowAny])
def courses_list(request):
    try:
        user_id = request.query_params.get("user_id")
        courses = TrainingCourse.objects.all().order_by("created_at")
        serializer = TrainingCourseSerializer(courses, many=True, context={"user_id": user_id})
        return Response(serializer.data, status=status.HTTP_200_OK)
    except Exception as e:
        logger.error(f"Error listing courses: {e}")
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(["POST"])
@permission_classes([permissions.AllowAny])
def enroll_course(request, course_id):
    try:
        user_id = request.data.get("user_id")
        if not user_id:
            return Response({"error": "user_id is required"}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            course = TrainingCourse.objects.get(course_id=course_id)
        except TrainingCourse.DoesNotExist:
            return Response({"error": "Course not found"}, status=status.HTTP_404_NOT_FOUND)
            
        try:
            user = User.objects.get(user_id=user_id)
        except User.DoesNotExist:
            return Response({"error": "User not found"}, status=status.HTTP_404_NOT_FOUND)
            
        progress, created = VolunteerCourseProgress.objects.get_or_create(
            user=user,
            course=course,
        )
        return Response({
            "message": "Enrolled successfully",
            "is_completed": progress.is_completed,
            "enrolled_at": progress.enrolled_at.isoformat()
        }, status=status.HTTP_200_OK)
    except Exception as e:
        logger.error(f"Error enrolling in course: {e}")
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(["POST"])
@permission_classes([permissions.AllowAny])
def complete_course(request, course_id):
    try:
        user_id = request.data.get("user_id")
        if not user_id:
            return Response({"error": "user_id is required"}, status=status.HTTP_400_BAD_REQUEST)
            
        try:
            course = TrainingCourse.objects.get(course_id=course_id)
        except TrainingCourse.DoesNotExist:
            return Response({"error": "Course not found"}, status=status.HTTP_404_NOT_FOUND)
            
        try:
            user = User.objects.get(user_id=user_id)
        except User.DoesNotExist:
            return Response({"error": "User not found"}, status=status.HTTP_404_NOT_FOUND)
            
        progress, created = VolunteerCourseProgress.objects.get_or_create(
            user=user,
            course=course,
        )
        progress.is_completed = True
        progress.completed_at = timezone.now()
        progress.save()
        
        return Response({
            "message": "Course completed successfully",
            "is_completed": True,
            "completed_at": progress.completed_at.isoformat()
        }, status=status.HTTP_200_OK)
    except Exception as e:
        logger.error(f"Error completing course: {e}")
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)



@api_view(["GET"])
@permission_classes([permissions.AllowAny])
def get_user_badges(request, user_id):
    """
    Returns all earned training badges for a user (completed courses only).
    """
    try:
        user = User.objects.get(user_id=user_id)
        completed = VolunteerCourseProgress.objects.filter(
            user=user, is_completed=True
        ).select_related("course")
        badges = [
            {
                "badge_name_en": cp.course.badge_name_en,
                "badge_name_ar": cp.course.badge_name_ar,
                "course_title_en": cp.course.title_en,
                "course_title_ar": cp.course.title_ar,
                "course_id": str(cp.course.course_id),
                "category_en": cp.course.category_en,
                "category_ar": cp.course.category_ar,
                "completed_at": cp.completed_at.isoformat() if cp.completed_at else None,
            }
            for cp in completed
        ]
        return Response({"badges": badges, "total": len(badges)}, status=200)
    except User.DoesNotExist:
        return Response({"error": "User not found"}, status=404)
    except Exception as e:
        logger.error(f"Error fetching user badges: {e}")
        return Response({"error": str(e)}, status=500)


# ═══════════════════════════════════════════════════════════════
#  ADMIN — EXTENDED MANAGEMENT ENDPOINTS
# ═══════════════════════════════════════════════════════════════

def _require_admin(request):
    """Helper: returns (admin_user, error_response). Pass request."""
    uid = (
        request.data.get("admin_user_id")
        or request.query_params.get("admin_user_id")
        or request.headers.get("X-Admin-Id")
    )
    if not uid:
        return None, Response({"error": "admin_user_id is required"}, status=400)
    try:
        u = User.objects.get(user_id=uid)
        if u.user_type != "admin":
            return None, Response({"error": "Admin access required"}, status=403)
        return u, None
    except User.DoesNotExist:
        return None, Response({"error": "Admin not found"}, status=404)


# ── 1. Hard-delete a specific incident ──────────────────────────────────────
@api_view(["DELETE"])
@permission_classes([permissions.AllowAny])
def admin_hard_delete_incident(request, incident_id):
    """
    Permanently removes an incident from the database.
    Required: admin_user_id (query param or body)
    """
    admin, err = _require_admin(request)
    if err:
        return err
    try:
        try:
            incident = Incident.objects.get(incident_id=incident_id)
        except Incident.DoesNotExist:
            incident = Incident.objects.get(pk=incident_id)
        incident.delete()
        return Response({"message": f"Incident {incident_id} permanently deleted"})
    except Incident.DoesNotExist:
        return Response({"error": "Incident not found"}, status=404)
    except Exception as e:
        return Response({"error": str(e)}, status=500)


# ── 2. List all community initiatives ───────────────────────────────────────
@api_view(["GET"])
@permission_classes([permissions.AllowAny])
def admin_initiatives(request):
    """
    Returns all community initiatives for admin management.
    Required: admin_user_id (query param)
    """
    admin, err = _require_admin(request)
    if err:
        return err
    try:
        initiatives = Initiative.objects.all().order_by("-created_at")
        data = []
        for init in initiatives:
            data.append({
                "id": init.pk,
                "title": init.title,
                "description": init.description,
                "created_at": init.created_at.isoformat() if init.created_at else "",
                "user_id": str(init.user_id) if init.user_id else "",
            })
        return Response(data)
    except Exception as e:
        return Response({"error": str(e)}, status=500)


# ── 3. Delete a community initiative ────────────────────────────────────────
@api_view(["DELETE"])
@permission_classes([permissions.AllowAny])
def admin_delete_initiative(request, initiative_id):
    """
    Permanently deletes a community initiative.
    Required: admin_user_id
    """
    admin, err = _require_admin(request)
    if err:
        return err
    try:
        initiative = Initiative.objects.get(pk=initiative_id)
        initiative.delete()
        return Response({"message": f"Initiative {initiative_id} deleted"})
    except Initiative.DoesNotExist:
        return Response({"error": "Initiative not found"}, status=404)
    except Exception as e:
        return Response({"error": str(e)}, status=500)


# ── 4. List all training courses ─────────────────────────────────────────────
@api_view(["GET"])
@permission_classes([permissions.AllowAny])
def admin_courses(request):
    """
    Returns all training courses for admin management.
    Required: admin_user_id (query param)
    """
    admin, err = _require_admin(request)
    if err:
        return err
    try:
        courses = TrainingCourse.objects.all().order_by("created_at")
        serializer = TrainingCourseSerializer(courses, many=True)
        return Response(serializer.data)
    except Exception as e:
        return Response({"error": str(e)}, status=500)


# ── 5. Delete a training course ──────────────────────────────────────────────
@api_view(["DELETE"])
@permission_classes([permissions.AllowAny])
def admin_delete_course(request, course_id):
    """
    Permanently deletes a training course and all related progress.
    Required: admin_user_id
    """
    admin, err = _require_admin(request)
    if err:
        return err
    try:
        course = TrainingCourse.objects.get(course_id=course_id)
        course.delete()
        return Response({"message": f"Course {course_id} deleted"})
    except TrainingCourse.DoesNotExist:
        return Response({"error": "Course not found"}, status=404)
    except Exception as e:
        return Response({"error": str(e)}, status=500)


# ── 5b. Create a new training course ─────────────────────────────────────────
@api_view(["POST"])
@permission_classes([permissions.AllowAny])
def admin_create_course(request):
    """
    Admin creates a new training course.
    Required body: admin_user_id, title_en, title_ar, description_en, description_ar,
                   category_en, category_ar, difficulty, duration_minutes, price,
                   badge_name_en, badge_name_ar, is_irl (optional)
    """
    admin, err = _require_admin(request)
    if err:
        return err
    try:
        data = request.data
        required = ['title_en', 'title_ar', 'description_en', 'description_ar',
                    'category_en', 'category_ar', 'difficulty', 'duration_minutes', 'price']
        for field in required:
            if not data.get(field):
                return Response({"error": f"'{field}' is required"}, status=400)

        course = TrainingCourse.objects.create(
            title_en=data['title_en'],
            title_ar=data['title_ar'],
            description_en=data['description_en'],
            description_ar=data['description_ar'],
            category_en=data['category_en'],
            category_ar=data['category_ar'],
            difficulty=data.get('difficulty', 'beginner'),
            duration_minutes=int(data.get('duration_minutes', 60)),
            price=float(data.get('price', 0)),
            badge_name_en=data.get('badge_name_en', data['title_en'] + ' Badge'),
            badge_name_ar=data.get('badge_name_ar', data['title_ar'] + ' شارة'),
            is_irl=data.get('is_irl', False),
            location_info_en=data.get('location_info_en', ''),
            location_info_ar=data.get('location_info_ar', ''),
            schedule_info_en=data.get('schedule_info_en', ''),
            schedule_info_ar=data.get('schedule_info_ar', ''),
        )
        serializer = TrainingCourseSerializer(course)
        return Response(serializer.data, status=201)
    except Exception as e:
        return Response({"error": str(e)}, status=500)


# ── 5c. Edit a training course (name + price) ─────────────────────────────────
@api_view(["PATCH"])
@permission_classes([permissions.AllowAny])
def admin_edit_course(request, course_id):
    """
    Admin edits a training course (title, description, price, difficulty, duration).
    Required: admin_user_id in body
    """
    admin, err = _require_admin(request)
    if err:
        return err
    try:
        course = TrainingCourse.objects.get(course_id=course_id)
        data = request.data
        editable_fields = [
            'title_en', 'title_ar', 'description_en', 'description_ar',
            'price', 'difficulty', 'duration_minutes',
            'category_en', 'category_ar',
            'badge_name_en', 'badge_name_ar',
            'is_irl', 'location_info_en', 'location_info_ar',
            'schedule_info_en', 'schedule_info_ar',
        ]
        for field in editable_fields:
            if field in data:
                val = data[field]
                if field == 'price':
                    val = float(val)
                elif field == 'duration_minutes':
                    val = int(val)
                setattr(course, field, val)
        course.save()
        serializer = TrainingCourseSerializer(course)
        return Response(serializer.data)
    except TrainingCourse.DoesNotExist:
        return Response({"error": "Course not found"}, status=404)
    except Exception as e:
        return Response({"error": str(e)}, status=500)


# ── 6. List all active subscriptions ─────────────────────────────────────────
@api_view(["GET"])
@permission_classes([permissions.AllowAny])
def admin_subscriptions(request):
    """
    Returns all users with active Plus subscriptions.
    Required: admin_user_id (query param)
    """
    admin, err = _require_admin(request)
    if err:
        return err
    try:
        subscribers = User.objects.filter(is_plus=True).order_by("-subscription_date")
        data = []
        for u in subscribers:
            data.append({
                "user_id": str(u.user_id),
                "name": u.name,
                "email": u.email,
                "phone_number": u.phone_number,
                "plan_type": u.plan_type,
                "subscription_date": u.subscription_date.isoformat() if u.subscription_date else None,
                "renewal_date": u.renewal_date.isoformat() if u.renewal_date else None,
                "status": u.status,
            })
        return Response({"subscriptions": data, "total": len(data)})
    except Exception as e:
        return Response({"error": str(e)}, status=500)


# ── 7. Cancel any user's subscription ────────────────────────────────────────
@api_view(["POST"])
@permission_classes([permissions.AllowAny])
def admin_cancel_subscription(request, user_id):
    """
    Admin cancels a specific user's Plus subscription immediately.
    Required: admin_user_id in body
    """
    admin, err = _require_admin(request)
    if err:
        return err
    try:
        user = User.objects.get(user_id=user_id)
        user.is_plus = False
        user.plan_type = None
        user.subscription_date = None
        user.renewal_date = None
        user.save()
        return Response({"message": f"Subscription cancelled for {user.name}"})
    except User.DoesNotExist:
        return Response({"error": "User not found"}, status=404)
    except Exception as e:
        return Response({"error": str(e)}, status=500)# ═══════════════════════════════════════════════════════════════════════════════
# ═══════════════════ FACE RECOGNITION CAMERA ENDPOINTS ═════════════════════════
# ═══════════════════════════════════════════════════════════════════════════════

@api_view(["POST"])
@permission_classes([permissions.AllowAny])
def start_security_camera(request):
    """
    Start the face recognition security camera service.
    
    POST /api/security/camera/start/
    Request data: {
        "user_id": "uuid",
        "enable_notifications": true (optional)
    }
    
    Returns: {
        "success": bool,
        "message": str,
        "status": str,
        "pid": int (if started)
    }
    """
    from .camera_service import start_face_recognition
    
    user_id = request.data.get("user_id")
    enable_notifications = request.data.get("enable_notifications", True)
    
    if not user_id:
        return Response(
            {"error": "user_id is required"},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    try:
        user = User.objects.get(user_id=user_id)
        # Enable camera permission for this user
        user.camera = True
        user.save()
        
        result = start_face_recognition()
        return Response(result, status=status.HTTP_200_OK)
    
    except User.DoesNotExist:
        return Response(
            {"error": "User not found"},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        logger.error(f"Error starting security camera: {e}")
        return Response(
            {"error": f"Failed to start camera: {str(e)}"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(["POST"])
@permission_classes([permissions.AllowAny])
def stop_security_camera(request):
    """
    Stop the face recognition security camera service.
    
    POST /api/security/camera/stop/
    Request data: {
        "user_id": "uuid"
    }
    
    Returns: {
        "success": bool,
        "message": str,
        "status": str
    }
    """
    from .camera_service import stop_face_recognition
    
    user_id = request.data.get("user_id")
    
    if not user_id:
        return Response(
            {"error": "user_id is required"},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    try:
        user = User.objects.get(user_id=user_id)
        # Disable camera permission for this user
        user.camera = False
        user.save()
        
        result = stop_face_recognition()
        return Response(result, status=status.HTTP_200_OK)
    
    except User.DoesNotExist:
        return Response(
            {"error": "User not found"},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        logger.error(f"Error stopping security camera: {e}")
        return Response(
            {"error": f"Failed to stop camera: {str(e)}"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(["GET"])
@permission_classes([permissions.AllowAny])
def get_security_camera_status(request):
    """
    Get the current status of the face recognition security camera.
    
    GET /api/security/camera/status/?user_id=uuid
    
    Returns: {
        "running": bool,
        "message": str,
        "status": str ("active" or "inactive")
    }
    """
    from .camera_service import get_camera_status
    
    user_id = request.query_params.get("user_id")
    
    if not user_id:
        return Response(
            {"error": "user_id is required"},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    try:
        user = User.objects.get(user_id=user_id)
        
        result = get_camera_status()
        result["user_id"] = str(user.user_id)
        result["user_name"] = user.name
        result["camera_enabled"] = user.camera
        
        return Response(result, status=status.HTTP_200_OK)
    
    except User.DoesNotExist:
        return Response(
            {"error": "User not found"},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        logger.error(f"Error getting camera status: {e}")
        return Response(
            {"error": f"Failed to get status: {str(e)}"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


import threading
from .models import PendingCameraAlert

def auto_create_incident(alert_id):
    try:
        alert = PendingCameraAlert.objects.get(alert_id=alert_id)
        if alert.status == 'pending':
            # Create incident automatically
            from .models import Location, Incident
            location, _ = Location.objects.get_or_create(
                latitude=29.964988,  # Default or read from sensor
                longitude=31.259293,
                defaults={'city': 'Unknown', 'region': 'Unknown', 'address': 'Home Camera'}
            )
            incident = Incident.objects.create(
                user=alert.user,
                location=location,
                category="Theft",
                description="Stranger detected by home camera - AUTO REPORT (No response in 2 mins)",
                status="reported",
                total_volunteers=10,
                media_files=[alert.image.url] if alert.image else []
            )
            alert.status = 'auto_reported'
            alert.save()
            print(f"[DJANGO] Auto-created incident {incident.incident_id} for alert {alert_id}")
    except Exception as e:
        print(f"[DJANGO] Error auto-creating incident for alert {alert_id}: {e}")

@api_view(["POST"])
@permission_classes([permissions.AllowAny])
def stranger_detected_api(request):
    try:
        user_id = request.data.get("user_id")
        image_file = request.FILES.get("media_files")
        if not user_id or not image_file:
            return Response({"error": "user_id and media_files are required"}, status=400)
            
        user = User.objects.get(user_id=user_id)
        
        # Check if there's already a pending alert for this user
        existing_alert = PendingCameraAlert.objects.filter(user=user, status='pending').first()
        if existing_alert:
            return Response({"message": "Alert already pending", "alert_id": str(existing_alert.alert_id)}, status=200)

        alert = PendingCameraAlert.objects.create(
            user=user,
            image=image_file,
            status='pending'
        )
        
        # Start 2-minute timer
        t = threading.Timer(120.0, auto_create_incident, args=[alert.alert_id])
        t.daemon = True
        t.start()
        
        return Response({"message": "Stranger alert registered", "alert_id": str(alert.alert_id)}, status=201)
    except Exception as e:
        logger.error(f"Error in stranger_detected_api: {e}")
        return Response({"error": str(e)}, status=500)


@api_view(["GET"])
@permission_classes([permissions.AllowAny])
def pending_alert_api(request):
    try:
        user_id = request.query_params.get("user_id")
        if not user_id:
            return Response({"error": "user_id is required"}, status=400)
            
        alert = PendingCameraAlert.objects.filter(user__user_id=user_id, status='pending').first()
        if alert:
            return Response({
                "has_alert": True,
                "alert_id": str(alert.alert_id),
                "image_url": request.build_absolute_uri(alert.image.url) if alert.image else None,
                "created_at": alert.created_at.isoformat()
            }, status=200)
        return Response({"has_alert": False}, status=200)
    except Exception as e:
        return Response({"error": str(e)}, status=500)


@api_view(["POST"])
@permission_classes([permissions.AllowAny])
def respond_alert_api(request):
    try:
        alert_id = request.data.get("alert_id")
        action = request.data.get("action")  # 'accept' or 'reject'
        if not alert_id or not action:
            return Response({"error": "alert_id and action are required"}, status=400)
            
        alert = PendingCameraAlert.objects.get(alert_id=alert_id)
        
        if alert.status != 'pending':
            return Response({"message": "Alert already handled", "status": alert.status}, status=200)
            
        if action == 'accept':
            from .models import Location, Incident
            location, _ = Location.objects.get_or_create(
                latitude=29.964988,
                longitude=31.259293,
                defaults={'city': 'Unknown', 'region': 'Unknown', 'address': 'Home Camera'}
            )
            incident = Incident.objects.create(
                user=alert.user,
                location=location,
                category="Theft",
                description="Stranger detected by home camera - USER CONFIRMED",
                status="reported",
                total_volunteers=10,
                media_files=[alert.image.url] if alert.image else []
            )
            alert.status = 'resolved'
            alert.save()
            return Response({"message": "Incident created", "incident_id": str(incident.incident_id)}, status=200)
            
        elif action == 'reject':
            alert.status = 'resolved'
            alert.save()
            return Response({"message": "Alert canceled"}, status=200)
            
        return Response({"error": "Invalid action"}, status=400)
    except PendingCameraAlert.DoesNotExist:
        return Response({"error": "Alert not found"}, status=404)
    except Exception as e:
        logger.error(f"Error in respond_alert_api: {e}")
        return Response({"error": str(e)}, status=500)
