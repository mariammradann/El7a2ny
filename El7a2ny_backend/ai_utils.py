"""
Emergency Analysis Pipeline — El7a2ny Backend
Architecture:
  Image → YOLO (object detection)
        → BLIP (scene captioning)
        → Risk Extraction Engine
        → Smart Gemini prompt (context-aware)
        → Structured JSON
"""
import os
from django.conf import settings
from .models import Incident
from ultralytics import YOLO
from google import genai

# ── BLIP lazy loader (avoids slow startup if not needed) ─────────────────────
_blip_processor = None
_blip_model = None

def _load_blip():
    global _blip_processor, _blip_model
    if _blip_model is None:
        try:
            from transformers import BlipProcessor, BlipForConditionalGeneration
            import torch
            print("📷 Loading BLIP model...")
            _blip_processor = BlipProcessor.from_pretrained(
                "Salesforce/blip-image-captioning-base"
            )
            _blip_model = BlipForConditionalGeneration.from_pretrained(
                "Salesforce/blip-image-captioning-base"
            )
            print("✅ BLIP loaded")
        except Exception as e:
            print(f"⚠️ BLIP not available: {e}")
    return _blip_processor, _blip_model

# ── Gemini client ────────────────────────────────────────────────────────────
API_KEY = os.environ.get("GEMINI_API_KEY", "AIzaSyDFAHTPmm2i43HmIZ0WWkoVjgDoqHZ6fVw")
_gemini = genai.Client(api_key=API_KEY)
GEMINI_MODELS = ["gemini-2.0-flash", "gemini-2.0-flash-lite", "gemini-1.5-flash"]

# ── YOLOv8 ───────────────────────────────────────────────────────────────────
yolo_model = YOLO('yolov8n.pt')

# ── Taxonomy ─────────────────────────────────────────────────────────────────
# ALL COCO vehicles (not just car)
VEHICLE_CLASSES = {
    'bicycle', 'car', 'motorcycle', 'airplane', 'bus', 'train', 'truck', 'boat'
}

# ALL COCO living beings (not just person)
LIVING_BEING_CLASSES = {
    'person', 'bird', 'cat', 'dog', 'horse', 'sheep', 'cow',
    'elephant', 'bear', 'zebra', 'giraffe'
}

# Arabic labels for all 80 COCO classes
LABEL_AR = {
    'person':'شخص','bicycle':'دراجة','car':'سيارة','motorcycle':'دراجة نارية',
    'airplane':'طائرة','bus':'حافلة','train':'قطار','truck':'شاحنة',
    'boat':'قارب','traffic light':'إشارة مرور','fire hydrant':'صنبور حريق',
    'stop sign':'إشارة توقف','parking meter':'عداد مواقف','bench':'مقعد',
    'bird':'طائر','cat':'قطة','dog':'كلب','horse':'حصان','sheep':'خروف',
    'cow':'بقرة','elephant':'فيل','bear':'دب','zebra':'حمار وحشي','giraffe':'زرافة',
    'backpack':'حقيبة ظهر','umbrella':'مظلة','handbag':'حقيبة يد','tie':'ربطة عنق',
    'suitcase':'حقيبة سفر','frisbee':'فريسبي','skis':'زلاجات','snowboard':'لوح تزلج',
    'sports ball':'كرة','kite':'طائرة ورقية','baseball bat':'مضرب','baseball glove':'قفاز',
    'skateboard':'لوح','surfboard':'لوح مائي','tennis racket':'مضرب تنس','bottle':'زجاجة',
    'wine glass':'كأس','cup':'كوب','fork':'شوكة','knife':'سكين','spoon':'ملعقة',
    'bowl':'وعاء','banana':'موزة','apple':'تفاحة','sandwich':'ساندويتش','orange':'برتقالة',
    'broccoli':'بروكلي','carrot':'جزرة','hot dog':'هوت دوج','pizza':'بيتزا',
    'donut':'دونات','cake':'كيك','chair':'كرسي','couch':'أريكة','potted plant':'نبات',
    'bed':'سرير','dining table':'طاولة','toilet':'مرحاض','tv':'تلفاز',
    'laptop':'حاسوب','mouse':'فأرة','remote':'ريموت','keyboard':'لوحة مفاتيح',
    'cell phone':'هاتف','microwave':'ميكروويف','oven':'فرن','toaster':'محمصة',
    'sink':'حوض','refrigerator':'ثلاجة','book':'كتاب','clock':'ساعة','vase':'مزهرية',
    'scissors':'مقص','teddy bear':'دمية','hair drier':'مجفف شعر','toothbrush':'فرشاة أسنان',
}

