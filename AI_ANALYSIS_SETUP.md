# AI Analysis Integration - Setup Guide

## ✅ What Has Been Integrated

I've successfully integrated AI-powered incident analysis into your El7a2ny backend. This system allows users to analyze incidents using images, videos, voice recordings, or text descriptions to:

- **Detect incident types** (fires, accidents, medical emergencies, etc.)
- **Assign severity levels** (Critical, High, Medium, Low)
- **Generate triage levels** (Red, Orange, Yellow, Green, Black) 
- **Provide emergency instructions** for responders and civilians
- **Transcribe voice recordings** and detect panic/distress

---

## 📦 Components Installed

### 1. **Database Model** (`models.py`)
- ✅ `IncidentAIAnalysis` - Stores AI analysis results linked to incidents
- Fields: severity, triage_level, urgency_score, instructions, responders_needed, summary, etc.

### 2. **AI Client** (`ai_client.py`)
- ✅ New file created for communicating with AI microservice
- Handles image, video, voice, and text analysis
- Saves results to database

### 3. **API Views** (`views.py`)
- ✅ `AnalyzeIncidentImageView` - POST /api/incidents/analyze/image/
- ✅ `AnalyzeIncidentVideoView` - POST /api/incidents/analyze/video/
- ✅ `AnalyzeIncidentVoiceView` - POST /api/incidents/analyze/voice/
- ✅ `AnalyzeIncidentTextView` - POST /api/incidents/analyze/text/
- ✅ `IncidentAIAnalysisDetailView` - GET /api/incidents/<incident_id>/analysis/

### 4. **Serializers** (`serializers.py`)
- ✅ `IncidentAIAnalysisSerializer` - Full response
- ✅ `AnalyzeImageRequestSerializer`, `AnalyzeVideoRequestSerializer`, etc.

### 5. **URL Routes** (`urls.py`)
- ✅ All 5 endpoints registered and ready

### 6. **Settings** (`settings.py`)
- ✅ AI_SERVICE_URL = "http://localhost:8001"
- ✅ AI_SERVICE_TIMEOUT = 120 seconds

---

## 🚀 How to Use

### Step 1: Start the AI Microservice

The AI service should be running on port 8001. If not already running:

```bash
cd d:\El7a2ny-trial\ai_service
python main.py
# or
uvicorn main:app --host 0.0.0.0 --port 8001
```

### Step 2: Make Migrations (If Schema Mismatch Resolved)

If you encounter schema issues, you may need to handle the existing `responders` table:

```bash
cd d:\El7a2ny-trial
python manage.py migrate El7a2ny_backend 0024  # Migrate to just before Responder
python manage.py migrate El7a2ny_backend 0025  # Apply new migrations with IncidentAIAnalysis
```

Or if there are issues, Django may have already handled them. The migration is created at:
- `El7a2ny_backend/migrations/0025_responder_incidentaianalysis.py`

### Step 3: API Usage from Flutter

All endpoints require JWT authentication.

#### **Analyze Image**
```
POST /api/incidents/analyze/image/
Content-Type: multipart/form-data
Header: Authorization: Bearer <jwt_token>

Body:
  incident_id: UUID (string)
  image: File (JPEG/PNG/WebP, max 20MB)
```

#### **Analyze Video**
```
POST /api/incidents/analyze/video/
Content-Type: multipart/form-data
Header: Authorization: Bearer <jwt_token>

Body:
  incident_id: UUID (string)
  video: File (MP4/AVI/MOV, max 200MB)
```

#### **Analyze Voice**
```
POST /api/incidents/analyze/voice/
Content-Type: multipart/form-data
Header: Authorization: Bearer <jwt_token>

Body:
  incident_id: UUID (string)
  audio: File (WAV/MP3/OGG/M4A, max 50MB)

Response includes:
  - transcription: String (speech-to-text)
  - panic_detected: Boolean
  - distress_keywords: Array
  - analysis: Full IncidentAIAnalysis object
```

#### **Analyze Text**
```
POST /api/incidents/analyze/text/
Content-Type: application/json
Header: Authorization: Bearer <jwt_token>

Body:
  {
    "incident_id": "uuid-string",
    "description": "Building is on fire with people trapped inside",
    "location": "Optional location string"
  }
```

#### **Get Saved Analysis**
```
GET /api/incidents/<incident_id>/analysis/
Header: Authorization: Bearer <jwt_token>
```

---

## 📊 Response Format

All analyze endpoints return this structure:

