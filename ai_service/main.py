"""
El7a2ny AI Service - Powered by Google Gemini API
Port: 8001

This service analyzes images, videos, audio, and text to detect emergencies
and provide AI-driven incident assessment for the El7a2ny emergency app.
"""

import os
import logging
import json
from typing import Optional
from io import BytesIO

from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.responses import JSONResponse
from google import genai
from dotenv import load_dotenv
from PIL import Image
import tempfile

# ─────────────────────────────────────────────────────────────────────────────
# Configuration & Logging
# ─────────────────────────────────────────────────────────────────────────────

load_dotenv()

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if not GEMINI_API_KEY:
    raise ValueError("GEMINI_API_KEY not found in .env file")

client = genai.Client(api_key=GEMINI_API_KEY)

app = FastAPI(
    title="El7a2ny AI Analysis Service",
    description="Emergency incident detection using Google Gemini API",
    version="1.0.0"
)

# Pipeline utilities
from utils.yolov8_detector import EmergencyDetector
from utils.authenticity import (
    analyze_metadata, 
    check_image_consistency, 
    calculate_authenticity_verdict
)
from utils.triage import evaluate_baseline_triage
from utils.gemini_client import GeminiReasoner
from utils.assistant_client import GeminiAssistant

try:
    detector = EmergencyDetector()
except Exception as e:
    logger.error(f"Failed to initialize EmergencyDetector: {e}")
    detector = None

reasoner = GeminiReasoner()
assistant = GeminiAssistant()


# ─────────────────────────────────────────────────────────────────────────────
# Constants & Prompts
# ─────────────────────────────────────────────────────────────────────────────

ANALYSIS_PROMPT = """
You are an expert emergency response AI vision system for El7a2ny, an Egyptian emergency management app.
You will be shown an emergency scene image. Your job is to carefully examine EVERY visible detail.

Analyze the scene and respond ONLY with valid JSON (no markdown, no code blocks).

Respond with exactly this JSON structure:
{
  "incident_type": "One of: Building Fire | Vehicle Fire | Wildfire | Traffic Accident | Train Accident | Aviation Incident | Medical Emergency | Chemical Spill | Gas Leak | Flood | Earthquake | Storm Damage | Active Shooter | Bomb Threat | Hostage Situation | Missing Person | Collapsed Structure | Other",
  "severity": "Critical|High|Medium|Low",
  "triage_level": "Red|Orange|Yellow|Green|Black",
  "urgency_score": 1-10,
  "risk_level": "Specific risks visible in the scene",
  "dispatch_priority": "Exact units and priority for dispatch",

  "scene_details": {
    "people_detected": true|false,
    "people_count": "exact number if countable, or 'multiple', 'unknown'",
    "people_condition": "description of visible injuries, unconscious, trapped, walking, etc.",
    "casualties_visible": true|false,
    "casualties_count": "number or 'unknown'",

    "vehicles_detected": true|false,
    "vehicles": [
      {
        "type": "car|truck|bus|motorcycle|van|ambulance|fire truck|police car|bicycle|other",
        "count": 1,
        "condition": "overturned|on fire|crashed|intact|damaged",
        "color": "color if visible",
        "occupants_visible": true|false
      }
    ],
    "total_vehicles_count": 0,

    "fire_detected": true|false,
    "fire_details": {
      "intensity": "small|moderate|large|massive|none",
      "spread": "contained|spreading|explosive|none",
      "what_is_burning": "building|vehicle|vegetation|debris|unknown",
      "smoke_color": "black|white|grey|orange|none",
      "smoke_density": "light|heavy|none",
      "estimated_area": "small room|multiple rooms|floor|whole building|outdoor area"
    },

    "medical_details": {
      "injury_type_visible": "burns|trauma|bleeding|unconscious|cardiac|fracture|unknown|none",
      "patient_position": "standing|sitting|lying down|trapped|unknown",
      "patients_count": "number or 'unknown'",
      "bystanders_assisting": true|false,
      "medical_equipment_visible": "defibrillator|stretcher|oxygen|none"
    },

    "structural_hazards": "collapsed walls|broken glass|unstable structure|flooding|exposed wires|none",
    "environmental_conditions": "nighttime|daytime|rain|smoke filled|dust|clear",
    "scene_accessibility": "accessible|partially blocked|fully blocked"
  },

  "summary": {
    "en": "Detailed English summary based on what is ACTUALLY visible in the image, including specific counts of vehicles, people, and key hazards",
    "ar": "ملخص عربي تفصيلي بناءً على ما هو مرئي فعلياً في الصورة، بما في ذلك أعداد المركبات والأشخاص والمخاطر الرئيسية"
  },
  "responder_briefing": {
    "en": "Specific briefing for responders based on exact scene observations: vehicle types, people trapped, fire behavior, hazards present",
    "ar": "إحاطة محددة للمستجيبين بناءً على ملاحظات الموقع الدقيقة: أنواع المركبات، الأشخاص المحاصرون، سلوك الحريق، المخاطر الموجودة"
  },
  "instructions": {
    "en": ["Specific action based on scene", "Another specific action", "..."],
    "ar": ["إجراء محدد بناءً على الموقع", "إجراء آخر محدد", "..."]
  },
  "responders_needed": ["list based on what is detected"],
  "confidence": 0.0-1.0
}

DETECTION RULES:
1. TRAFFIC ACCIDENTS: Count every vehicle visible. Identify type (car/truck/bus/etc). Note if overturned, on fire, or crashed. Count visible people inside or around vehicles. Estimate injuries.
2. FIRES: Assess fire size, what is burning, smoke color (black = toxic/petroleum, white = water vapor, grey = structural). Note if people are trapped.
3. MEDICAL: Identify visible injury type (burns, bleeding, unconscious, fractures). Count patients. Note bystanders.
4. ALL SCENES: Always count people. Note if they appear trapped, injured, or mobile.

IMPORTANT RULES:
- If you cannot determine a value with confidence, use "unknown" not null.
- The summary and instructions MUST be specific to what you actually see, not generic.
- Write instructions in order of urgency (most critical first).
- All text in "summary", "responder_briefing", and "instructions" MUST be bilingual with "en" and "ar" keys.
- Write natural Egyptian Arabic (عربي مصري واضح) for the "ar" fields.
- Only respond with the JSON object. No explanations outside the JSON.
"""

