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
async def analyze_image(file: UploadFile = File(...)):
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
        
        # Send to Gemini
        logger.info("Sending image to Gemini for analysis...")
        response = client.models.generate_content(
            model="gemini-2.0-flash",
            contents=[
                ANALYSIS_PROMPT,
                {
                    "mime_type": file.content_type,
                    "data": content,
                }
            ]
        )
        
        analysis = parse_json_response(response.text)
        analysis = validate_analysis_response(analysis)
        analysis["source"] = "image"
        
        logger.info(f"Analysis complete: {analysis['incident_type']} (Severity: {analysis['severity']})")
        return analysis
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error analyzing image: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Image analysis failed: {str(e)}")


@app.post("/api/v1/analyze/video")
async def analyze_video(file: UploadFile = File(...)):
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
        
        # Save to temp file for Gemini
        with tempfile.NamedTemporaryFile(delete=False, suffix=".mp4") as tmp:
            tmp.write(content)
            tmp_path = tmp.name
        
        try:
            # Send to Gemini
            logger.info("Sending video to Gemini for analysis...")
            response = client.models.generate_content(
                model="gemini-2.0-flash",
                contents=[
                    ANALYSIS_PROMPT,
                    {
                        "mime_type": file.content_type,
                        "data": content,
                    }
                ]
            )
            
            analysis = parse_json_response(response.text)
            analysis = validate_analysis_response(analysis)
            analysis["source"] = "video"
            
            logger.info(f"Analysis complete: {analysis['incident_type']}")
            return analysis
            
        finally:
            os.unlink(tmp_path)
        
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
        response = client.models.generate_content(
            model="gemini-2.0-flash",
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
        response = client.models.generate_content(
            model="gemini-2.0-flash",
            contents=[
                prompt,
                f"Incident description: {description}"
            ]
        )
        
        analysis = parse_json_response(response.text)
        analysis = validate_analysis_response(analysis)
        analysis["source"] = "text"
        
        logger.info(f"Analysis complete: {analysis['incident_type']}")
        return analysis
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error analyzing text: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Text analysis failed: {str(e)}")


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
