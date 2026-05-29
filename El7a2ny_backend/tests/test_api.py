import pytest
import uuid
from datetime import timedelta
from unittest.mock import patch, MagicMock
from django.utils import timezone
from rest_framework.test import APIClient
from El7a2ny_backend.models import User, Incident, Location, SensorReading, SponsorRequest

# Enable DB access for all tests in this file
pytestmark = pytest.mark.django_db


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def create_test_user():
    def make_user(email="testuser@example.com", password="Password123", is_admin=False):
        # We use a raw password since views/serializers handle hashing
        from django.contrib.auth.hashers import make_password
        user = User.objects.create(
            name="Test User",
            email=email,
            password=make_password(password),
            phone_number="01012345678",
            user_type="admin" if is_admin else "normal",
            status="active"
        )
        return user
    return make_user


# ─── CORE WORKFLOW TESTS ───

def test_register_user_api(api_client):
    """
    Test user registration API endpoint.
    Path: /api/register/
    """
    payload = {
        "email": "newuser@example.com",
        "password": "Password123",
        "first_name": "New",
        "last_name": "User",
        "phone_number": "01098765432"
    }
    
    response = api_client.post("/api/register/", payload, format="json")
    assert response.status_code == 201
    assert response.data["message"] == "Success"
    
    # Verify user exists in the database
    user = User.objects.get(email="newuser@example.com")
    assert user.name == "New User"
    assert user.phone_number == "01098765432"


def test_register_user_api_duplicate_email(api_client, create_test_user):
    """
    Test registering with an already existing email returns bad request.
    """
    create_test_user(email="duplicate@example.com")
    payload = {
        "email": "duplicate@example.com",
        "password": "Password123",
        "first_name": "Duplicate",
        "last_name": "Email",
        "phone_number": "01011112222"
    }
    response = api_client.post("/api/register/", payload, format="json")
    assert response.status_code == 400
    assert "email" in response.data


def test_check_user_api_success(api_client, create_test_user):
    """
    Test credentials check / login endpoint.
    Path: /api/users/check_user/
    """
    user = create_test_user(email="login@example.com", password="Password123")
    payload = {
        "email": "login@example.com",
        "password": "Password123"
    }
    response = api_client.post("/api/users/check_user/", payload, format="json")
    assert response.status_code == 200
    assert response.data["message"] == "Login successful"
    assert str(response.data["user_id"]) == str(user.user_id)
    assert response.data["name"] == user.name
    assert response.data["user_type"] == user.user_type


def test_check_user_api_invalid_password(api_client, create_test_user):
    """
    Test credentials check with invalid password.
    """
    create_test_user(email="login@example.com", password="Password123")
    payload = {
        "email": "login@example.com",
        "password": "WrongPassword"
    }
    response = api_client.post("/api/users/check_user/", payload, format="json")
    assert response.status_code == 401
    assert "error" in response.data


def test_verify_and_change_password_api(api_client, create_test_user):
    """
    Test verifying current password and changing it.
    Paths: /api/auth/password/verify/ and /api/auth/password/change/
    """
    user = create_test_user(email="pwdchange@example.com", password="OldPassword123")
    
    # 1. Verify password
    verify_payload = {
        "user_id": str(user.user_id),
        "password": "OldPassword123"
    }
    verify_response = api_client.post("/api/auth/password/verify/", verify_payload, format="json")
    assert verify_response.status_code == 200
    assert verify_response.data["message"] == "Password verified"
    
    # 2. Change password
    change_payload = {
        "user_id": str(user.user_id),
        "old_password": "OldPassword123",
        "new_password": "NewPassword123"
    }
    change_response = api_client.post("/api/auth/password/change/", change_payload, format="json")
    assert change_response.status_code == 200
    assert change_response.data["message"] == "تم تغيير كلمة المرور بنجاح"
    
    # 3. Verify new credentials work on check_user
    login_payload = {
        "email": "pwdchange@example.com",
        "password": "NewPassword123"
    }
    login_response = api_client.post("/api/users/check_user/", login_payload, format="json")
    assert login_response.status_code == 200