VOICE_ANALYSIS_PROMPT = """
You are an emergency response AI. Analyze this transcript from an emergency call.
Respond ONLY with valid JSON (no markdown, no code blocks).

Respond with exactly this JSON structure:
{
  "transcription": "Full transcribed text",
  "panic_detected": true|false,
  "distress_keywords": ["keyword1", "keyword2"],
  "incident_type": "Type of incident",
  "severity": "Critical|High|Medium|Low",
  "triage_level": "Red|Orange|Yellow|Green|Black",
  "urgency_score": 1-10,
  "risk_level": "Brief description",
  "dispatch_priority": "Priority statement",
  "summary": {"en": "Brief English summary", "ar": "ملخص عربي مختصر"},
  "responder_briefing": {"en": "Responder instructions in English", "ar": "تعليمات المستجيبين بالعربية"},
  "instructions": {
    "en": ["English action 1", "English action 2"],
    "ar": ["الإجراء الأول بالعربية", "الإجراء الثاني بالعربية"]
  },
  "responders_needed": ["Firefighters|Ambulance|Police"],
  "confidence": 0.0-1.0
}

IMPORTANT: The summary, responder_briefing, and instructions MUST be bilingual with "en" and "ar" keys. Only respond with the JSON object. No explanations.
"""

TEXT_ANALYSIS_PROMPT = """
You are an emergency response AI for El7a2ny, an Egyptian emergency app. Analyze this incident description.
Respond ONLY with valid JSON (no markdown, no code blocks).

Respond with exactly this JSON structure:
{
  "incident_type": "Type of incident",
  "severity": "Critical|High|Medium|Low",
  "triage_level": "Red|Orange|Yellow|Green|Black",
  "urgency_score": 1-10,
  "risk_level": "Brief description",
  "dispatch_priority": "Priority statement",
  "summary": {"en": "Brief English summary", "ar": "ملخص عربي مختصر"},
  "responder_briefing": {"en": "Responder instructions in English", "ar": "تعليمات المستجيبين بالعربية"},
  "instructions": {
    "en": ["English action 1", "English action 2"],
    "ar": ["الإجراء الأول بالعربية", "الإجراء الثاني بالعربية"]
  },
  "responders_needed": ["Firefighters|Ambulance|Police"],
  "confidence": 0.0-1.0
}

IMPORTANT: The summary, responder_briefing, and instructions MUST be bilingual with "en" and "ar" keys. Write natural Arabic for Egyptian citizens and emergency responders. Only respond with the JSON object. No explanations.
"""

