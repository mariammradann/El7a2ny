# El7a2ny API Testing Guide

This document provides a comprehensive guide for testing the El7a2ny backend APIs. It is divided into two sections:
1. **Automated Testing with Pytest** (using the Django test database)
2. **Manual Testing with Postman** (specifying each URL, method, headers, and body)

---

## 1. Automated Testing with Pytest

We have created an automated test suite under `El7a2ny_backend/tests/test_api.py`. These tests cover user registration, authentication (login), password management, subscription plans, emergency reporting (SOS), and the K-type thermocouple sensor integration.

### Setup Instructions

1. **Activate the Virtual Environment**:
   ```bash
   # Windows (PowerShell)
   .\.venv\Scripts\Activate.ps1
   ```

2. **Install Testing Dependencies**:
   ```bash
   pip install pytest pytest-django
   ```

3. **Running the Tests**:
   To run the complete test suite:
   ```bash
   pytest
   ```
   
   To run with detailed output (verbose):
   ```bash
   pytest -v
   ```

### Test Coverage Summary

- **User Registration**: Tests successful sign-up and validation errors for duplicate emails.
- **User Login (`check_user`)**: Tests credentials checking, successful logins, and invalid password responses.
- **Password Management**: Tests password verification (`/api/auth/password/verify/`) and change API (`/api/auth/password/change/`).
- **Subscriptions**: Tests subscribing to monthly/yearly plans and cancelling them.
- **SOS Emergency Reports**: Tests reporting an incident manually with category, description, and GPS coordinates.
- **Thermocouple Sensor Integration**: 
  - Tests NORMAL temperature readings (logged but no alert).
  - Tests ALERT temperature readings (exceeding 70°C), verifying that a fire incident is automatically created with appropriate severity and status.
  - Tests retrieving the latest sensor reading.

---

## 2. Postman API Testing Plan

Use this reference to set up your requests in Postman.

### Environment Setup (Variables)
Create an environment in Postman with the following variables:
- `base_url`: `http://localhost:8000`
- `user_id`: *(Will be populated with the UUID returned from the Registration/Login response)*

---

### Phase 1: Authentication & User Management

#### 1. Register User
- **URL**: `{{base_url}}/api/register/`
- **Method**: `POST`
- **Headers**:
  - `Content-Type: application/json`
- **Body (JSON)**:
  ```json
  {
    "email": "testuser@el7a2ny.com",
    "password": "SecurePassword123",
    "first_name": "John",
    "last_name": "Doe",
    "phone_number": "01023456789"
  }
  ```
- **Expected Response**: `201 Created`
  ```json
  {
    "message": "Success"
  }
  ```

#### 2. Check User (Login)
- **URL**: `{{base_url}}/api/users/check_user/`
- **Method**: `POST`
- **Headers**:
  - `Content-Type: application/json`
- **Body (JSON)**:
  ```json
  {
    "email": "testuser@el7a2ny.com",
    "password": "SecurePassword123"
  }
  ```
- **Expected Response**: `200 OK`
  ```json
  {
    "message": "Login successful",
    "email": "testuser@el7a2ny.com",
    "user_id": "fef5bed0-1c2e-4a04-bb5c-e5c590c3dcf1",
    "name": "John Doe",
    "user_type": "normal"
  }
  ```
  *(Note: Copy the `user_id` value and save it in your Postman variables)*

#### 3. Verify Password
- **URL**: `{{base_url}}/api/auth/password/verify/`
- **Method**: `POST`
- **Headers**:
  - `Content-Type: application/json`
- **Body (JSON)**:
  ```json
  {
    "user_id": "{{user_id}}",
    "password": "SecurePassword123"
  }
  ```
- **Expected Response**: `200 OK`
  ```json
  {
    "message": "Password verified"
  }
  ```

#### 4. Change Password
- **URL**: `{{base_url}}/api/auth/password/change/`
- **Method**: `POST`
- **Headers**:
  - `Content-Type: application/json`