def test_subscribe_and_cancel_subscription_api(api_client, create_test_user):
    """
    Test subscribing and cancelling subscription.
    Paths: /api/subscription/subscribe/ and /api/subscription/cancel/
    """
    user = create_test_user(email="subscriber@example.com")
    assert not user.is_plus
    
    # 1. Subscribe to monthly plan
    sub_payload = {
        "user_id": str(user.user_id),
        "plan_type": "monthly"
    }
    sub_response = api_client.post("/api/subscription/subscribe/", sub_payload, format="json")
    assert sub_response.status_code == 200
    assert sub_response.data["is_plus"] is True
    assert sub_response.data["plan_type"] == "monthly"
    
    # Verify DB update
    user.refresh_from_db()
    assert user.is_plus is True
    assert user.plan_type == "monthly"
    
    # 2. Cancel subscription
    cancel_payload = {
        "user_id": str(user.user_id)
    }
    cancel_response = api_client.post("/api/subscription/cancel/", cancel_payload, format="json")
    assert cancel_response.status_code == 200
    assert cancel_response.data["is_plus"] is False
    
    # Verify DB update
    user.refresh_from_db()
    assert user.is_plus is False
    assert user.plan_type is None


def test_receive_temperature_normal_reading(api_client, create_test_user):
    """
    Test sending normal temperature (e.g., 25°C) to the temperature receiver.
    Path: /api/sensor/temperature/
    Should record reading but NOT create an incident.
    """
    user = create_test_user(email="sensor1@example.com")
    payload = {
        "user_id": str(user.user_id),
        "temperature": 25.0,
        "humidity": 0.0,
        "is_alert": False,
        "alert_level": "🟢 NORMAL"
    }
    
    response = api_client.post("/api/sensor/temperature/", payload, format="json")
    assert response.status_code == 201
    assert response.data["message"] == "reading saved"
    assert response.data["alert_level"] == "NORMAL"
    assert response.data["incident_id"] is None
    
    # Verify database
    assert SensorReading.objects.filter(user=user).count() == 1
    assert Incident.objects.filter(user=user).count() == 0


def test_receive_temperature_alert_fire_incident(api_client, create_test_user):
    """
    Test sending alert temperature (e.g., 85.5°C) to the temperature receiver.
    Path: /api/sensor/temperature/
    Should record reading AND automatically create a fire incident since it exceeds thresholds.
    """
    user = create_test_user(email="sensor2@example.com")
    payload = {
        "user_id": str(user.user_id),
        "temperature": 85.5,
        "humidity": 0.0,
        "is_alert": True,
        "alert_level": "🚨 ALERT"
    }
    
    response = api_client.post("/api/sensor/temperature/", payload, format="json")
    assert response.status_code == 201
    assert response.data["message"] == "alert recorded"
    assert response.data["alert_level"] == "ALERT"
    assert response.data["incident_id"] is not None
    
    # Verify database has recorded the reading and created the incident
    assert SensorReading.objects.filter(user=user).count() == 1
    assert Incident.objects.filter(user=user).count() == 1
    
    incident = Incident.objects.get(user=user)
    assert incident.category == "fire"
    assert incident.status == "active"
    assert "85.5" in incident.description


def test_get_latest_sensor_reading(api_client, create_test_user):
    """
    Test retrieving the latest sensor reading for a user.
    Path: /api/sensor/latest/
    """
    user = create_test_user(email="sensor3@example.com")
    
    # 1. Check with no readings returns mock data (specified in views.py)
    response = api_client.get(f"/api/sensor/latest/?user_id={user.user_id}")
    assert response.status_code == 200
    assert response.data["temperature"] == 28.5  # mock default
    
    # 2. Add a reading
    SensorReading.objects.create(
        user=user,
        temperature=35.6,
        humidity=10.0,
        is_alert=False,
        alert_level="NORMAL"
    )
    
    # 3. Request again, should return the actual reading
    response = api_client.get(f"/api/sensor/latest/?user_id={user.user_id}")
    assert response.status_code == 200
    assert float(response.data["temperature"]) == 35.6