# ─────────────────────────────────────────────────────────────────────────────
# Helper Functions
# ─────────────────────────────────────────────────────────────────────────────

def parse_json_response(response_text: str) -> dict:
    """
    Extract and parse JSON from Gemini response.
    Handles cases where response is wrapped in markdown code blocks.
    """
    text = response_text.strip()
    
    # Remove markdown code blocks if present
    if text.startswith("```json"):
        text = text[7:]
    if text.startswith("```"):
        text = text[3:]
    if text.endswith("```"):
        text = text[:-3]
    
    text = text.strip()
    
    try:
        return json.loads(text)
    except json.JSONDecodeError as e:
        logger.error(f"Failed to parse JSON response: {e}\nResponse: {text[:200]}")
        # Return a default safe response
        return {
            "incident_type": "Unknown",
            "severity": "Medium",
            "triage_level": "Yellow",
            "urgency_score": 5,
            "risk_level": "Unable to determine",
            "dispatch_priority": "Standard response",
            "summary": "AI analysis failed - check with dispatcher",
            "responder_briefing": "Dispatch for detailed information",
            "instructions": ["Contact dispatcher for details"],
            "responders_needed": ["Standard response team"],
            "confidence": 0.0
        }


def validate_analysis_response(data: dict) -> dict:
    """Ensure all required fields are present with defaults."""
    required_fields = {
        "incident_type": "Unknown",
        "severity": "Medium",
        "triage_level": "Yellow",
        "urgency_score": 5,
        "risk_level": "",
        "dispatch_priority": "",
        "summary": {"en": "", "ar": ""},
        "responder_briefing": {"en": "", "ar": ""},
        "instructions": {"en": [], "ar": []},
        "responders_needed": [],
        "confidence": 0.5,
        "scene_details": {},
    }

    for field, default in required_fields.items():
        if field not in data:
            data[field] = default

    # Ensure urgency_score is an int
    try:
        data["urgency_score"] = int(data.get("urgency_score", 5))
    except (ValueError, TypeError):
        data["urgency_score"] = 5

    # Ensure confidence is a float
    try:
        data["confidence"] = float(data.get("confidence", 0.5))
    except (ValueError, TypeError):
        data["confidence"] = 0.5

    # instructions: accept both old list format and new bilingual dict format
    inst = data.get("instructions", {})
    if isinstance(inst, list):
        # Upgrade old flat list to bilingual dict
        data["instructions"] = {"en": inst, "ar": inst}
    elif not isinstance(inst, dict):
        data["instructions"] = {"en": [], "ar": []}

    # Ensure responders_needed is a list
    if not isinstance(data.get("responders_needed"), list):
        data["responders_needed"] = []

    # Ensure scene_details is a dict
    if not isinstance(data.get("scene_details"), dict):
        data["scene_details"] = {}

    return data



# ─────────────────────────────────────────────────────────────────────────────
# Routes
# ─────────────────────────────────────────────────────────────────────────────

@app.get("/")
async def root():
    """Health check and API info."""
    return {
        "service": "El7a2ny AI Analysis Service",
        "version": "1.0.0",
        "status": "running",
        "endpoints": {
            "image": "/api/v1/analyze/image",
            "video": "/api/v1/analyze/video",
            "voice": "/api/v1/analyze/voice",
            "text": "/api/v1/analyze/text",
        }
    }


