import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import '../services/session_service.dart';
import '../services/api_service.dart';
import '../core/auth/auth_token_store.dart';
import '../core/localization/app_strings.dart';

const _kGold = Color(0xFFF59E0B);
const _kGoldDark = Color(0xFFE95F32);
const _kNavy = Color(0xFF1E293B);
const _kBg = Color(0xFFFFFBF0);

class SubscriptionDetailsPage extends StatefulWidget {
  const SubscriptionDetailsPage({super.key});

  @override
  State<SubscriptionDetailsPage> createState() => _SubscriptionDetailsPageState();
}

class _SubscriptionDetailsPageState extends State<SubscriptionDetailsPage> {
  bool _cancelling = false;

  void _showManageSheet(BuildContext context, bool isAr) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Directionality(
        textDirection: isAr ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isAr ? 'إدارة الاشتراك' : 'Manage Subscription',
                style: const TextStyle(
                  color: _kNavy,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'NotoSansArabic',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isAr ? 'اختار إيه اللي تعمله' : 'Choose what you want to do',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontFamily: 'NotoSansArabic'),
              ),
              const SizedBox(height: 28),
              _ManageOptionTile(
                icon: Icons.cancel_outlined,
                iconColor: const Color(0xFFEF4444),
                title: isAr ? 'إلغاء الاشتراك' : 'Cancel Subscription',
                subtitle: isAr ? 'هيتلغي بعد انتهاء الفترة الحالية' : 'Will end after current period',
                onTap: () {
                  Navigator.pop(context);
                  _confirmCancel(context, isAr);
                },
              ),
              const SizedBox(height: 12),
              _ManageOptionTile(
                icon: Icons.support_agent_rounded,
                iconColor: _kGold,
                title: isAr ? 'تواصل مع الدعم' : 'Contact Support',
                subtitle: isAr ? 'لو عندك أي سؤال عن اشتراكك' : 'For any questions about your plan',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isAr ? 'جاري تحويلك للدعم...' : 'Connecting to support...',
                        style: const TextStyle(fontFamily: 'NotoSansArabic'),
                      ),
                      backgroundColor: _kNavy,
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kGold,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    isAr ? 'الاحتفاظ بالاشتراك' : 'Keep Subscription',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, fontFamily: 'NotoSansArabic'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmCancel(BuildContext context, bool isAr) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isAr ? 'إلغاء الاشتراك؟' : 'Cancel Subscription?',
          style: const TextStyle(color: _kNavy, fontWeight: FontWeight.w900, fontFamily: 'NotoSansArabic'),
        ),
        content: Text(
          isAr
              ? 'هتفقد كل مميزات إلحقني بلس في آخر يوم من اشتراكك الحالي. مش هيترجع فيه.'
              : 'You will lose all El7a2ny Plus benefits at the end of your current billing period. This cannot be undone.',
          style: const TextStyle(color: Color(0xFF475569), height: 1.5, fontFamily: 'NotoSansArabic'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              isAr ? 'مش عايز أتراجع' : 'Keep it',
              style: const TextStyle(color: _kGold, fontFamily: 'NotoSansArabic', fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _doCancelSubscription(context, isAr);
            },
            child: Text(
              isAr ? 'إلغاء' : 'Cancel Plan',
              style: const TextStyle(color: Color(0xFFEF4444), fontFamily: 'NotoSansArabic'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _doCancelSubscription(BuildContext context, bool isAr) async {
    final userId = AuthTokenStore.userId;
    if (userId == null) return;

    setState(() => _cancelling = true);
    try {
      await ApiService.cancelSubscription(userId);
      SessionService().setPlus(false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr ? 'تم إلغاء الاشتراك بنجاح' : 'Subscription cancelled successfully',
              style: const TextStyle(fontFamily: 'NotoSansArabic'),
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr ? 'حصل خطأ، حاول تاني' : 'Something went wrong, please try again',
              style: const TextStyle(fontFamily: 'NotoSansArabic'),
            ),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.loc.isAr;
    final session = SessionService();
    final isYearly = session.isYearlyPlan;
    final subDate = session.subscriptionDate ?? DateTime.now();
    final renDate = session.renewalDate ?? DateTime.now();

    final dateFormat = isAr
        ? DateFormat('yyyy/MM/dd')
        : DateFormat('dd MMM yyyy');

    return Directionality(
      textDirection: isAr ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _kNavy),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            isAr ? 'تفاصيل الاشتراك' : 'Subscription Details',
            style: const TextStyle(
              color: _kNavy,
              fontWeight: FontWeight.w900,
              fontFamily: 'NotoSansArabic',
              fontSize: 18,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: const Color(0xFFF1F5F9)),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Premium Header Card ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kGold, _kGoldDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: _kGold.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'إلحقني بلس',
                      style: TextStyle(
                        fontFamily: 'NotoSansArabic',
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        isAr ? 'عضوية نشطة ✓' : 'ACTIVE MEMBERSHIP ✓',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Plan Information ─────────────────────────────────────────
              _buildSectionTitle(isAr ? 'معلومات الخطة' : 'Plan Information'),
              _buildInfoCard([
                _buildInfoRow(
                  isAr ? 'نوع الخطة' : 'Plan Type',
                  isYearly ? (isAr ? 'سنوي' : 'Yearly') : (isAr ? 'شهري' : 'Monthly'),
                  Icons.calendar_today_rounded,
                ),
                _buildInfoRow(
                  isAr ? 'تاريخ الاشتراك' : 'Subscription Date',
                  dateFormat.format(subDate),
                  Icons.event_available_rounded,
                ),
                _buildInfoRow(
                  isAr ? 'تاريخ التجديد' : 'Renewal Date',
                  dateFormat.format(renDate),
                  Icons.event_repeat_rounded,
                  isLast: true,
                ),
              ]),

              const SizedBox(height: 24),

              // ── Active Features ──────────────────────────────────────────
              _buildSectionTitle(isAr ? 'مميزاتك النشطة' : 'Active Features'),
              _buildFeatureItem(
                isAr ? 'أولوية قصوى في الاستجابة' : 'Top Priority Response',
                Icons.speed_rounded,
              ),
              _buildFeatureItem(
                isAr ? 'استشارات طبية غير محدودة' : 'Unlimited Medical Consults',
                Icons.medical_services_rounded,
              ),
              _buildFeatureItem(
                isAr ? 'تغطية عائلية شاملة' : 'Full Family Coverage',
                Icons.family_restroom_rounded,
              ),
              _buildFeatureItem(
                isAr ? 'خصومات حصرية على التحاليل' : 'Exclusive Lab Discounts',
                Icons.percent_rounded,
              ),

              const SizedBox(height: 32),

              // ── Manage Button ────────────────────────────────────────────
              SizedBox(
                height: 56,
                child: _cancelling
                    ? const Center(child: CircularProgressIndicator(color: _kGold))
                    : OutlinedButton(
                        onPressed: () => _showManageSheet(context, isAr),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          foregroundColor: _kNavy,
                        ),
                        child: Text(
                          isAr ? 'إدارة الاشتراك' : 'Manage Subscription',
                          style: const TextStyle(
                            color: _kNavy,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'NotoSansArabic',
                          ),
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
      padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _kGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _kGold, size: 18),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontFamily: 'NotoSansArabic',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: _kNavy,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'NotoSansArabic',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _kGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _kGold, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: _kNavy,
                fontWeight: FontWeight.w600,
                fontFamily: 'NotoSansArabic',
                fontSize: 14,
              ),
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
        ],
      ),
    );
  }
}

class _ManageOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ManageOptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _kNavy,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFamily: 'NotoSansArabic',
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      fontFamily: 'NotoSansArabic',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFCBD5E1), size: 14),
          ],
        ),
      ),
    );
  }
}
