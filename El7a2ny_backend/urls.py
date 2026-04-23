from django.contrib import admin
from django.urls import path, include
from rest_framework.routers import DefaultRouter
# ضيف IncidentViewSet هنا
from .views import UserViewSet, IncidentViewSet, register_user_api 

# 1. إعداد الـ Router
router = DefaultRouter()
router.register(r'users', UserViewSet, basename='user')

# تسجيل مسار البلاغات (Incidents) لربطه بجدول الـ ems_schema.incidents
router.register(r'incidents', IncidentViewSet, basename='incident')

# 2. المصفوفة النهائية للمسارات
urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/register/', register_user_api, name='api_register'),
    
    # الحل الأضمن: هننادي على الـ ViewSet مباشرة بدون Router للمسار ده
    path('api/profile/<uuid:user_id>/', UserViewSet.as_view({'get': 'profile_by_id'}), name='user-profile-detail'),

    # مسارات الـ Router خليها في الآخر خالص
    path('api/', include(router.urls)),
]