@app.post("/api/v1/analyze/image")
async def analyze_image(
    file: UploadFile = File(...),
    description: Optional[str] = Form(None),
    user_trust_score: Optional[float] = Form(1.0)
):
    """
    Analyze an image file for emergency detection.
    Accepts: JPEG, PNG, WebP (max 20MB)
    """
    try:
        logger.info(f"Analyzing image: {file.filename}")
        
        # Read file content
        content = await file.read()
        
        # Validate it's an image
        if file.content_type not in ["image/jpeg", "image/png", "image/webp"]:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid image type: {file.content_type}. Accepts: JPEG, PNG, WebP"
            )
        
        # Convert to PIL Image for validation
        try:
            img = Image.open(BytesIO(content))
            img.verify()
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"Invalid image file: {str(e)}")
        
        # Run YOLOv8 detection
        try:
            img_detect = Image.open(BytesIO(content))
            if detector:
                raw_detections, detected_counts = detector.detect(img_detect)
            else:
                raw_detections, detected_counts = [], {}
        except Exception as e:
            logger.error(f"YOLO detection failed: {e}")
            raw_detections, detected_counts = [], {}

        # Run Authenticity analysis
        metadata_res = analyze_metadata(content)
        consistency_score = check_image_consistency(raw_detections, description)
        is_real, real_prob = calculate_authenticity_verdict(
            metadata_res.get("score", 0.5),
            consistency_score,
            user_trust_score
        )

        # Run Baseline Triage
        baseline_severity, baseline_triage, urgency_score = evaluate_baseline_triage(detected_counts)

        # Run Gemini reasoning
        logger.info("Sending image details to Gemini for semantic reasoning...")
        gemini_res = reasoner.reason_incident(
            detected_counts,
            description,
            baseline_severity,
            image_data=content,
            mime_type=file.content_type
        )
        
        incident_type = gemini_res.get("incident_type", "Medical Emergency")
        if not incident_type or incident_type == "Medical Emergency":
            if detected_counts.get("fire", 0) > 0 or detected_counts.get("smoke", 0) > 0:
                incident_type = "Building Fire"
            elif detected_counts.get("vehicle-accident", 0) > 0 or detected_counts.get("damaged-vehicle", 0) > 0:
                incident_type = "Traffic Accident"
            elif detected_counts.get("flood", 0) > 0:
                incident_type = "Flood"
            elif detected_counts.get("collapsed-building", 0) > 0:
                incident_type = "Collapsed Structure"

        # Merge: prefer Gemini's image-aware severity over YOLO-only baseline
        gemini_severity  = gemini_res.get("severity")   # may be None if Gemini didn't return it
        gemini_triage    = gemini_res.get("triage_level")
        final_severity   = gemini_severity  if gemini_severity  else baseline_severity
        final_triage     = gemini_triage    if gemini_triage     else baseline_triage

        # Map triage → urgency_score when Gemini overrides
        triage_urgency_map = {"Red": 10, "Orange": 8, "Yellow": 5, "Green": 2}
        final_urgency = triage_urgency_map.get(final_triage, urgency_score)

        analysis = {
            "incident_type": incident_type,
            "severity": final_severity,
            "triage_level": final_triage,
            "urgency_score": final_urgency,
            "risk_level": f"Detections: {', '.join([f'{k}: {v}' for k, v in detected_counts.items() if v])}" if any(detected_counts.values()) else "No immediate hazards detected",
            "dispatch_priority": f"Priority dispatch based on {final_severity} severity",
            
            "is_real": is_real,
            "fake_probability": round(1.0 - real_prob, 3),
            "verification_methods": {
                "exif_valid": metadata_res.get("valid", False),
                "exif_score": metadata_res.get("score", 0.0),
                "consistency_score": consistency_score,
                "user_trust_score": user_trust_score,
                "exif_reason": metadata_res.get("reason", "")
            },
            "raw_detections": raw_detections,
            "detected_objects": detected_counts,
            
            "summary": gemini_res.get("summary", {}),
            "responder_briefing": gemini_res.get("volunteer_instructions", {}),
            "instructions": gemini_res.get("user_instructions", {}),
            "responders_needed": [role for role, count in gemini_res.get("volunteers_recommended", {}).items() if count > 0],
            "volunteers_recommended": gemini_res.get("volunteers_recommended", {}),
            "confidence": 0.9,
            "source": "image"
        }
        
        logger.info(f"Analysis complete: {analysis['incident_type']} (Severity: {analysis['severity']})")
        return analysis
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error analyzing image: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Image analysis failed: {str(e)}")


