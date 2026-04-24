import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import '../services/session_service.dart';
import '../core/localization/app_strings.dart';

class SubscriptionDetailsPage extends StatelessWidget {
  const SubscriptionDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = context.loc.isAr;
    final session = SessionService();
    final isYearly = session.isYearlyPlan;
    final subDate = session.subscriptionDate ?? DateTime.now();
    final renDate = session.renewalDate ?? DateTime.now();
    
    final dateFormat = isAr ? DateFormat('yyyy/MM/dd') : DateFormat('dd MMM yyyy');

    return Directionality(
      textDirection: isAr ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFFFD700)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            isAr ? 'تفاصيل الاشتراك' : 'Subscription Details',
            style: const TextStyle(
              color: Color(0xFFFFD700),
              fontWeight: FontWeight.w900,
              fontFamily: 'NotoSansArabic',
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Premium Header Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD700), size: 48),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'إلحقني بلس',
                      style: TextStyle(
                        fontFamily: 'NotoSansArabic',
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFFD700),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isAr ? 'عضوية نشطة' : 'ACTIVE MEMBERSHIP',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),

              // Plan Info Section
              _buildSectionTitle(isAr ? 'معلومات الخطة' : 'Plan Information'),
              _buildInfoCard([
                _buildInfoRow(
                  isAr ? 'نوع الخطة' : 'Plan Type', 
                  isYearly ? (isAr ? 'سنوي' : 'Yearly') : (isAr ? 'شهري' : 'Monthly'),
                  Icons.calendar_today_rounded
                ),
                _buildInfoRow(
                  isAr ? 'تاريخ الاشتراك' : 'Subscription Date', 
                  dateFormat.format(subDate),
                  Icons.event_available_rounded
                ),
                _buildInfoRow(
                  isAr ? 'تاريخ التجديد' : 'Renewal Date', 
                  dateFormat.format(renDate),
                  Icons.event_repeat_rounded,
                  isLast: true
                ),
              ]),

              const SizedBox(height: 24),

              // Features Section
              _buildSectionTitle(isAr ? 'مميزاتك النشطة' : 'Active Features'),
              _buildFeatureItem(isAr ? 'أولوية قصوى في الاستجابة' : 'Top Priority Response', Icons.speed_rounded),
              _buildFeatureItem(isAr ? 'استشارات طبية غير محدودة' : 'Unlimited Medical Consults', Icons.medical_services_rounded),
              _buildFeatureItem(isAr ? 'تغطية عائلية شاملة' : 'Full Family Coverage', Icons.family_restroom_rounded),
              _buildFeatureItem(isAr ? 'خصومات حصرية على التحاليل' : 'Exclusive Lab Discounts', Icons.percent_rounded),
              
              const SizedBox(height: 40),

              // Manage Button
              SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    isAr ? 'إدارة الاشتراك' : 'Manage Subscription',
                    style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFFD700).withValues(alpha: 0.6), size: 20),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFFD700), size: 20),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          const Spacer(),
          const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
        ],
      ),
    );
  }
}