# Emergency weights: positive = emergency signal, negative = non-emergency signal
EMERGENCY_WEIGHTS = {
    # Living beings — context-dependent
    'person': 0.25, 'horse': 0.15, 'dog': 0.05, 'bird': 0.0,
    'cat': 0.0, 'cow': 0.10, 'sheep': 0.05, 'elephant': 0.20,
    'bear': 0.30, 'zebra': 0.05, 'giraffe': 0.0,
    # Vehicles — all count as potential emergency context
    'car': 0.20, 'truck': 0.25, 'bus': 0.25, 'motorcycle': 0.20,
    'bicycle': 0.10, 'airplane': 0.20, 'train': 0.20, 'boat': 0.15,
    # Strong emergency indicators
    'knife': 0.85, 'fire hydrant': 0.35,
    # Non-emergency / indoor objects (reduce score)
    'pizza': -0.60, 'donut': -0.60, 'cake': -0.55, 'sandwich': -0.55,
    'banana': -0.50, 'hot dog': -0.50, 'broccoli': -0.45,
    'chair': -0.45, 'couch': -0.55, 'bed': -0.60, 'toilet': -0.60,
    'laptop': -0.45, 'tv': -0.45, 'keyboard': -0.45, 'mouse': -0.40,
    'book': -0.50, 'vase': -0.45, 'teddy bear': -0.55,
}

# Scene patterns: (required_objects_set, incident_type, severity, emergency_boost)
SCENE_PATTERNS = [
    # Vehicles + living beings = accident
    ({'car', 'person'},        'حادث مروري',                      'high',     0.35),
    ({'truck', 'person'},      'حادث شاحنة',                      'high',     0.40),
    ({'bus', 'person'},        'حادث حافلة',                      'high',     0.40),
    ({'motorcycle', 'person'}, 'حادث دراجة نارية',                'high',     0.35),
    ({'bicycle', 'person'},    'حادث دراجة',                      'medium',   0.25),
    ({'airplane', 'person'},   'حادث طيران',                      'critical', 0.60),
    ({'train', 'person'},      'حادث قطار',                       'critical', 0.60),
    ({'boat', 'person'},       'حادث مائي',                       'high',     0.40),
    # Multi-vehicle
    ({'car', 'truck'},         'تصادم سيارة وشاحنة',              'high',     0.40),
    ({'car', 'motorcycle'},    'تصادم مروري',                     'high',     0.35),
    ({'car', 'bus'},           'تصادم حافلة',                     'high',     0.40),
    # Security
    ({'knife', 'person'},      'اعتداء بسلاح أبيض',               'critical', 0.70),
    ({'knife'},                'سلاح مرصود في الموقع',            'high',     0.55),
    # Wild animal
    ({'bear', 'person'},       'هجوم حيوان بري',                  'critical', 0.65),
    ({'elephant', 'person'},   'حادثة مع حيوان ضخم',              'high',     0.50),
    # Traffic alone (no people)
    ({'car', 'truck'},         'حادث مروري',                      'medium',   0.25),
    ({'fire hydrant'},         'خط مياه أو حريق محتمل قريب',      'medium',   0.30),
]

# Objects that are almost always non-emergency
NON_EMERGENCY_ONLY = {
    'pizza', 'donut', 'cake', 'sandwich', 'hot dog', 'banana', 'broccoli',
    'carrot', 'apple', 'orange', 'couch', 'bed', 'toilet', 'laptop',
    'tv', 'book', 'teddy bear', 'toothbrush', 'hair drier', 'keyboard',
}


def _compute_perceptual_hash(image_path):
    """Simple 64-bit perceptual hash using PIL — no extra libraries needed."""
    from PIL import Image
    try:
        img = Image.open(image_path).convert('L').resize((8, 8), Image.LANCZOS)
        pixels = list(img.getdata())
        avg = sum(pixels) / len(pixels)
        bits = ''.join('1' if p > avg else '0' for p in pixels)
        return hex(int(bits, 2))[2:].zfill(16)
    except Exception:
        return None