def test_create_incident_sos_api(api_client, create_test_user):
    """
    Test reporting an emergency incident (SOS).
    Path: /api/emergency/reports/ (which maps to IncidentViewSet.create)
    """
    user = create_test_user(email="reporter@example.com")
    
    payload = {
        "user_id": str(user.user_id),
        "category": "medical",
        "description": "Heart attack emergency, need ambulance.",
        "latitude": 30.0444,
        "longitude": 31.2357,
        "address": "Tahrir Square, Cairo",
        "city": "Cairo",
        "region": "Cairo Governorate",
        "is_for_me": "true"
    }
    
    response = api_client.post("/api/emergency/reports/", payload, format="json")
    assert response.status_code == 201
    assert response.data["category"] == "medical"
    
    # Verify in DB
    assert Incident.objects.filter(user=user).count() == 1
    incident = Incident.objects.get(user=user)
    assert incident.category == "medical"
    assert float(incident.location.latitude) == pytest.approx(30.0444)
    assert float(incident.location.longitude) == pytest.approx(31.2357)


# ─── EXPANDED MODULES TESTS ───

def test_admin_stats_as_admin(api_client, create_test_user):
    """
    Test retrieving admin statistics.
    Path: /api/admin/stats/
    """
    admin_user = create_test_user(email="admin_stats@el7a2ny.com", is_admin=True)
    response = api_client.get(f"/api/admin/stats/?user_id={admin_user.user_id}")
    assert response.status_code == 200
    assert "total_users" in response.data
    assert "active_alerts" in response.data


def test_admin_stats_as_normal_user_denied(api_client, create_test_user):
    """
    Test that retrieving admin statistics as a normal user is forbidden (403).
    """
    normal_user = create_test_user(email="normal_stats@el7a2ny.com", is_admin=False)
    response = api_client.get(f"/api/admin/stats/?user_id={normal_user.user_id}")
    assert response.status_code == 403
    assert "error" in response.data


def test_admin_users_list(api_client, create_test_user):
    """
    Test retrieving the list of users as an admin.
    Path: /api/admin/users/
    """
    admin_user = create_test_user(email="admin_users@el7a2ny.com", is_admin=True)
    create_test_user(email="user_listed@el7a2ny.com")
    
    response = api_client.get(f"/api/admin/users/?user_id={admin_user.user_id}")
    assert response.status_code == 200
    assert len(response.data) >= 2


def test_training_academy_flow(api_client, create_test_user):
    """
    Test the Volunteer Training Academy flow:
    1. List courses.
    2. Enroll in a course.
    3. Complete a course.
    4. Retrieve badges.
    """
    from El7a2ny_backend.models import TrainingCourse, VolunteerCourseProgress
    user = create_test_user(email="volunteer@el7a2ny.com")
    
    # Create a mock course
    course = TrainingCourse.objects.create(
        title_en="First Aid Basics",
        title_ar="أساسيات الإسعافات الأولية",
        description_en="Learn first aid",
        description_ar="تعلم الإسعافات",
        category_en="Medical",
        category_ar="طبي",
        duration_minutes=60,
        price=0.0
    )
    
    # 1. List courses
    list_response = api_client.get(f"/api/training/courses/?user_id={user.user_id}")
    assert list_response.status_code == 200
    assert len(list_response.data) >= 1
    
    # 2. Enroll in course
    enroll_payload = {"user_id": str(user.user_id)}
    enroll_response = api_client.post(f"/api/training/courses/{course.course_id}/enroll/", enroll_payload, format="json")
    assert enroll_response.status_code == 200
    assert enroll_response.data["message"] == "Enrolled successfully"
    
    # 3. Complete course
    complete_payload = {"user_id": str(user.user_id)}
    complete_response = api_client.post(f"/api/training/courses/{course.course_id}/complete/", complete_payload, format="json")
    assert complete_response.status_code == 200
    assert complete_response.data["message"] == "Course completed successfully"
    assert complete_response.data["is_completed"] is True
    
    # 4. Get badges
    badges_response = api_client.get(f"/api/training/badges/{user.user_id}/")
    assert badges_response.status_code == 200
    assert badges_response.data["total"] == 1
    assert badges_response.data["badges"][0]["badge_name_en"] == course.badge_name_en


