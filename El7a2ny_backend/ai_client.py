"""
El7a2ny_backend / ai_client.py

This is the ONLY place Django talks to the AI microservice.
All forwarding logic lives here — views stay clean.
"""

import os
import logging
from pathlib import Path
from typing import IO

import httpx
from django.conf import settings

logger = logging.getLogger(__name__)

# ── Config ────────────────────────────────────────────────────────────────────
AI_SERVICE_URL = getattr(settings, "AI_SERVICE_URL", "http://localhost:8001")
AI_TIMEOUT     = getattr(settings, "AI_SERVICE_TIMEOUT", 120)  # seconds


class AIServiceError(Exception):
    """Raised when the AI microservice returns an error or is unreachable."""
    pass


# ── Internal helper ───────────────────────────────────────────────────────────

def _post(endpoint: str, **kwargs) -> dict:
    """
    Make a synchronous POST to the AI microservice.
    Raises AIServiceError on any failure.
    """
    url = f"{AI_SERVICE_URL}{endpoint}"
    try:
        with httpx.Client(timeout=AI_TIMEOUT) as client:
            response = client.post(url, **kwargs)
        response.raise_for_status()
        return response.json()
    except httpx.TimeoutException:
        raise AIServiceError("AI service timed out. Please try again.")
    except httpx.ConnectError:
        raise AIServiceError("Cannot reach AI service. Is it running on port 8001?")
    except httpx.HTTPStatusError as e:
        detail = e.response.json().get("detail", str(e)) if e.response.content else str(e)
        raise AIServiceError(f"AI service error {e.response.status_code}: {detail}")
    except Exception as e:
        logger.error(f"Unexpected AI client error: {e}", exc_info=True)
        raise AIServiceError(f"Unexpected error: {str(e)}")


# ── Public API ────────────────────────────────────────────────────────────────

def analyze_image(image_file: IO, filename: str, content_type: str = "image/jpeg", description: str = None, user_trust_score: float = 1.0) -> dict:
    """
    Forward an image file to the AI microservice.
    Returns the raw AI JSON dict.
    """
    logger.info(f"Forwarding image to AI service: {filename}")
    data = {}
    if description:
        data["description"] = description
    data["user_trust_score"] = user_trust_score
    return _post(
        "/api/v1/analyze/image",
        files={"file": (filename, image_file, content_type)},
        data=data,
    )


def analyze_video(video_file: IO, filename: str, content_type: str = "video/mp4", description: str = None, user_trust_score: float = 1.0) -> dict:
    """Forward a video file to the AI microservice."""
    logger.info(f"Forwarding video to AI service: {filename}")
    data = {}
    if description:
        data["description"] = description
    data["user_trust_score"] = user_trust_score
    return _post(
        "/api/v1/analyze/video",
        files={"file": (filename, video_file, content_type)},
        data=data,
    )


def analyze_voice(audio_file: IO, filename: str, content_type: str = "audio/wav") -> dict:
    """
    Forward a voice recording to the AI microservice.
    Returns VoiceTranscription JSON (includes transcription + analysis).
    """
    logger.info(f"Forwarding audio to AI service: {filename}")
    return _post(
        "/api/v1/analyze/voice",
        files={"file": (filename, audio_file, content_type)},
    )


def analyze_text(description: str, location: str | None = None) -> dict:
    """Forward a text description to the AI microservice."""
    logger.info(f"Forwarding text to AI service ({len(description)} chars)")
    payload = {"description": description}
    if location:
        payload["location"] = location
    return _post("/api/v1/analyze/text", data=payload)


def save_ai_result(incident, ai_data: dict, source: str):
    """
    Parse the AI microservice JSON response and save it
    as an IncidentAIAnalysis linked to the given Incident.

    Works for image, video, text responses.
    For voice, pass ai_data["analysis"] (the nested dict).

    Returns the saved IncidentAIAnalysis instance.
    """
    import json as _json
    from .models import IncidentAIAnalysis  # local import avoids circular deps

    # Voice responses have a nested 'analysis' key
    analysis_data = ai_data.get("analysis", ai_data)

    def _to_json_str(value):
        """If value is a dict/list, JSON-encode it; otherwise return as-is."""
        if isinstance(value, (dict, list)):
            return _json.dumps(value, ensure_ascii=False)
        return value or ""

    summary_raw   = analysis_data.get("summary", "")
    briefing_raw  = analysis_data.get("responder_briefing", "")
    instructions_raw = analysis_data.get("instructions", [])

    # Extract bilingual summaries
    summary_en = ""
    summary_ar = ""
    if isinstance(summary_raw, dict):
        summary_en = summary_raw.get("en", "")
        summary_ar = summary_raw.get("ar", "")
    else:
        summary_en = str(summary_raw)

    # Extract bilingual user instructions
    user_inst_en = []
    user_inst_ar = []
    if isinstance(instructions_raw, dict):
        user_inst_en = instructions_raw.get("en", [])
        user_inst_ar = instructions_raw.get("ar", [])
    elif isinstance(instructions_raw, list):
        user_inst_en = instructions_raw
        user_inst_ar = instructions_raw

    # Extract bilingual volunteer/responder instructions
    vol_inst_en = []
    vol_inst_ar = []
    if isinstance(briefing_raw, dict):
        vol_inst_en = briefing_raw.get("en", [])
        vol_inst_ar = briefing_raw.get("ar", [])
    elif isinstance(briefing_raw, list):
        vol_inst_en = briefing_raw
        vol_inst_ar = briefing_raw

    # Delete any previous analysis for this incident (re-analysis case)
    IncidentAIAnalysis.objects.filter(incident=incident).delete()

    obj = IncidentAIAnalysis.objects.create(
        incident          = incident,
        incident_type     = analysis_data.get("incident_type", "Unknown"),
        severity          = analysis_data.get("severity", "Unknown"),
        triage_level      = analysis_data.get("triage_level", "Yellow"),
        urgency_score     = int(analysis_data.get("urgency_score", 5)),
        risk_level        = analysis_data.get("risk_level", ""),
        dispatch_priority = analysis_data.get("dispatch_priority", ""),
        
        is_real           = analysis_data.get("is_real", True),
        fake_probability  = analysis_data.get("fake_probability", 0.0),
        verification_methods = analysis_data.get("verification_methods", {}),
        raw_detections    = analysis_data.get("raw_detections", []),
        detected_objects  = analysis_data.get("detected_objects", {}),
        volunteers_recommended = analysis_data.get("volunteers_recommended", {}),

        summary           = _to_json_str(summary_raw),
        responder_briefing= _to_json_str(briefing_raw),
        summary_en        = summary_en,
        summary_ar        = summary_ar,
        instructions      = instructions_raw,
        user_instructions_en = user_inst_en,
        user_instructions_ar = user_inst_ar,
        volunteer_instructions_en = vol_inst_en,
        volunteer_instructions_ar = vol_inst_ar,

        responders_needed = analysis_data.get("responders_needed", []),
        confidence        = analysis_data.get("confidence"),
        source            = source,
        raw_response      = ai_data,   # store full response for debugging
    )

    logger.info(
        f"AI analysis saved: incident={incident.incident_id} "
        f"severity={obj.severity} triage={obj.triage_level}"
    )
    return obj