def _resolve_path(media_path):
    """Resolve stored media URL/path to absolute filesystem path."""
    if '://' in media_path:
        media_path = media_path.split('/media/')[-1]
    elif media_path.startswith('/media/'):
        media_path = media_path[len('/media/'):]
    return os.path.normpath(os.path.join(settings.MEDIA_ROOT, media_path))


def _get_scene_caption(image_path):
    """
    BLIP image captioning → natural language scene description.
    Example: 'a damaged car on a highway with smoke coming from the engine'
    Returns empty string if BLIP unavailable.
    """
    try:
        processor, model = _load_blip()
        if processor is None:
            return ""
        from PIL import Image as PILImage
        import torch
        image = PILImage.open(image_path).convert('RGB')
        inputs = processor(image, return_tensors="pt")
        with torch.no_grad():
            out = model.generate(**inputs, max_new_tokens=60)
        caption = processor.decode(out[0], skip_special_tokens=True)
        print(f"📷 BLIP caption: {caption}")
        return caption
    except Exception as e:
        print(f"⚠️ BLIP caption error: {e}")
        return ""


def _extract_risks(detected_set, caption, confidence_map, category):
    """
    detections + scene caption → specific, contextual risks.
    This is the detections → risks layer before instructions.
    """
    risks = []
    cap = caption.lower()

    # Confidence threshold: skip weak detections for risk assessment
    HIGH_CONF = {l for l, c in confidence_map.items() if c >= 0.50}
    MED_CONF  = {l for l, c in confidence_map.items() if c >= 0.35}

    # Fire / smoke signals (BLIP caption is key here since YOLO has no fire class)
    if any(w in cap for w in ['fire', 'flame', 'burning', 'smoke', 'blaze']):
        risks.append("خطر اندلاع حريق")
        risks.append("خطر استنشاق الدخان")
        if any(w in cap for w in ['truck', 'fuel', 'tanker', 'gas']):
            risks.append("⚠️ خطر انفجار — ناقلة وقود في المشهد")

    # Flood / water signals
    if any(w in cap for w in ['flood', 'water', 'river', 'rain', 'wet road']):
        risks.append("خطر المياه والانزلاق")
        risks.append("خطر الصعق الكهربائي من الكابلات")

    # Vehicle accidents
    vehicles_detected = detected_set & VEHICLE_CLASSES
    if vehicles_detected and detected_set & LIVING_BEING_CLASSES:
        risks.append("إصابات بشرية محتملة")
    if vehicles_detected:
        risks.append("خطر على حركة المرور")
        if any(w in cap for w in ['overturned', 'flipped', 'crashed', 'damaged', 'collision']):
            risks.append("مركبة متضررة — خطر تسرب وقود")

    # Crowd panic
    if any(w in cap for w in ['crowd', 'people', 'panic', 'running']):
        risks.append("خطر حالة هلع جماعي")

    # Security threats
    if 'knife' in HIGH_CONF:
        risks.append("تهديد أمني مباشر — سلاح أبيض")
        risks.append("خطر إصابات جسدية")

    # Wild animals
    dangerous_animals = {'bear', 'elephant'} & HIGH_CONF
    if dangerous_animals:
        risks.append("خطر هجوم حيوان مفترس")

    # Low confidence warning
    emergency_labels = (VEHICLE_CLASSES | LIVING_BEING_CLASSES | {'knife', 'fire hydrant'})
    strong_detections = detected_set & emergency_labels & HIGH_CONF
    if not strong_detections and not any(w in cap for w in ['fire','crash','flood','injur','blood','smoke']):
        risks.append("تحقق يدوي مطلوب — ثقة منخفضة في التحليل")

    return risks