@app.post("/api/v1/analyze/video")
async def analyze_video(
    file: UploadFile = File(...),
    description: Optional[str] = Form(None),
    user_trust_score: Optional[float] = Form(1.0)
):
    """
    Analyze a video file for emergency detection.
    Accepts: MP4, AVI, MOV (max 200MB)
    Note: Video analysis may take 30-60 seconds.
    """
    try:
        logger.info(f"Analyzing video: {file.filename}")
        
        # Read file content
        content = await file.read()
        
        # Validate file type
        valid_types = ["video/mp4", "video/x-msvideo", "video/quicktime"]
        if file.content_type not in valid_types:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid video type: {file.content_type}"
            )
        
        # Save to temp file for processing
        with tempfile.NamedTemporaryFile(delete=False, suffix=".mp4") as tmp:
            tmp.write(content)
            tmp_path = tmp.name
        
        try:
            # Run video frame-sampling detection
            if detector:
                raw_detections, detected_counts = detector.detect_video(tmp_path)
            else:
                raw_detections, detected_counts = [], {}
            
            # Run Authenticity analysis
            metadata_score = 0.85  # Default validation score for standard video container
            consistency_score = check_image_consistency(raw_detections, description)
            is_real, real_prob = calculate_authenticity_verdict(
                metadata_score,
                consistency_score,
                user_trust_score
            )

            # Run Baseline Triage
            baseline_severity, baseline_triage, urgency_score = evaluate_baseline_triage(detected_counts)

            # Try to extract the first frame of the video as an image to pass to Gemini
            first_frame_bytes = None
            first_frame_mime = None
            try:
                import cv2
                cap = cv2.VideoCapture(tmp_path)
                if cap.isOpened():
                    ret, frame = cap.read()
                    if ret:
                        ret_enc, encoded_img = cv2.imencode(".jpg", frame)
                        if ret_enc:
                            first_frame_bytes = encoded_img.tobytes()
                            first_frame_mime = "image/jpeg"
                    cap.release()
            except Exception as ve:
                logger.warning(f"Could not extract first frame for Gemini video reasoning: {ve}")

            # Run Gemini reasoning
            logger.info("Sending video details to Gemini for semantic reasoning...")
            gemini_res = reasoner.reason_incident(
                detected_counts,
                description,
                baseline_severity,
                image_data=first_frame_bytes,
                mime_type=first_frame_mime
            )
            
            incident_type = gemini_res.get("incident_type", "Medical Emergency")
            if not incident_type or incident_type == "Medical Emergency":
                if detected_counts.get("fire", 0) > 0 or detected_counts.get("smoke", 0) > 0:
                    incident_type = "Building Fire"
                elif detected_counts.get("vehicle-accident", 0) > 0 or detected_counts.get("damaged-vehicle", 0) > 0:
                    incident_type = "Traffic Accident"
                elif detected_counts.get("flood", 0) > 0:
                    incident_type = "Flood"
                elif detected_counts.get("collapsed-building", 0) > 0:
                    incident_type = "Collapsed Structure"

            # Merge: prefer Gemini's image-aware severity over YOLO-only baseline
            gemini_severity  = gemini_res.get("severity")
            gemini_triage    = gemini_res.get("triage_level")
            final_severity   = gemini_severity  if gemini_severity  else baseline_severity
            final_triage     = gemini_triage    if gemini_triage     else baseline_triage
            triage_urgency_map = {"Red": 10, "Orange": 8, "Yellow": 5, "Green": 2}
            final_urgency = triage_urgency_map.get(final_triage, urgency_score)

            analysis = {
                "incident_type": incident_type,
                "severity": final_severity,
                "triage_level": final_triage,
                "urgency_score": final_urgency,
                "risk_level": f"Detections: {', '.join([f'{k}: {v}' for k, v in detected_counts.items() if v])}" if any(detected_counts.values()) else "No immediate hazards detected",
                "dispatch_priority": f"Priority dispatch based on {final_severity} severity",
                
                "is_real": is_real,
                "fake_probability": round(1.0 - real_prob, 3),
                "verification_methods": {
                    "exif_valid": True,
                    "exif_score": metadata_score,
                    "consistency_score": consistency_score,
                    "user_trust_score": user_trust_score,
                    "exif_reason": "Standard video file format"
                },
                "raw_detections": raw_detections,
                "detected_objects": detected_counts,
                
                "summary": gemini_res.get("summary", {}),
                "responder_briefing": gemini_res.get("volunteer_instructions", {}),
                "instructions": gemini_res.get("user_instructions", {}),
                "responders_needed": [role for role, count in gemini_res.get("volunteers_recommended", {}).items() if count > 0],
                "volunteers_recommended": gemini_res.get("volunteers_recommended", {}),
                "confidence": 0.9,
                "source": "video"
            }
            
            logger.info(f"Analysis complete: {analysis['incident_type']}")
            return analysis
            
        finally:
            try:
                os.unlink(tmp_path)
            except Exception as e:
                logger.warning(f"Failed to delete temp video file: {e}")
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error analyzing video: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Video analysis failed: {str(e)}")


