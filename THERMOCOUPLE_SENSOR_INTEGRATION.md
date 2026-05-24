# Arduino Thermocouple Sensor Integration - Changes Summary

## Overview

Updated Django backend to match Arduino ESP32 K-Type Thermocouple Fire Monitor data structure and thresholds.

## Changes Made

### 1. **SensorReading Model** ([models.py](El7a2ny_backend/models.py#L203))

Added `alert_level` field to track temperature alert classifications:

**New Field:**

```python
alert_level = models.CharField(
    max_length=20,
    choices=[
        ("NORMAL", "🟢 NORMAL"),
        ("WARNING", "⚠️ WARNING"),
        ("ALERT", "🚨 ALERT"),
        ("CRITICAL", "🔥 CRITICAL"),
    ],
    default="NORMAL"
)
```

**Temperature Thresholds (°C):**

- **NORMAL**: < 40°C (🟢 green status)
- **WARNING**: 40-70°C (⚠️ yellow status, logged but not sent as alert)
- **ALERT**: 70-120°C (🚨 orange status, auto-incident created)
- **CRITICAL**: ≥ 120°C (🔥 red status, urgent incident created)

---

### 2. **receive_temperature API Endpoint** ([views.py](El7a2ny_backend/views.py#L1263))

**Updated Functionality:**

- Now classifies temperature automatically using `classify_temperature()` function
- Creates `ALERT` or `CRITICAL` incidents based on temperature level
- Stores `alert_level` in SensorReading model
- Returns enhanced response with alert classification

**Request Format:**

```json
{
  "user_id": "uuid",
  "temperature": 85.5,
  "humidity": 0,
  "is_alert": true,
  "alert_level": "🚨 ALERT"
}
```

**Response Format:**

```json
{
  "message": "alert recorded",
  "temperature": 85.5,
  "humidity": 0,
  "is_alert": true,
  "alert_level": "ALERT",
  "alert_label": "🚨 ALERT",
  "timestamp": "2026-05-24T12:30:45.123456Z",
  "incident_id": "incident-uuid",
  "incident_status": "active"
}
```

**Auto-Incident Creation:**

- When `is_alert=true` AND `alert_level` is "ALERT" or "CRITICAL"
- Category: "fire" (K-type thermocouple is fire detection sensor)
- Status: "active" for ALERT, "critical" for CRITICAL
- Description includes: temperature, humidity, timestamp, alert level, device info
- Location: Auto-created at Cairo (29.9649, 31.2592) or matched if exists

---

### 3. **fetch_sensors Endpoint** ([views.py](lines ~1499-1566))

**Updated Display Logic:**
Now shows all sensor readings with proper Arduino thermocouple thresholds:

**Status Mapping:**

- `status="normal"` if temp < 40°C (green)
- `status="warning"` if temp 40-70°C (yellow)
- `status="danger"` if temp 70-120°C (orange)
- `status="critical"` if temp ≥ 120°C (red)

**Enhanced Response Fields:**

```json
{
  "id": 1,
  "type": "heat",
  "value": "85.5",
  "unit": "°C",
  "status": "danger",
  "alert_level": "ALERT",
  "alert_label": "🚨 ALERT",
  "is_alert": true,
  "humidity": 0,
  "user_id": "uuid",
  "user_name": "Device Name",
  "lat": 29.9649,
  "lng": 31.2592,
  "updated_at": "2026-05-24T12:30:45.123456Z"
}
```

---

### 4. **Helper Functions Added** ([views.py](lines ~1261-1284))

```python
def classify_temperature(temp):
    """Classify temperature based on Arduino thresholds"""
    if temp >= 120.0: return "CRITICAL"
    elif temp >= 70.0: return "ALERT"
    elif temp >= 40.0: return "WARNING"
    return "NORMAL"

def get_alert_label(alert_level):
    """Convert alert level to emoji-labeled display text"""
    # Returns matching emoji labels from Arduino code
```

---

### 5. **Database Migration**

Created migration file: `0028_sensorreading_alert_level.py`

- Adds `alert_level` field to `sensor_readings` table
- Default value: "NORMAL"
- Includes help text with threshold information

---

## Arduino Code Integration

The ESP32 sketch sends data matching this structure:

```cpp
{
    "user_id": "fef5bed0-1c2e-4a04-bb5c-e5c590c3dcf1",
    "temperature": temp,
    "humidity": 0,              // K-type has no humidity
    "is_alert": isAlertActive(level),
    "alert_level": levelLabel(level)
}
```

**Thresholds from Arduino Code:**

- `TEMP_WARNING = 40.0°C`
- `TEMP_ALERT = 70.0°C`
- `TEMP_CRITICAL = 120.0°C`

Django backend now validates and uses these exact thresholds.

---

## API Endpoints

| Endpoint                   | Method | Purpose                                  |
| -------------------------- | ------ | ---------------------------------------- |
| `/api/sensor/temperature/` | POST   | Receive temperature data from ESP32      |
| `/api/sensor/latest/`      | GET    | Get latest reading for a user            |
| `/api/sensors/`            | GET    | Fetch all sensor readings (new endpoint) |

---

## Testing the Integration

### 1. Send Temperature Data:

```bash
curl -X POST http://192.168.1.11:8000/api/sensor/temperature/ \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "fef5bed0-1c2e-4a04-bb5c-e5c590c3dcf1",
    "temperature": 85.5,
    "humidity": 0,
    "is_alert": true,
    "alert_level": "🚨 ALERT"
  }'
```

### 2. View All Sensors:

```bash
curl http://192.168.1.11:8000/api/sensors/
```

### 3. Check Auto-Created Incident:

- Navigate to incidents list
- Filter by category: "fire"
- Status should be "active" or "critical" based on temperature

---

## Migration Status

⚠️ **Note:** There is a pre-existing migration error in `0016_alter_helpinitiative_options_and_more` related to PostgreSQL schema naming.

**To apply the new migration once migrations are working:**

```bash
python manage.py migrate El7a2ny_backend
```

---

## Flutter App Integration

The sensors page will now display:

- ✅ All temperature readings with correct thresholds
- ✅ Alert levels and emoji labels
- ✅ Status indicator colors (normal/warning/danger/critical)
- ✅ User who owns the sensor
- ✅ Last update time
- ✅ Humidity value (0 for thermocouple)

---

## Files Modified

1. **[El7a2ny_backend/models.py](models.py)** - Added `alert_level` to SensorReading model
2. **[El7a2ny_backend/views.py](views.py)** - Updated receive_temperature and fetch_sensors endpoints
3. **[El7a2ny_backend/migrations/0028_sensorreading_alert_level.py](migrations/0028_sensorreading_alert_level.py)** - New migration

---

## Next Steps

1. ✅ Apply database migration once schema error is resolved
2. ✅ Test ESP32 data transmission to `/api/sensor/temperature/`
3. ✅ Verify incidents are auto-created for ALERT and CRITICAL levels
4. ✅ Confirm sensors page displays all readings with correct status indicators
5. ⏳ Monitor fire detection accuracy with live sensor data
