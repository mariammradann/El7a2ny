from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from rest_framework.routers import DefaultRouter

from .views import (
    UserViewSet, IncidentViewSet, HelpInitiativeViewSet, 
    register_user_api, get_device_status, get_first_aid_advice,
    verify_password_api, change_password_api,
    password_reset_request, password_reset_verify_token, password_reset_confirm,
    get_user_activity_history, admin_stats, admin_users, admin_update_user,
    admin_delete_user, admin_incidents
)

# 1. إعداد الـ Router
router = DefaultRouter()
router.register(r'users', UserViewSet, basename='user')

# تسجيل مسار البلاغات (Incidents) لربطه بجدول الـ ems_schema.incidents
router.register(r'incidents', IncidentViewSet, basename='incident')
router.register(r'initiatives', HelpInitiativeViewSet, basename='initiative')

# 2. المصفوفة النهائية للمسارات
urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/register/', register_user_api, name='api_register'),
    
    # Password Reset Endpoints
    path('api/auth/password/reset/request/', password_reset_request, name='password_reset_request'),
    path('api/auth/password/reset/verify/', password_reset_verify_token, name='password_reset_verify'),
    path('api/auth/password/reset/confirm/', password_reset_confirm, name='password_reset_confirm'),
    
    # الحل الأضمن: هننادي على الـ ViewSet مباشرة بدون Router للمسار ده
    path('api/profile/<uuid:user_id>/', UserViewSet.as_view({'get': 'profile_by_id'}), name='user-profile-detail'),
    path('api/profile/update/', UserViewSet.as_view({'put': 'update_profile'}), name='update-profile'),
    path('api/profile/history/', get_user_activity_history, name='activity-history'),

    # مسارات الـ Router خليها في الآخر خالص
    path('api/emergency/reports/', IncidentViewSet.as_view({'post': 'create'}), name='emergency-reports-alias'),
    
    # Admin Endpoints
    path('api/admin/stats/', admin_stats, name='admin-stats'),
    path('api/admin/users/', admin_users, name='admin-users'),
    path('api/admin/users/<uuid:user_id>/', admin_update_user, name='admin-update-user'),
    path('api/admin/users/<uuid:user_id>/delete/', admin_delete_user, name='admin-delete-user'),
    path('api/admin/incidents/', admin_incidents, name='admin-incidents'),
    
    path('api/', include(router.urls)),

    path('api/devices/status/', get_device_status),
    path('api/chat/', get_first_aid_advice),
    
    # مسارات تعديل كلمة المرور
    path('api/auth/password/verify/', verify_password_api),
    path('api/auth/password/change/', change_password_api),
]

# خدمة ملفات الـ Media في بيئة التطوير
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