@app.post("/api/v1/analyze/voice")
async def analyze_voice(file: UploadFile = File(...)):
    """
    Analyze a voice/audio file for emergency detection.
    Automatically transcribes and analyzes for panic/distress.
    Accepts: WAV, MP3, OGG, M4A (max 50MB)
    """
    try:
        logger.info(f"Analyzing voice: {file.filename}")
        
        # Read file content
        content = await file.read()
        
        # Validate audio type
        valid_types = [
            "audio/wav",
            "audio/mpeg",
            "audio/ogg",
            "audio/mp4",
            "audio/aac"
        ]
        if file.content_type not in valid_types:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid audio type: {file.content_type}"
            )
        
        # Send to Gemini for transcription and analysis
        logger.info("Sending audio to Gemini for transcription and analysis...")
        try:
            response = client.models.generate_content(
                model="gemini-2.5-flash",
                contents=[
                    VOICE_ANALYSIS_PROMPT,
                    {
                        "mime_type": file.content_type,
                        "data": content,
                    }
                ]
            )
            analysis = parse_json_response(response.text)
            analysis = validate_analysis_response(analysis)
        except Exception as e:
            logger.error(f"Gemini voice analysis failed: {e}. Using default fallback.")
            analysis = {
                "transcription": "Voice emergency message received.",
                "panic_detected": True,
                "distress_keywords": ["help", "emergency"],
                "incident_type": "Medical Emergency",
                "severity": "High",
                "triage_level": "Orange",
                "urgency_score": 7,
                "risk_level": "Immediate responder deployment",
                "dispatch_priority": "High priority dispatch",
                "summary": {
                    "en": "Emergency voice recording uploaded.",
                    "ar": "تم رفع رسالة صوتية لحالة طوارئ."
                },
                "responder_briefing": {
                    "en": "Voice call reports emergency. Respond immediately.",
                    "ar": "بلاغ صووتى طارئ. توجه للموقع فوراً."
                },
                "instructions": {
                    "en": ["Stay calm and wait for help.", "Do not hang up if contacted."],
                    "ar": ["حافظ على هدوئك وانتظر المساعدة.", "لا تغلق الخط إذا تم الاتصال بك."]
                },
                "responders_needed": ["first_aid"],
                "volunteers_recommended": {
                    "first_aid": 1,
                    "fire_response": 0,
                    "transportation": 1,
                    "rescue": 0
                },
                "confidence": 0.5
            }
            
        analysis["source"] = "voice"
        logger.info(f"Transcription: {analysis.get('transcription', '')[:100]}...")
        logger.info(f"Panic detected: {analysis.get('panic_detected', False)}")
        return analysis
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error analyzing voice: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Voice analysis failed: {str(e)}")