- **Body (JSON)**:
  ```json
  {
    "user_id": "{{user_id}}",
    "old_password": "SecurePassword123",
    "new_password": "NewSecurePassword123"
  }
  ```
- **Expected Response**: `200 OK`
  ```json
  {
    "message": "تم تغيير كلمة المرور بنجاح"
  }
  ```

---

### Phase 2: Subscriptions

#### 1. Subscribe to Plan
- **URL**: `{{base_url}}/api/subscription/subscribe/`
- **Method**: `POST`
- **Headers**:
  - `Content-Type: application/json`
- **Body (JSON)**:
  ```json
  {
    "user_id": "{{user_id}}",
    "plan_type": "monthly"
  }
  ```
- **Expected Response**: `200 OK`
  ```json
  {
    "message": "User subscribed to monthly plan successfully",
    "is_plus": true,
    "plan_type": "monthly",
    "subscription_date": "2026-05-29T20:00:00Z",
    "renewal_date": "2026-06-28T20:00:00Z"
  }
  ```

#### 2. Get User Subscription Status
- **URL**: `{{base_url}}/api/subscription/{{user_id}}/`
- **Method**: `GET`
- **Expected Response**: `200 OK` containing subscription metadata.

#### 3. Cancel Subscription
- **URL**: `{{base_url}}/api/subscription/cancel/`
- **Method**: `POST`
- **Headers**:
  - `Content-Type: application/json`
- **Body (JSON)**:
  ```json
  {
    "user_id": "{{user_id}}"
  }
  ```
- **Expected Response**: `200 OK`
  ```json
  {
    "message": "Subscription cancelled successfully",
    "is_plus": false
  }
  ```

---

### Phase 3: Emergency Reporting & Sensor Readings

#### 1. Report SOS Emergency manually
- **URL**: `{{base_url}}/api/emergency/reports/`
- **Method**: `POST`
- **Headers**:
  - `Content-Type: application/json`
- **Body (JSON)**:
  ```json
  {
    "user_id": "{{user_id}}",
    "category": "medical",
    "description": "Patient experiencing severe chest pain. Needs urgent ambulance.",
    "latitude": 30.0561,
    "longitude": 31.2394,
    "address": "Downtown, Cairo",
    "city": "Cairo",
    "region": "Egypt",
    "is_for_me": "true"
  }
  ```
- **Expected Response**: `201 Created` with incident details and fallback AI analysis triggering.

#### 2. Send Thermocouple Sensor Temperature (Normal)
- **URL**: `{{base_url}}/api/sensor/temperature/`
- **Method**: `POST`
- **Headers**:
  - `Content-Type: application/json`
- **Body (JSON)**:
  ```json
  {
    "user_id": "{{user_id}}",
    "temperature": 27.5,
    "humidity": 0.0,
    "is_alert": false,
    "alert_level": "🟢 NORMAL"
  }
  ```
- **Expected Response**: `201 Created`
  ```json
  {
    "message": "reading saved",
    "temperature": 27.5,
    "humidity": 0.0,
    "is_alert": false,
    "alert_level": "NORMAL",
    "alert_label": "🟢 NORMAL",
    "timestamp": "2026-05-29T20:30:00Z",
    "incident_id": null,
    "incident_status": null
  }
  ```

#### 3. Send Thermocouple Sensor Temperature (Alert - Fire Incident)
- **URL**: `{{base_url}}/api/sensor/temperature/`
- **Method**: `POST`
- **Headers**:
  - `Content-Type: application/json`
- **Body (JSON)**:
  ```json
  {
    "user_id": "{{user_id}}",
    "temperature": 85.5,
    "humidity": 0.0,
    "is_alert": true,
    "alert_level": "🚨 ALERT"
  }
  ```