def _build_smart_gemini_prompt(caption, detected_set, confidence_map, risks, incident):
    """
    Builds a context-rich prompt that explicitly forbids generic instructions
    and forces scene-specific, risk-driven responses.
    """
    # Build objects string with confidence
    objects_str = ", ".join(
        [f"{LABEL_AR.get(l, l)} ({c*100:.0f}%)" for l, c in confidence_map.items()]
    ) if confidence_map else "لا شيء واضح"

    risks_str = "\n".join([f"- {r}" for r in risks]) if risks else "- لم تُرصد مخاطر واضحة"

    # Confidence assessment
    high_conf_emergency = any(
        c >= 0.5 for l, c in confidence_map.items()
        if l in (VEHICLE_CLASSES | LIVING_BEING_CLASSES | {'knife'})
    )
    conf_note = (
        "التحليل ذو ثقة عالية." if high_conf_emergency
        else "ملاحظة: بعض العناصر مكتشفة بثقة منخفضة — كن محتاطاً في التقييم."
    )

    prompt = f"""أنت نظام تحليل حوادث طوارئ ذكي.

[بيانات المشهد]
وصف BLIP للمشهد: "{caption or 'غير متاح'}"
العناصر المكتشفة بـ YOLOv8: {objects_str}
المخاطر المستخرجة:
{risks_str}
{conf_note}
نوع البلاغ: {incident.category or 'غير محدد'}
وصف المستخدم: {incident.description or 'لا يوجد'}

[تعليمات صارمة]
- لا تُطلع تعليمات عامة مثل "اتصل بالطوارئ" أو "ابقَ آمناً" بدون سياق.
- التعليمات يجب أن تعتمد على المشهد الفعلي والمخاطر المرصودة فقط.
- إذا لم يكن هناك خطر واضح، قل: "لا يمكن التحقق من الحادث بثقة كافية."
- إذا كانت الصورة عادية (طعام، منزل، لا طوارئ)، اذكر ذلك صراحةً.

[مثال على الصح]
إذا كان هناك دخان قرب مركبة:
→ حذّر من خطر الانفجار، اطلب ابتعاد الجميع 50 متر

إذا كانت المياه تغمر الطريق:
→ حذّر من الصعق الكهربائي، لا تسر في المياه

[الصيغة المطلوبة - عربي فقط]
SUMMARY: [ملخص دقيق للمتطوعين بناءً على المشهد الفعلي]
INSTRUCTIONS: [تعليمات خطوة بخطوة مخصصة للمخاطر المرصودة]"""
    return prompt


def _try_gemini(image_path, caption, detected_set, confidence_map, risks, incident):
    """Call Gemini with smart context-aware prompt. Returns (summary, instructions) or (None,None)."""
    prompt = _build_smart_gemini_prompt(caption, detected_set, confidence_map, risks, incident)
    is_video = image_path.lower().endswith(('.mp4', '.mov', '.avi', '.mkv'))
    from PIL import Image as PILImage
    for model_name in GEMINI_MODELS:
        try:
            if is_video:
                with open(image_path, 'rb') as f:
                    contents = [genai.types.Part.from_bytes(data=f.read(), mime_type='video/mp4'), prompt]
            else:
                contents = [PILImage.open(image_path), prompt]
            resp = _gemini.models.generate_content(model=model_name, contents=contents)
            text = resp.text
            tu = text.upper()
            if "SUMMARY:" in tu and "INSTRUCTIONS:" in tu:
                s, i = tu.find("SUMMARY:"), tu.find("INSTRUCTIONS:")
                if s < i:
                    return text[s+8:i].strip(), text[i+13:].strip()
            return text.strip(), None
        except Exception as eg:
            print(f"ℹ️ Gemini {model_name}: {type(eg).__name__}")
    return None, None


