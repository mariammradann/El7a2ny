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
    # لوحة تحكم دجانجو
    path('admin/', admin.site.urls),
    
    # مسار التسجيل (Register) - يفضل وضعه قبل الـ router urls
    path('api/register/', register_user_api, name='api_register'),
    
    # مسارات الـ API (تشمل الآن الـ Users والـ Incidents)
    path('api/', include(router.urls)),
]