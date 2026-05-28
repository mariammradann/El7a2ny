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
    cancel_subscription,
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
    admin_sponsors_list,
    admin_sponsors_create,
    admin_sponsors_detail,
    admin_sponsors_approve_request,
    admin_sponsors_reject_request,
    admin_sponsors_change_status,
    admin_sponsors_change_level,
    admin_sponsors_bulk_action,
    api_assistant_chat,
    report_fake_incident,
    admin_logs,
    courses_list,
    enroll_course,
    complete_course,
    get_user_badges,
    admin_hard_delete_incident,
    admin_initiatives,
    admin_delete_initiative,
    admin_courses,
    admin_delete_course,
    admin_create_course,
    admin_edit_course,
    admin_subscriptions,
    admin_cancel_subscription,
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
    path("api/subscription/cancel/", cancel_subscription, name="cancel-subscription"),
    path("api/sponsors/", get_sponsors, name="get-sponsors"),
    path("api/sponsors/apply/", apply_sponsor, name="apply-sponsor"),
    path("api/admin/sponsors/requests/", admin_sponsor_requests, name="admin-sponsor-requests"),
    path("api/admin/sponsors/requests/<uuid:request_id>/respond/", admin_respond_sponsor_request, name="admin-respond-sponsor-request"),
    # Admin Sponsor Management Endpoints
    path("api/admin/sponsors/", admin_sponsors_list, name="admin-sponsors-list"),
    path("api/admin/sponsors/create/", admin_sponsors_create, name="admin-sponsors-create"),
    path("api/admin/sponsors/<uuid:sponsor_id>/", admin_sponsors_detail, name="admin-sponsors-detail"),
    path("api/admin/sponsors/<uuid:request_id>/approve/", admin_sponsors_approve_request, name="admin-sponsors-approve-request"),
    path("api/admin/sponsors/<uuid:request_id>/reject/", admin_sponsors_reject_request, name="admin-sponsors-reject-request"),
    path("api/admin/sponsors/<uuid:sponsor_id>/status/", admin_sponsors_change_status, name="admin-sponsors-change-status"),
    path("api/admin/sponsors/<uuid:sponsor_id>/level/", admin_sponsors_change_level, name="admin-sponsors-change-level"),
    path("api/admin/sponsors/bulk-action/", admin_sponsors_bulk_action, name="admin-sponsors-bulk-action"),
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

    # ── Admin Extended Management ──────────────────────────────────────────────
    path("api/admin/incidents/<str:incident_id>/hard-delete/", admin_hard_delete_incident, name="admin-hard-delete-incident"),
    path("api/admin/initiatives/", admin_initiatives, name="admin-initiatives"),
    path("api/admin/initiatives/<int:initiative_id>/", admin_delete_initiative, name="admin-delete-initiative"),
    path("api/admin/courses/", admin_courses, name="admin-courses"),
    path("api/admin/courses/create/", admin_create_course, name="admin-create-course"),
    path("api/admin/courses/<uuid:course_id>/", admin_delete_course, name="admin-delete-course"),
    path("api/admin/courses/<uuid:course_id>/edit/", admin_edit_course, name="admin-edit-course"),
    path("api/admin/subscriptions/", admin_subscriptions, name="admin-subscriptions"),
    path("api/admin/subscriptions/<uuid:user_id>/cancel/", admin_cancel_subscription, name="admin-cancel-subscription"),

    # Volunteer Training Academy
    path("api/training/courses/", courses_list, name="courses-list"),
    path("api/training/courses/<uuid:course_id>/enroll/", enroll_course, name="enroll-course"),
    path("api/training/courses/<uuid:course_id>/complete/", complete_course, name="complete-course"),
    path("api/training/badges/<uuid:user_id>/", get_user_badges, name="user-badges"),
]

# خدمة ملفات الـ Media في بيئة التطوير
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