def analyze_incident_media(incident_id):
    """
    Full pipeline:
    1. Perceptual hash → duplicate check
    2. YOLOv8 → detect ALL objects (vehicles, living beings, everything)
    3. Reasoning engine → scene context, validity, false report score
    4. Gemini (optional) → richer Arabic narrative
    5. Save structured JSON to incident.ai_analysis
    """
    try:
        incident = Incident.objects.get(incident_id=incident_id)
        if not incident.media_files:
            print(f"⚠️ No media for {incident_id}")
            return False

        full_path = _resolve_path(incident.media_files[0])
        if not os.path.exists(full_path):
            print(f"❌ File not found: {full_path}")
            return False

        print(f"🔍 Analyzing: {full_path}")

        # ── Step 1: Duplicate detection ──────────────────────────────────────
        img_hash = _compute_perceptual_hash(full_path)
        duplicate_detected = False
        if img_hash:
            existing = Incident.objects.filter(image_hash=img_hash).exclude(
                incident_id=incident_id
            ).exists()
            if existing:
                duplicate_detected = True
                print(f"🔁 Duplicate image detected! hash={img_hash}")

        # ── Step 2: YOLOv8 detection ─────────────────────────────────────────
        raw_detections = []
        try:
            results = yolo_model(full_path, conf=0.25)
            for r in results:
                for box in r.boxes:
                    label = yolo_model.names[int(box.cls[0])]
                    conf = float(box.conf[0])
                    raw_detections.append((label, round(conf, 3)))
            print(f"🎯 YOLO: {raw_detections}")
        except Exception as ey:
            print(f"⚠️ YOLO error: {ey}")

        detected_labels = [d[0] for d in raw_detections]
        detected_set = set(detected_labels)
        confidence_map = {l: c for l, c in raw_detections}  # label → best confidence
        has_vehicle = bool(detected_set & VEHICLE_CLASSES)
        has_living = bool(detected_set & LIVING_BEING_CLASSES)
        has_person = 'person' in detected_set
        is_all_non_emergency = bool(detected_set) and detected_set.issubset(NON_EMERGENCY_ONLY)

        # ── Step 2b: BLIP scene captioning ───────────────────────────────────
        caption = ""
        if not full_path.lower().endswith(('.mp4', '.mov', '.avi', '.mkv')):
            caption = _get_scene_caption(full_path)

        # ── Step 3: Scene pattern matching ───────────────────────────────────
        matched_patterns = []
        pattern_boost = 0.0
        inferred_type = None
        inferred_severity = "low"

        for required, inc_type, severity, boost in SCENE_PATTERNS:
            if required.issubset(detected_set):
                matched_patterns.append(inc_type)
                if boost > pattern_boost:
                    pattern_boost = boost
                    inferred_type = inc_type
                    inferred_severity = severity
                break  # use highest-priority match

        # ── Step 4: Emergency & false-report scoring ─────────────────────────
        base_emergency = 0.0
        for label, conf in raw_detections:
            w = EMERGENCY_WEIGHTS.get(label, 0.0)
            base_emergency += w * conf

        base_emergency = min(base_emergency + pattern_boost, 1.0)
        base_emergency = max(base_emergency, 0.0)

        # False report signals
        false_report_prob = 0.0
        if not raw_detections:
            false_report_prob += 0.55
        elif is_all_non_emergency:
            false_report_prob += 0.70
        elif not has_vehicle and not has_living:
            false_report_prob += 0.40
        if duplicate_detected:
            false_report_prob = 1.0

        # Emergency objects reduce false report probability
        false_report_prob = max(0.0, false_report_prob - base_emergency * 0.5)
        false_report_prob = min(false_report_prob, 1.0)
        false_report_prob = round(false_report_prob, 3)

        # Confidence
        avg_conf = (sum(c for _, c in raw_detections) / len(raw_detections)) if raw_detections else 0.0
        confidence = round(avg_conf * max(base_emergency, 0.1) * (1 - false_report_prob * 0.5), 3)
        confidence = min(confidence, 1.0)

        # Validity classification
        if duplicate_detected:
            validity = "definitely_false"
        elif false_report_prob >= 0.70:
            validity = "definitely_false"
        elif false_report_prob >= 0.45:
            validity = "likely_false"
        elif base_emergency >= 0.40 or matched_patterns:
            validity = "genuine"
        elif base_emergency >= 0.15:
            validity = "uncertain"
        else:
            validity = "likely_false"

        is_emergency = validity in ("genuine", "uncertain")

        # Severity from pattern or fallback
        if not matched_patterns:
            if base_emergency >= 0.70:
                inferred_severity = "critical"
            elif base_emergency >= 0.45:
                inferred_severity = "high"
            elif base_emergency >= 0.20:
                inferred_severity = "medium"
            elif is_emergency:
                inferred_severity = "low"
            else:
                inferred_severity = "none"

        # Incident type fallback
        category = (incident.category or "").lower()
        if not inferred_type:
            if "fire" in category or "حريق" in category:
                inferred_type = "حريق"
            elif "accident" in category or "حادث" in category:
                inferred_type = "حادث مروري"
            elif "medical" in category or "طبي" in category:
                inferred_type = "حالة طبية"
            elif has_vehicle and has_living:
                inferred_type = "حادث محتمل"
            elif has_living and not has_vehicle:
                inferred_type = "حادث يتضمن أشخاصاً أو كائنات حية"
            elif has_vehicle:
                inferred_type = "حادث مركبة"
            else:
                inferred_type = incident.category or "غير محدد"

        # ── Step 3b: Risk extraction (detections + caption → risks) ─────────
        risks = _extract_risks(detected_set, caption, confidence_map, category)
        if not risks and is_emergency:
            risks.append("يتطلب تدخلاً عاجلاً")

        # Recommended actions (driven by risks)
        actions = []
        if duplicate_detected:
            actions = ["⚠️ صورة مكررة — قد يكون البلاغ مزيفاً"]
        else:
            if inferred_severity in ("critical", "high"):
                actions.append("إرسال متطوعين للموقع فوراً")
                actions.append("إبلاغ الجهات الرسمية (إسعاف 123 | شرطة 122)")
            elif inferred_severity == "medium":
                actions.append("إرسال أقرب متطوع")
                actions.append("مراقبة الوضع")
            if has_vehicle:
                actions.append("تأمين منطقة الحادث وتحويل المرور")
            if 'knife' in detected_set:
                actions.insert(0, "⚠️ لا تقترب وحدك — اتصل بالشرطة أولاً")
            for r in risks:
                if 'انفجار' in r:
                    actions.insert(0, "إبعاد الجميع 50 متر على الأقل")
                    break
            for r in risks:
                if 'كهربائي' in r:
                    actions.append("لا تسر في المياه — خطر صعق كهربائي")
                    break

        # Build instructions string (rule-based fallback)
        instructions = _build_instructions(inferred_type, detected_set, category)

        # ── Step 5: Summary (YOLO-based) ──────────────────────────────────────
        ar_detections = [LABEL_AR.get(l, l) for l in detected_labels]
        if raw_detections:
            summary_ar = (
                f"رصد النظام: {', '.join(ar_detections)}. "
                f"التقييم: {inferred_type}. "
                f"{'المستخدم أفاد: ' + incident.description + '. ' if incident.description else ''}"
                f"مستوى الخطورة: {inferred_severity}."
            )
        else:
            summary_ar = f"تم استلام البلاغ. لم يُرصد عناصر واضحة في الصورة. التحقق يدوي مطلوب."

        analysis_source = "yolov8+blip+reasoning"

        # ── Step 6: Optional Gemini enhancement (smart context-aware prompt) ─
        g_summary, g_instructions = _try_gemini(
            full_path, caption, detected_set, confidence_map, risks, incident
        )
        if g_summary:
            summary_ar = g_summary
            if g_instructions:
                instructions = g_instructions
            analysis_source = "yolov8+blip+gemini"

        # Inject caption into summary if BLIP produced something useful
        if caption and 'رصد النظام' in summary_ar:
            summary_ar = f"وصف المشهد: {caption}.\n" + summary_ar

        # ── Step 7: Build final JSON ──────────────────────────────────────────
        detected_objects_json = [
            {
                "label": label,
                "label_ar": LABEL_AR.get(label, label),
                "confidence": conf,
                "category": (
                    "vehicle" if label in VEHICLE_CLASSES else
                    "living_being" if label in LIVING_BEING_CLASSES else
                    "object"
                ),
                "emergency_weight": EMERGENCY_WEIGHTS.get(label, 0.0)
            }
            for label, conf in raw_detections
        ]

        analysis = {
            "is_emergency": is_emergency,
            "incident_validity": validity,
            "false_report_probability": false_report_prob,
            "incident_type": inferred_type,
            "severity": inferred_severity,
            "confidence": confidence,
            "detected_objects": detected_objects_json,
            "scene_patterns_matched": matched_patterns,
            "scene_caption": caption,
            "summary": summary_ar,
            "risks": risks,
            "recommended_actions": actions,
            "user_instructions": instructions,
            "duplicate_detected": duplicate_detected,
            "image_hash": img_hash,
            "analysis_source": analysis_source,
        }

        # ── Step 8: Save ──────────────────────────────────────────────────────
        incident.ai_summary = summary_ar
        incident.ai_instructions = instructions
        incident.ai_analysis = analysis
        if img_hash:
            incident.image_hash = img_hash
        incident.save()

        print(f"✅ Analysis done: {validity}, severity={inferred_severity}, "
              f"emergency={is_emergency}, false_prob={false_report_prob}")
        return True

    except Exception as e:
        import traceback
        msg = traceback.format_exc()
        print(f"🚨 Pipeline Error:\n{msg}")
        try:
            with open(os.path.join(settings.BASE_DIR, "ai_debug.log"), "a", encoding="utf-8") as f:
                f.write(f"\n--- {incident_id} ---\n{msg}\n")
        except Exception:
            pass
        try:
            inc = Incident.objects.get(incident_id=incident_id)
            inc.ai_instructions = _build_instructions((inc.category or ""), set(), (inc.category or "").lower())
            inc.ai_summary = "تم استلام البلاغ. جاري التحقق يدوياً."
            inc.save()
        except Exception:
            pass
        return False