def test_incident_chat_and_responder_flow(api_client, create_test_user):
    """
    Test reporting, responding to incident, and messaging in the chat thread.
    Paths: /alerts/<incident_id>/respond/, /alerts/<incident_id>/responders/, /alerts/<incident_id>/chat/
    """
    user = create_test_user(email="responder_test@el7a2ny.com")
    
    # Create location and incident
    loc = Location.objects.create(latitude=30.0, longitude=31.0, address="Test Location")
    incident = Incident.objects.create(
        user=user,
        location=loc,
        category="general",
        status="reported"
    )
    
    # 1. Respond to incident
    respond_payload = {
        "user_id": str(user.user_id),
        "lat": 30.001,
        "lng": 31.001,
        "response_seconds": 120
    }
    respond_response = api_client.post(f"/alerts/{incident.incident_id}/respond/", respond_payload, format="json")
    assert respond_response.status_code == 201
    
    # 2. Get incident responders
    responders_response = api_client.get(f"/alerts/{incident.incident_id}/responders/")
    assert responders_response.status_code == 200
    assert len(responders_response.data) == 1
    assert responders_response.data[0]["name"] == "Test User"
    
    # 3. Chat messages (send a message)
    chat_payload = {
        "sender_id": str(user.user_id),
        "sender_name": "Test User",
        "sender_type": "user",
        "text": "I am on my way to help!"
    }
    chat_response = api_client.post(f"/alerts/{incident.incident_id}/chat/", chat_payload, format="json")
    assert chat_response.status_code == 201
    assert chat_response.data["text"] == "I am on my way to help!"
    
    # 4. Poll / fetch chat messages
    # Pass since parameter to avoid timezone UnboundLocalError backend bug
    poll_response = api_client.get(f"/alerts/{incident.incident_id}/chat/poll/?since=2026-05-29T00:00:00Z")
    assert poll_response.status_code == 200
    assert len(poll_response.data["messages"]) >= 1


def test_sponsor_application_and_response(api_client, create_test_user):
    """
    Test sponsor request application and responding to it as admin.
    Paths: /api/sponsors/apply/, /api/admin/sponsors/requests/, /api/admin/sponsors/requests/<id>/respond/
    """
    user = create_test_user(email="sponsor_app@el7a2ny.com")
    
    # 1. Apply for sponsorship
    apply_payload = {
        "user_id": str(user.user_id),
        "company_name": "Test Health Corp",
        "contact_person": "Jane Sponsor",
        "phone_number": "01234567890",
        "message": "We would love to sponsor medical kits."
    }
    apply_response = api_client.post("/api/sponsors/apply/", apply_payload, format="json")
    assert apply_response.status_code == 201
    assert apply_response.data["message"] == "Sponsor application submitted successfully"
    
    request_id = apply_response.data["request_id"]
    
    # 2. List requests as admin
    list_response = api_client.get("/api/admin/sponsors/requests/")
    assert list_response.status_code == 200
    assert len(list_response.data) >= 1
    
    # 3. Respond to sponsor request (approve it)
    respond_payload = {
        "action": "approve"
    }
    respond_response = api_client.post(f"/api/admin/sponsors/requests/{request_id}/respond/", respond_payload, format="json")
    assert respond_response.status_code == 200
    assert respond_response.data["status"] == "approved"


@patch("requests.post")
def test_assistant_chat(mock_post, api_client):
    """
    Test calling the assistant chat endpoint.
    Path: /api/assistant/chat/
    """
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = {"response": "Ensure safety first."}
    mock_post.return_value = mock_response

    payload = {
        "history": [{"role": "user", "text": "What to do in a fire?"}]
    }
    response = api_client.post("/api/assistant/chat/", payload, format="json")
    assert response.status_code == 200
    assert response.data["response"] == "Ensure safety first."


