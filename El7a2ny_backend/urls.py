from django import views
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from rest_framework.routers import DefaultRouter
from .views import (
    UserViewSet,
    IncidentViewSet,
    HelpInitiativeViewSet,
    get_incident_responders,
    get_latest_sensor_reading,
    receive_temperature,
    register_user_api,
    get_device_status,
    respond_to_alert,
    update_responder_location,
    verify_password_api,
    change_password_api,
    password_reset_request,
    password_reset_verify_token,
    password_reset_confirm,
    get_user_activity_history,
    admin_stats,
    admin_users,
    admin_update_user,
    admin_delete_user,
    admin_incidents,
    admin_update_incident,
    get_user_subscription,
    subscribe_user,
    submit_user_rating,
    submit_volunteer_rating,
    incident_chat_messages,
    incident_chat_poll,
    AnalyzeIncidentImageView,
    AnalyzeIncidentVideoView,
    AnalyzeIncidentVoiceView,
    AnalyzeIncidentTextView,
    IncidentAIAnalysisDetailView,
    get_sponsors,
    apply_sponsor,
    admin_sponsor_requests,
    admin_respond_sponsor_request,
    api_assistant_chat,
    report_fake_incident,
    admin_logs,
)

# 1. إعداد الـ Router
router = DefaultRouter()
router.register(r"users", UserViewSet, basename="user")

# تسجيل مسار البلاغات (Incidents) لربطه بجدول الـ ems_schema.incidents
router.register(r"incidents", IncidentViewSet, basename="incident")
router.register(r"initiatives", HelpInitiativeViewSet, basename="initiative")

# 2. المصفوفة النهائية للمسارات
urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/register/", register_user_api, name="api_register"),
    # Password Reset Endpoints
    path(
        "api/auth/password/reset/request/",
        password_reset_request,
        name="password_reset_request",
    ),
    path(
        "api/auth/password/reset/verify/",
        password_reset_verify_token,
        name="password_reset_verify",
    ),
    path(
        "api/auth/password/reset/confirm/",
        password_reset_confirm,
        name="password_reset_confirm",
    ),
    # الحل الأضمن: هننادي على الـ ViewSet مباشرة بدون Router للمسار ده
    path(
        "api/profile/<uuid:user_id>/",
        UserViewSet.as_view({"get": "profile_by_id"}),
        name="user-profile-detail",
    ),
    path(
        "api/profile/update/",
        UserViewSet.as_view({"put": "update_profile"}),
        name="update-profile",
    ),
    path("api/profile/history/", get_user_activity_history, name="activity-history"),
    path(
        "api/emergency/reports/",
        IncidentViewSet.as_view({"post": "create"}),
        name="emergency-reports-alias",
    ),
    # Admin Endpoints
    path("api/admin/stats/", admin_stats, name="admin-stats"),
    path("api/admin/users/", admin_users, name="admin-users"),
    path(
        "api/admin/users/<uuid:user_id>/", admin_update_user, name="admin-update-user"
    ),
    path(
        "api/admin/users/<uuid:user_id>/delete/",
        admin_delete_user,
        name="admin-delete-user",
    ),
    path("api/admin/incidents/", admin_incidents, name="admin-incidents"),
    path(
        "api/admin/incidents/<str:incident_id>/",
        admin_update_incident,
        name="admin-update-incident",
    ),
    # Subscription Endpoints
    path(
        "api/subscription/<uuid:user_id>/",
        get_user_subscription,
        name="get-subscription",
    ),
    path("api/subscription/subscribe/", subscribe_user, name="subscribe-user"),
    path("api/sponsors/", get_sponsors, name="get-sponsors"),
    path("api/sponsors/apply/", apply_sponsor, name="apply-sponsor"),
    path("api/admin/sponsors/requests/", admin_sponsor_requests, name="admin-sponsor-requests"),
    path("api/admin/sponsors/requests/<uuid:request_id>/respond/", admin_respond_sponsor_request, name="admin-respond-sponsor-request"),
    path("api/", include(router.urls)),
    path("api/devices/status/", get_device_status),
    # مسارات تعديل كلمة المرور
    path("api/auth/password/verify/", verify_password_api),
    path("api/auth/password/change/", change_password_api),
    path("api/sensor/temperature/", receive_temperature, name="receive_temperature"),
    path("api/sensor/latest/", get_latest_sensor_reading, name="latest_sensor"),
    path("api/ratings/user/", submit_user_rating, name="submit_user_rating"),
    path(
        "api/ratings/volunteer/",
        submit_volunteer_rating,
        name="submit_volunteer_rating",
    ),
    path(
        "alerts/<uuid:incident_id>/respond/", respond_to_alert, name="respond-to-alert"
    ),
    path(
        "alerts/<uuid:incident_id>/responders/",
        get_incident_responders,
        name="incident-responders",
    ),
    path(
        "alerts/<uuid:incident_id>/responders/location/",
        update_responder_location,
        name="update-responder-location",
    ),
    path(
        "alerts/<uuid:incident_id>/chat/",
        incident_chat_messages,
        name="incident-chat-messages",
    ),
    path(
        "alerts/<uuid:incident_id>/chat/poll/",
        incident_chat_poll,
        name="incident-chat-poll",
    ),
    
    # ── AI Analysis endpoints ─────────────────────────────────────────────────
    path("api/incidents/analyze/image/", AnalyzeIncidentImageView.as_view(), name="analyze-image"),
    path("api/incidents/analyze/video/", AnalyzeIncidentVideoView.as_view(), name="analyze-video"),
    path("api/incidents/analyze/voice/", AnalyzeIncidentVoiceView.as_view(), name="analyze-voice"),
    path("api/incidents/analyze/text/",  AnalyzeIncidentTextView.as_view(),  name="analyze-text"),
    path("api/incidents/<uuid:incident_id>/analysis/", IncidentAIAnalysisDetailView.as_view(), name="incident-analysis"),
    path("api/assistant/chat/", api_assistant_chat, name="assistant-chat"),
    path("api/incidents/<uuid:incident_id>/report-fake/", report_fake_incident, name="report-fake-incident"),
    path("api/admin/logs/", admin_logs, name="admin-logs"),
]

# خدمة ملفات الـ Media في بيئة التطوير
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
