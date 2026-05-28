from django.contrib import admin
from django.utils.html import format_html
from .models import SponsorRequest, Sponsor


# ═══════════════════════════════════════════════════════════════════════════════
# ═══════════════════ SPONSOR ADMIN ═══════════════════════════════════════════════════════
# ═══════════════════════════════════════════════════════════════════════════════


@admin.register(Sponsor)
class SponsorAdmin(admin.ModelAdmin):
    """Admin interface for managing Sponsors"""
    
    list_display = (
        'name',
        'company_type_display',
        'status_badge',
        'sponsorship_level',
        'phone',
        'contract_date',
        'created_at',
    )
    list_filter = ('status', 'company_type', 'sponsorship_level', 'created_at')
    search_fields = ('name', 'phone', 'contact_email', 'website')
    readonly_fields = ('sponsor_id', 'created_at', 'updated_at')
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('sponsor_id', 'name', 'company_type', 'website', 'phone', 'contact_email')
        }),
        ('Status & Level', {
            'fields': ('status', 'sponsorship_level')
        }),
        ('Contract Details', {
            'fields': ('contract_date', 'admin_id')
        }),
        ('Relations', {
            'fields': ('incident_id', 'training_id'),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def company_type_display(self, obj):
        """Display company type as readable string"""
        type_dict = {
            'cars': '🚗 Cars & Roadside',
            'insurance': '🛡️ Insurance',
            'medical': '🏥 Medical',
        }
        return type_dict.get(obj.company_type, obj.company_type)
    company_type_display.short_description = 'Type'
    
    def status_badge(self, obj):
        """Display status as a colored badge"""
        colors = {
            'active': '#28a745',
            'inactive': '#6c757d',
            'pending': '#ffc107',
        }
        color = colors.get(obj.status, '#6c757d')
        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 10px; border-radius: 3px; font-weight: bold;">{}</span>',
            color,
            obj.status.upper()
        )
    status_badge.short_description = 'Status'
    
    def get_readonly_fields(self, request, obj=None):
        """Make sponsor_id read-only when editing"""
        if obj:  # Editing an existing object
            return self.readonly_fields + ['name']
        return self.readonly_fields


@admin.register(SponsorRequest)
class SponsorRequestAdmin(admin.ModelAdmin):
    """Admin interface for managing Sponsor Requests"""
    
    list_display = (
        'company_name',
        'contact_person',
        'phone_number',
        'status_badge',
        'user_display',
        'created_at',
    )
    list_filter = ('status', 'created_at')
    search_fields = ('company_name', 'contact_person', 'phone_number', 'message')
    readonly_fields = ('request_id', 'created_at', 'updated_at', 'message_display')
    
    fieldsets = (
        ('Company Information', {
            'fields': ('request_id', 'company_name', 'contact_person', 'phone_number')
        }),
        ('Message', {
            'fields': ('message_display',)
        }),
        ('Status & User', {
            'fields': ('status', 'user')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def user_display(self, obj):
        """Display user information"""
        if obj.user:
            return f"{obj.user.name} ({obj.user.email})"
        return "—"
    user_display.short_description = 'User'
    
    def status_badge(self, obj):
        """Display status as a colored badge"""
        colors = {
            'pending': '#ffc107',
            'approved': '#28a745',
            'rejected': '#dc3545',
        }
        color = colors.get(obj.status, '#6c757d')
        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 10px; border-radius: 3px; font-weight: bold;">{}</span>',
            color,
            obj.status.upper()
        )
    status_badge.short_description = 'Status'
    
    def message_display(self, obj):
        """Display the message in a more readable format"""
        return obj.message
    message_display.short_description = 'Message'
    message_display.allow_tags = True
    
    actions = ['approve_requests', 'reject_requests']
    
    def approve_requests(self, request, queryset):
        """Bulk approve sponsor requests"""
        updated = 0
        for sponsor_request in queryset.filter(status='pending'):
            sponsor_request.status = 'approved'
            sponsor_request.save()
            updated += 1
        
        self.message_user(
            request,
            f'{updated} sponsor request(s) have been approved.'
        )
    approve_requests.short_description = 'Approve selected sponsor requests'
    
    def reject_requests(self, request, queryset):
        """Bulk reject sponsor requests"""
        updated = queryset.filter(status='pending').update(status='rejected')
        self.message_user(
            request,
            f'{updated} sponsor request(s) have been rejected.'
        )
    reject_requests.short_description = 'Reject selected sponsor requests'


# Configure Django Admin site
admin.site.site_header = "El7a2ny Emergency Management System Admin"
admin.site.site_title = "El7a2ny Admin Portal"
admin.site.index_title = "Welcome to El7a2ny Administration"