- **Expected Response**: `201 Created`
  ```json
  {
    "message": "alert recorded",
    "temperature": 85.5,
    "humidity": 0.0,
    "is_alert": true,
    "alert_level": "ALERT",
    "alert_label": "🚨 ALERT",
    "timestamp": "2026-05-29T20:31:00Z",
    "incident_id": "9a7f34b2-0c9f-4318-912b-bb6c90c3def4",
    "incident_status": "active"
  }
  ```
  *(Note: This automatically spawns a corresponding Incident of category "fire" in the backend Database!)*

#### 4. Get Latest Sensor Reading
- **URL**: `{{base_url}}/api/sensor/latest/?user_id={{user_id}}`
- **Method**: `GET`
- **Expected Response**: `200 OK`
  ```json
  {
    "temperature": 85.5,
    "humidity": 0.0,
    "is_alert": true,
    "timestamp": "2026-05-29T20:31:00Z"
  }
  ```

---

### Phase 4: Admin Management

#### 1. Get Admin Statistics
- **URL**: `{{base_url}}/api/admin/stats/?user_id={{admin_user_id}}`
- **Method**: `GET`
- **Expected Response**: `200 OK` with JSON dashboard stats (e.g. `total_users`, `active_alerts`).
- **Failure case**: Attempting with normal user ID returns `403 Forbidden`.

#### 2. List All Users
- **URL**: `{{base_url}}/api/admin/users/?user_id={{admin_user_id}}`
- **Method**: `GET`
- **Expected Response**: `200 OK` with list of users.

---

### Phase 5: Volunteer Training Academy

#### 1. Get Training Courses
- **URL**: `{{base_url}}/api/training/courses/?user_id={{user_id}}`
- **Method**: `GET`
- **Expected Response**: `200 OK` listing all available courses.

#### 2. Enroll in Course
- **URL**: `{{base_url}}/api/training/courses/{{course_id}}/enroll/`
- **Method**: `POST`
- **Headers**:
  - `Content-Type: application/json`
- **Body (JSON)**:
  ```json
  {
    "user_id": "{{user_id}}"
  }
  ```
- **Expected Response**: `200 OK`
  ```json
  {
    "message": "Enrolled successfully",
    "is_completed": false,
    "enrolled_at": "2026-05-29T20:35:00Z"
  }
  ```

#### 3. Complete Course
- **URL**: `{{base_url}}/api/training/courses/{{course_id}}/complete/`
- **Method**: `POST`
- **Headers**:
  - `Content-Type: application/json`
- **Body (JSON)**:
  ```json
  {
    "user_id": "{{user_id}}"
  }
  ```
- **Expected Response**: `200 OK`
  ```json
  {
    "message": "Course completed successfully",
    "is_completed": true,
    "completed_at": "2026-05-29T20:36:00Z"
  }
  ```

#### 4. Fetch User Badges
- **URL**: `{{base_url}}/api/training/badges/{{user_id}}/`
- **Method**: `GET`
- **Expected Response**: `200 OK`
  ```json
  {
    "badges": [
      {
        "badge_name_en": "Certified Responder",
        "badge_name_ar": "مسعف معتمد",
        "course_title_en": "First Aid Basics",
        "course_id": "course-uuid",
        "completed_at": "2026-05-29T20:36:00Z"
      }
    ],
    "total": 1
  }
  ```

---

### Phase 6: Incident Chat & Responders

#### 1. Respond to Alert
- **URL**: `{{base_url}}/alerts/{{incident_id}}/respond/`
- **Method**: `POST`
- **Headers**:
  - `Content-Type: application/json`
- **Body (JSON)**:
  ```json
  {
    "user_id": "{{user_id}}",
    "lat": 30.0444,
    "lng": 31.2357,
    "response_seconds": 120
  }
  ```
- **Expected Response**: `201 Created` with responder metadata.

#### 2. Get Incident Responders
- **URL**: `{{base_url}}/alerts/{{incident_id}}/responders/`
- **Method**: `GET`
- **Expected Response**: `200 OK` showing list of active responders.

#### 3. Send Incident Chat Message
- **URL**: `{{base_url}}/alerts/{{incident_id}}/chat/`
- **Method**: `POST`
- **Headers**:
  - `Content-Type: application/json`