```json
{
  "analysis_id": "uuid",
  "incident_id": "uuid",
  "incident_type": "Building Fire",
  "severity": "Critical",
  "triage_level": "Red",
  "triage_color": "#FF0000",
  "urgency_score": 9,
  "alert_level": "CRITICAL ALERT",
  "risk_level": "Extreme risk to life",
  "dispatch_priority": "Priority 1 — Immediate Response",
  "summary": "Large fire in residential building with people trapped.",
  "responder_briefing": "Multi-floor fire. Aerial ladder required. EMS standby.",
  "instructions": [
    "Evacuate immediately",
    "Use stairs — not elevators",
    "Stay low to avoid smoke"
  ],
  "responders_needed": ["Firefighters", "Ambulance"],
  "confidence": 0.92,
  "source": "image|video|voice|text",
  "analyzed_at": "2025-01-15T14:30:00Z"
}
```

---

## 🔧 Configuration

To change the AI service URL or timeout in production:

Edit `El7a2ny_backend/settings.py`:

```python
# Change these values
AI_SERVICE_URL     = "http://your-ai-service:8001"  # Or your production URL
AI_SERVICE_TIMEOUT = 180  # Increase for slower networks
```

---

## ⚙️ Dependencies

All required dependencies are already installed:
- ✅ `httpx` - For making async HTTP requests to AI service
- ✅ `djangorestframework` - Already in your project
- ✅ `djangorestframework-simplejwt` - For JWT auth

---

## 🐛 Troubleshooting

### Issue: "Cannot reach AI service"
**Solution:** Ensure AI service is running on port 8001:
```bash
# Check if port 8001 is in use
netstat -ano | findstr :8001
# If not, start the service
python d:\El7a2ny-trial\ai_service\main.py
```

### Issue: "AI service timed out"
**Solution:** Increase timeout in settings.py:
```python
AI_SERVICE_TIMEOUT = 300  # 5 minutes
```

### Issue: JWT Authentication Failed
**Solution:** Ensure Flutter is sending valid JWT token:
```
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
```

### Issue: File upload too large
**Solution:** The limits are:
- Images: 20MB
- Videos: 200MB
- Audio: 50MB

Increase in `ai_client.py` if needed.

---

## 📝 Example Usage (Python/cURL)

```bash
# 1. Create an incident first (if not already created)
curl -X POST http://localhost:8000/api/incidents/ \
  -F "user_id=<user-uuid>" \
  -F "category=fire" \
  -F "description=Building on fire" \
  -F "latitude=30.0444" \
  -F "longitude=31.2357"

# 2. Then analyze an image
curl -X POST http://localhost:8000/api/incidents/analyze/image/ \
  -H "Authorization: Bearer <jwt-token>" \
  -F "incident_id=<incident-uuid>" \
  -F "image=@/path/to/image.jpg"
```

---

## ✅ Next Steps

1. **Ensure AI service is running** on port 8001
2. **Test the endpoints** using Postman or curl
3. **Update Flutter app** to use new analysis endpoints
4. **Monitor logs** in Django and AI service for any issues

---

## 📚 Files Modified

- `El7a2ny_backend/models.py` - Added IncidentAIAnalysis model
- `El7a2ny_backend/ai_client.py` - Created (new file)
- `El7a2ny_backend/views.py` - Added 5 analysis views
- `El7a2ny_backend/serializers.py` - Added analysis serializers
- `El7a2ny_backend/urls.py` - Added 5 new routes
- `El7a2ny_backend/settings.py` - Added AI service config
- `El7a2ny_backend/migrations/0025_*.py` - Created (new migration)

---

## 🎯 Key Features

✅ **Multi-modal Analysis** - Images, videos, audio, or text
✅ **Emergency Prioritization** - Triage levels (Red/Orange/Yellow/Green)
✅ **Responder Briefing** - Automatic emergency instructions
✅ **Confidence Scoring** - Know how confident the AI is
✅ **Voice Transcription** - Automatic speech-to-text for audio
✅ **Panic Detection** - Identifies distress in voice recordings
✅ **Persistent Storage** - Analysis saved to database for history
✅ **JWT Protected** - Secure endpoints with authentication

---

## 💡 Pro Tips

- Voice analysis takes longer (up to 120 seconds) due to transcription
- Store `analysis_id` for tracking and audit trails
- Use `confidence` score to decide if re-analysis is needed
- `instructions` array is perfect for in-app emergency notifications
- `responders_needed` helps dispatch the right teams

---

🎉 **Your AI analysis system is now ready to detect emergencies from photos and videos!**