def _build_instructions(incident_type, detected_set, category):
    """Contextual Arabic instructions based on detected scene."""
    if 'knife' in detected_set:
        return ("1. ابتعد عن الموقع فوراً.\n"
                "2. لا تواجه المعتدي — سلامتك أولاً.\n"
                "3. اختبئ في مكان آمن.\n"
                "4. اتصل بالشرطة 122 الآن.")
    if 'bear' in detected_set or 'elephant' in detected_set:
        return ("1. لا تتحرك فجأة — ابقَ هادئاً تماماً.\n"
                "2. ابتعد ببطء دون أن تدير ظهرك للحيوان.\n"
                "3. اصعد لمكان مرتفع إن أمكن.\n"
                "4. اتصل بالدفاع المدني 123.")
    if bool(detected_set & VEHICLE_CLASSES) and bool(detected_set & LIVING_BEING_CLASSES):
        return ("1. لا تتحرك إلا إذا كنت في خطر مباشر.\n"
                "2. تنفس بعمق وابقَ هادئاً.\n"
                "3. لا تنزع حزام الأمان حتى يصل المسعفون.\n"
                "4. أوقف المحرك وفعّل أضواء الطوارئ إن استطعت.\n"
                "5. اتصل بالإسعاف 123 فوراً.")
    if bool(detected_set & VEHICLE_CLASSES):
        return ("1. ابتعد عن المركبة فوراً.\n"
                "2. أوقف المحرك وفعّل أضواء الطوارئ.\n"
                "3. احذر من تسرب الوقود.\n"
                "4. اتصل بالإسعاف 123.")
    if "fire" in category or "حريق" in category:
        return ("1. غادر المبنى فوراً — لا تستخدم المصاعد.\n"
                "2. ابقَ منخفضاً تحت الدخان.\n"
                "3. أغلق الأبواب خلفك لتباطؤ انتشار النيران.\n"
                "4. اتصل بالإطفاء 180.")
    if "medical" in category or "طبي" in category:
        return ("1. ابقَ هادئاً وتنفس ببطء.\n"
                "2. لا تتحرك إلا للضرورة.\n"
                "3. إذا كان هناك نزيف: اضغط بقوة بقماش نظيف.\n"
                "4. اتصل بالإسعاف 123.")
    return ("1. ابقَ في مكانك إذا كان آمناً.\n"
            "2. أبعد الآخرين عن مصدر الخطر.\n"
            "3. اتصل بالطوارئ: إسعاف 123 | شرطة 122 | إطفاء 180.\n"
            "4. المتطوعون في الطريق إليك.")


def get_chatbot_response_with_media(message, media_file_path=None):
    """Chatbot handler — tries all Gemini models."""
    prompt = (
        "أنت مساعد طوارئ ذكي. المستخدم يقول: '{msg}'. "
        "قدّم نصيحة إسعافات أولية فورية وتعليمات سلامة بالعربية."
    ).format(msg=message)
    contents = [prompt]
    if media_file_path and os.path.exists(media_file_path):
        if media_file_path.lower().endswith(('.mp4', '.mov', '.avi', '.mkv')):
            with open(media_file_path, 'rb') as f:
                contents.append(genai.types.Part.from_bytes(data=f.read(), mime_type='video/mp4'))
        else:
            from PIL import Image
            contents.append(Image.open(media_file_path))
    for model_name in GEMINI_MODELS:
        try:
            resp = _gemini.models.generate_content(model=model_name, contents=contents)
            return resp.text
        except Exception:
            pass
    return "عذراً، الخدمة غير متاحة حالياً. اتصل بالطوارئ: 123."