- **Body (JSON)**:
  ```json
  {
    "sender_id": "{{user_id}}",
    "sender_name": "John Doe",
    "sender_type": "user",
    "text": "I am on my way with medical kits!"
  }
  ```
- **Expected Response**: `201 Created`

#### 4. Poll Chat Messages (updates)
- **URL**: `{{base_url}}/alerts/{{incident_id}}/chat/poll/?since=2026-05-29T00:00:00Z`
- **Method**: `GET`
- **Expected Response**: `200 OK` returning messages.

---

### Phase 7: Sponsor Management

#### 1. Apply for Sponsorship
- **URL**: `{{base_url}}/api/sponsors/apply/`
- **Method**: `POST`
- **Headers**:
  - `Content-Type: application/json`
- **Body (JSON)**:
  ```json
  {
    "user_id": "{{user_id}}",
    "company_name": "Global Health Partners",
    "contact_person": "Jane Sponsor",
    "phone_number": "01222223333",
    "message": "We would love to sponsor responder equipment."
  }
  ```
- **Expected Response**: `201 Created`
  ```json
  {
    "message": "Sponsor application submitted successfully",
    "request_id": "request-uuid"
  }
  ```

#### 2. List Sponsorship Requests
- **URL**: `{{base_url}}/api/admin/sponsors/requests/`
- **Method**: `GET`
- **Expected Response**: `200 OK`

#### 3. Respond to Sponsor Request (Approve/Reject)
- **URL**: `{{base_url}}/api/admin/sponsors/requests/{{request_id}}/respond/`
- **Method**: `POST`
- **Headers**:
  - `Content-Type: application/json`
- **Body (JSON)**:
  ```json
  {
    "action": "approve"
  }
  ```
- **Expected Response**: `200 OK`
  ```json
  {
    "message": "Sponsor request approved successfully",
    "request_id": "request-uuid",
    "status": "approved"
  }
  ```

---

### Phase 8: AI Assistant & Camera Services

#### 1. Daleel AI Assistant Chat
- **URL**: `{{base_url}}/api/assistant/chat/`
- **Method**: `POST`
- **Headers**:
  - `Content-Type: application/json`
- **Body (JSON)**:
  ```json
  {
    "history": [
      {
        "role": "user",
        "text": "What is the recovery position in first aid?"
      }
    ]
  }
  ```
- **Expected Response**: `200 OK` (FastAPI proxy response).

#### 2. Analyze Incident Text via AI
- **URL**: `{{base_url}}/api/incidents/analyze/text/`
- **Method**: `POST`
- **Headers**:
  - `Authorization`: Bearer {{jwt_token}}
  - `Content-Type: application/json`
- **Body (JSON)**:
  ```json
  {
    "incident_id": "{{incident_id}}",
    "description": "Kitchen fire reported, spreading to adjacent cabinets.",
    "location": "Cairo"
  }
  ```
- **Expected Response**: `201 Created` with incident analysis metrics.

#### 3. Start Face Recognition Camera
- **URL**: `{{base_url}}/api/security/camera/start/`
- **Method**: `POST`
- **Headers**:
  - `Content-Type: application/json`
- **Body (JSON)**:
  ```json
  {
    "user_id": "{{user_id}}"
  }
  ```
- **Expected Response**: `200 OK` with start state and process PID.

#### 4. Check Camera Status
- **URL**: `{{base_url}}/api/security/camera/status/?user_id={{user_id}}`
- **Method**: `GET`
- **Expected Response**: `200 OK` showing running status (true/false).

#### 5. Stop Face Recognition Camera
- **URL**: `{{base_url}}/api/security/camera/stop/`
- **Method**: `POST`
- **Headers**:
  - `Content-Type: application/json`
- **Body (JSON)**:
  ```json
  {
    "user_id": "{{user_id}}"
  }
  ```
- **Expected Response**: `200 OK` showing stop state.