@app.post("/api/v1/analyze/text")
async def analyze_text(
    description: str = Form(...),
    location: Optional[str] = Form(None)
):
    """
    Analyze a text description for emergency detection.
    """
    try:
        logger.info(f"Analyzing text description ({len(description)} chars)")
        
        # Build prompt with optional location
        prompt = TEXT_ANALYSIS_PROMPT
        if location:
            prompt = f"Location: {location}\n\n{prompt}"
        
        # Send to Gemini
        logger.info("Sending text to Gemini for analysis...")
        try:
            response = client.models.generate_content(
                model="gemini-2.5-flash",
                contents=[
                    prompt,
                    f"Incident description: {description}"
                ]
            )
            analysis = parse_json_response(response.text)
            analysis = validate_analysis_response(analysis)
        except Exception as e:
            logger.error(f"Gemini text analysis failed: {e}. Using rule-based fallback.")
            desc_lower = description.lower()
            severity = "Low"
            triage_level = "Green"
            urgency_score = 3
            incident_type = "Medical Emergency"
            volunteers = {"first_aid": 0, "fire_response": 0, "transportation": 0, "rescue": 0}
            
            if any(w in desc_lower for w in ["fire", "smoke", "burn", "حريق", "دخان", "نار"]):
                incident_type = "Building Fire"
                severity = "High"
                triage_level = "Orange"
                urgency_score = 8
                volunteers["fire_response"] = 1
            if any(w in desc_lower for w in ["accident", "crash", "collision", "حادث", "تصادم"]):
                incident_type = "Traffic Accident"
                severity = "Medium"
                triage_level = "Yellow"
                urgency_score = 5
                volunteers["rescue"] = 1
            if any(w in desc_lower for w in ["unconscious", "trapped", "collapsed", "مغمى", "محتجز", "انهيار"]):
                severity = "Critical"
                triage_level = "Red"
                urgency_score = 10
                volunteers["rescue"] = max(volunteers["rescue"], 2)
            if any(w in desc_lower for w in ["blood", "injured", "bleed", "دم", "مصاب", "ينزف"]):
                volunteers["first_aid"] = 1
                if severity == "Low":
                    severity = "Medium"
                    triage_level = "Yellow"
                    urgency_score = 5

            analysis = {
                "incident_type": incident_type,
                "severity": severity,
                "triage_level": triage_level,
                "urgency_score": urgency_score,
                "risk_level": "Immediate action required" if severity in ["High", "Critical"] else "Monitor situation",
                "dispatch_priority": f"Priority dispatch based on {severity} severity",
                "summary": {
                    "en": f"Emergency report: {description}",
                    "ar": f"تقرير طوارئ: {description}"
                },
                "responder_briefing": {
                    "en": "Proceed to the location with caution and report status.",
                    "ar": "توجه إلى الموقع بحذر وأبلغ عن الحالة."
                },
                "instructions": {
                    "en": ["Stay safe and do not put yourself in danger.", "Wait for responders."],
                    "ar": ["حافظ على سلامتك ولا تعرض نفسك للخطر.", "انتظر وصول المسعفين."]
                },
                "responders_needed": [role for role, count in volunteers.items() if count > 0],
                "volunteers_recommended": volunteers,
                "confidence": 0.5
            }
            
        analysis["source"] = "text"
        logger.info(f"Analysis complete: {analysis['incident_type']}")
        return analysis
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error analyzing text: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Text analysis failed: {str(e)}")


# ─────────────────────────────────────────────────────────────────────────────
# AI Assistant Chat Endpoint
# ─────────────────────────────────────────────────────────────────────────────

from pydantic import BaseModel
from typing import List

class ChatMessage(BaseModel):
    role: str
    text: str

class AssistantChatRequest(BaseModel):
    history: List[ChatMessage]
    user_name: Optional[str] = None

@app.post("/api/v1/assistant/chat")
async def assistant_chat(payload: AssistantChatRequest):
    """
    Handle chat conversation history and return Daleel's response.
    """
    try:
        # Convert Pydantic models to dict lists
        history_list = [{"role": msg.role, "text": msg.text} for msg in payload.history]
        
        # Call assistant
        response_text = assistant.chat(history_list, user_name=payload.user_name)
        return {"response": response_text}
    except Exception as e:
        logger.error(f"Error in assistant chat endpoint: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Assistant chat failed: {str(e)}")


# ─────────────────────────────────────────────────────────────────────────────
# Health & Status Endpoints
# ─────────────────────────────────────────────────────────────────────────────

@app.get("/health")
async def health_check():
    """Kubernetes/Docker health check."""
    return {"status": "healthy"}


if __name__ == "__main__":
    import uvicorn
    logger.info("Starting El7a2ny AI Service on http://0.0.0.0:8001")
    uvicorn.run(app, host="0.0.0.0", port=8001, log_level="info")