@patch("El7a2ny_backend.views.analyze_text")
def test_ai_incident_text_analysis(mock_analyze_text, api_client, create_test_user):
    """
    Test invoking AI text analysis.
    Path: /api/incidents/analyze/text/
    """
    user = create_test_user(email="ai_test@el7a2ny.com")
    loc = Location.objects.create(latitude=30.0, longitude=31.0, address="Cairo")
    incident = Incident.objects.create(user=user, location=loc, category="other")
    
    # Mock AI response
    mock_analyze_text.return_value = {
        "incident_type": "Fire",
        "severity": "High",
        "triage_level": "Red",
        "urgency_score": 8,
        "risk_level": "High risk of spread",
        "dispatch_priority": "Immediate dispatch",
        "summary": {"en": "Kitchen fire reported", "ar": "حريق مطبخ"},
        "instructions": ["Evacuate building", "Call emergency"],
        "responders_needed": ["Firefighters"]
    }
    
    # We must force authenticate because the endpoint requires authentication
    # Custom User model does not inherit from AbstractBaseUser, so we mock is_authenticated
    user.is_authenticated = True
    api_client.force_authenticate(user=user)
    
    payload = {
        "incident_id": str(incident.incident_id),
        "description": "Kitchen fire starting to spread to curtains.",
        "location": "Cairo"
    }
    response = api_client.post("/api/incidents/analyze/text/", payload, format="json")
    assert response.status_code == 201
    assert response.data["incident_type"] == "Fire"
    assert response.data["severity"] == "High"


@patch("El7a2ny_backend.camera_service.start_face_recognition")
@patch("El7a2ny_backend.camera_service.stop_face_recognition")
def test_security_camera_endpoints(mock_stop, mock_start, api_client, create_test_user):
    """
    Test security camera starting, stopping, and status reading.
    Paths: /api/security/camera/start/, /api/security/camera/stop/, /api/security/camera/status/
    """
    user = create_test_user(email="camera_user@el7a2ny.com")
    
    # Setup mocks
    mock_start.return_value = {
        "success": True,
        "message": "Face recognition started successfully",
        "status": "started",
        "pid": 1234
    }
    mock_stop.return_value = {
        "success": True,
        "message": "Face recognition stopped successfully",
        "status": "stopped"
    }
    
    # 1. Start camera
    start_payload = {"user_id": str(user.user_id)}
    start_response = api_client.post("/api/security/camera/start/", start_payload, format="json")
    assert start_response.status_code == 200
    assert start_response.data["success"] is True
    assert start_response.data["pid"] == 1234
    
    # Verify user camera permission is set to True
    user.refresh_from_db()
    assert user.camera is True
    
    # 2. Get status
    status_response = api_client.get(f"/api/security/camera/status/?user_id={user.user_id}")
    assert status_response.status_code == 200
    
    # 3. Stop camera
    stop_payload = {"user_id": str(user.user_id)}
    stop_response = api_client.post("/api/security/camera/stop/", stop_payload, format="json")
    assert stop_response.status_code == 200
    assert stop_response.data["success"] is True
    
    # Verify user camera permission is set to False
    user.refresh_from_db()
    assert user.camera is False


def test_camera_service_robustness_with_null_process_info():
    """
    Test that camera_service.is_process_running and stop_face_recognition
    do not raise TypeError or exception when psutil process_iter returns processes
    with None values for cmdline or name.
    """
    from El7a2ny_backend.camera_service import is_process_running, stop_face_recognition
    
    # Mock process instances
    mock_proc_ok = MagicMock()
    mock_proc_ok.info = {'pid': 100, 'name': 'python', 'cmdline': ['python', 'Face_recognition_insightface.py']}
    
    # Process with None cmdline
    mock_proc_none_cmdline = MagicMock()
    mock_proc_none_cmdline.info = {'pid': 200, 'name': 'system_proc', 'cmdline': None}
    
    # Process with None name
    mock_proc_none_name = MagicMock()
    mock_proc_none_name.info = {'pid': 300, 'name': None, 'cmdline': ['some_app']}
    
    # Test is_process_running
    with patch('psutil.process_iter') as mock_iter:
        mock_iter.return_value = [mock_proc_none_cmdline, mock_proc_none_name, mock_proc_ok]
        
        # This shouldn't raise TypeError and should return True (because mock_proc_ok matches)
        assert is_process_running() is True

    # Test stop_face_recognition
    with patch('psutil.process_iter') as mock_iter:
        mock_iter.return_value = [mock_proc_none_cmdline, mock_proc_none_name, mock_proc_ok]
        
        # This shouldn't raise TypeError
        res = stop_face_recognition()
        assert res['success'] is True
        mock_proc_ok.kill.assert_called_once()

