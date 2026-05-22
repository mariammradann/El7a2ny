import 'package:flutter/material.dart';
import 'payment_page.dart';
import '../core/localization/app_strings.dart';
import '../services/session_service.dart';
import 'edit_plan_page.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PremiumSubscriptionPage extends StatefulWidget {
  const PremiumSubscriptionPage({super.key});

  @override
  State<PremiumSubscriptionPage> createState() =>
      _PremiumSubscriptionPageState();
}

class _PremiumSubscriptionPageState extends State<PremiumSubscriptionPage> {
  // 0: Free, 1: Monthly, 2: Yearly
  int _selectedPlanIndex = 1;
  bool _isLoading = true;
  String? _currentPlan; // 'monthly' | 'yearly' | null
  bool _isSubscribed = false;

  @override
  void initState() {
    super.initState();
    _loadUserSubscription();
  }

  Future<void> _loadUserSubscription() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId != null) {
        final subscription = await ApiService.getUserSubscription(userId);
        setState(() {
          _isSubscribed = subscription['is_plus'] ?? false;
          _currentPlan = subscription['plan_type']; // 'monthly' or 'yearly'

          if (!_isSubscribed) {
            _selectedPlanIndex = 1; // default to monthly for upsell
          } else if (_currentPlan == 'yearly') {
            _selectedPlanIndex = 2;
          } else {
            // monthly subscriber → show their current plan tab
            _selectedPlanIndex = 1;
          }
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading subscription: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Whether the currently-viewed tab matches what the user already owns.
  bool get _isViewingCurrentPlan {
    if (!_isSubscribed) return false;
    if (_currentPlan == 'yearly' && _selectedPlanIndex == 2) return true;
    if (_currentPlan == 'monthly' && _selectedPlanIndex == 1) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAr = context.loc.isAr;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _PremiumHeader(
                    selectedPlanIndex: _selectedPlanIndex,
                    onPlanSelected: (val) =>
                        setState(() => _selectedPlanIndex = val),
                    currentPlan: _currentPlan,
                    isSubscribed: _isSubscribed,
                  ),
                  Expanded(
                    child: Container(
                      color: theme.scaffoldBackgroundColor,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: _selectedPlanIndex == 0
                              ? [
                                  _SectionHeader(
                                    title: context.loc.freePlanSubtitle,
                                    icon: Icons.star_border_rounded,
                                  ),
                                  const SizedBox(height: 20),
                                  _FeatureItemCard(
                                    icon: Icons.timer_rounded,
                                    title: context.loc.standardResponse,
                                    subtitle: context.loc.standardResponseDesc,
                                  ),
                                  const SizedBox(height: 14),
                                  _FeatureItemCard(
                                    icon: Icons.people_alt_rounded,
                                    title: context.loc.communityHelp,
                                    subtitle: context.loc.communityHelpDesc,
                                  ),
                                  const SizedBox(height: 14),
                                  _FeatureItemCard(
                                    icon: Icons.medical_information_rounded,
                                    title: context.loc.standardMedicalAdvice,
                                    subtitle:
                                        context.loc.standardMedicalAdviceDesc,
                                  ),
                                  const SizedBox(height: 14),
                                  _FeatureItemCard(
                                    icon: Icons.sos_rounded,
                                    title: context.loc.normalSOSAlerts,
                                    subtitle: context.loc.normalSOSAlertsDesc,
                                  ),
                                  const SizedBox(height: 40),
                                ]
                              : [
                                  // ── "Currently active" banner ──────────
                                  if (_isViewingCurrentPlan) ...[
                                    _ActivePlanBanner(
                                        isYearly:
                                            _currentPlan == 'yearly',
                                        isAr: isAr),
                                    const SizedBox(height: 20),
                                  ],

                                  // ── Upgrade nudge for monthly→yearly ──
                                  if (_isSubscribed &&
                                      _currentPlan == 'monthly' &&
                                      _selectedPlanIndex == 2) ...[
                                    _UpgradeNudgeBanner(isAr: isAr),
                                    const SizedBox(height: 20),
                                  ],

                                  _SectionHeader(
                                    title: context.loc.exclusiveFeaturesTitle,
                                    icon: Icons.auto_awesome_rounded,
                                  ),
                                  const SizedBox(height: 20),
                                  _FeatureItemCard(
                                    icon: Icons.bolt_rounded,
                                    title: context.loc.instantResponse,
                                    subtitle: context.loc.instantResponseDesc,
                                  ),
                                  const SizedBox(height: 14),
                                  _FeatureItemCard(
                                    icon: Icons.shield_rounded,
                                    title: context.loc.premiumInsurance,
                                    subtitle: context.loc.premiumInsuranceDesc,
                                  ),
                                  const SizedBox(height: 14),
                                  _FeatureItemCard(
                                    icon: Icons.support_agent_rounded,
                                    title: context.loc.support24_7Title,
                                    subtitle: context.loc.support24_7Desc,
                                  ),
                                  const SizedBox(height: 14),
                                  _FeatureItemCard(
                                    icon: Icons.family_restroom_rounded,
                                    title: context.loc.familyProtection,
                                    subtitle: context.loc.familyProtectionDesc,
                                  ),
                                  const SizedBox(height: 14),
                                  _FeatureItemCard(
                                    icon: Icons.location_searching_rounded,
                                    title: context.loc.liveTrackingTitle,
                                    subtitle: context.loc.liveTrackingDesc,
                                  ),
                                  const SizedBox(height: 14),
                                  _FeatureItemCard(
                                    icon: Icons.health_and_safety_rounded,
                                    title: context.loc.healthRecordsTitle,
                                    subtitle: context.loc.healthRecordsDesc,
                                  ),
                                  const SizedBox(height: 32),
                                  _SectionHeader(
                                    title: context.loc.serviceCategoriesTitle,
                                    icon: Icons.category_rounded,
                                  ),
                                  const SizedBox(height: 20),
                                  _ServiceCategoryCard(
                                    icon: Icons.medical_services_rounded,
                                    iconBackground: const Color(0xFFE61717)
                                        .withValues(alpha: 0.12),
                                    iconColor: const Color(0xFFE61717),
                                    title: context.loc.medicalServicesTitle,
                                    features: isAr
                                        ? [
                                            'دخول المستشفى بأولوية',
                                            'استشارات مع أخصائيين',
                                            'زيارات رعاية صحية منزلية',
                                            'توصيل الأدوية',
                                          ]
                                        : [
                                            'Priority hospital admission',
                                            'Consultation with specialists',
                                            'Home healthcare visits',
                                            'Medicine delivery',
                                          ],
                                  ),
                                  const SizedBox(height: 14),
                                  _ServiceCategoryCard(
                                    icon: Icons.local_airport_rounded,
                                    iconBackground: const Color(0xFF2563EB)
                                        .withValues(alpha: 0.12),
                                    iconColor: const Color(0xFF2563EB),
                                    title: context.loc.transportServicesTitle,
                                    features: isAr
                                        ? [
                                            'خدمة الإسعاف الجوي',
                                            'إسعاف أرضي مميز',
                                          ]
                                        : [
                                            'Air ambulance service',
                                            'Premium ground ambulance',
                                          ],
                                  ),
                                  const SizedBox(height: 14),
                                  _ServiceCategoryCard(
                                    icon: Icons.gpp_good_rounded,
                                    iconBackground: const Color(0xFF15803D)
                                        .withValues(alpha: 0.12),
                                    iconColor: const Color(0xFF15803D),
                                    title: context.loc.insuranceCoverageTitle,
                                    features: isAr
                                        ? [
                                            'بدون حدود للمطالبات',
                                            'تغطية الأمراض المزمنة',
                                            'تشمل الأسنان والعيون',
                                            'دعم الصحة النفسية',
                                          ]
                                        : [
                                            'Unlimited claims',
                                            'Chronic disease coverage',
                                            'Dental and vision included',
                                            'Mental health support',
                                          ],
                                  ),
                                  const SizedBox(height: 14),
                                  _ServiceCategoryCard(
                                    icon: Icons.headset_mic_rounded,
                                    iconBackground: const Color(0xFF7C3AED)
                                        .withValues(alpha: 0.12),
                                    iconColor: const Color(0xFF7C3AED),
                                    title: context.loc.supportServicesTitle,
                                    features: isAr
                                        ? [
                                            'خط ساخن مخصص',
                                            'مستشار صحي شخصي',
                                            'مساعدة قانونية',
                                            'دعم طوارئ السفر',
                                          ]
                                        : [
                                            'Dedicated hotline',
                                            'Personal health advisor',
                                            'Legal assistance',
                                            'Travel emergency support',
                                          ],
                                  ),
                                  const SizedBox(height: 40),
                                ],
                        ),
                      ),
                    ),
                  ),
                  _StickyFooter(
                    selectedPlanIndex: _selectedPlanIndex,
                    currentPlan: _currentPlan,
                    isSubscribed: _isSubscribed,
                    isViewingCurrentPlan: _isViewingCurrentPlan,
                  ),
                ],
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// New banners
// ─────────────────────────────────────────────────────────────────────────────

class _ActivePlanBanner extends StatelessWidget {
  final bool isYearly;
  final bool isAr;
  const _ActivePlanBanner({required this.isYearly, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF15803D).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFF15803D).withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.verified_rounded,
              color: Color(0xFF4ADE80), size: 20),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              isAr
                  ? (isYearly
                      ? 'خطتك الحالية: سنوية ✓'
                      : 'خطتك الحالية: شهرية ✓')
                  : (isYearly
                      ? 'Your current plan: Yearly ✓'
                      : 'Your current plan: Monthly ✓'),
              style: const TextStyle(
                fontFamily: 'NotoSansArabic',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF4ADE80),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpgradeNudgeBanner extends StatelessWidget {
  final bool isAr;
  const _UpgradeNudgeBanner({required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDC800).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFFFDC800).withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.upgrade_rounded,
              color: Color(0xFFFDC800), size: 20),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              isAr
                  ? 'وفّر أكثر بالترقية إلى الخطة السنوية!'
                  : 'Save more by upgrading to the Yearly plan!',
              style: const TextStyle(
                fontFamily: 'NotoSansArabic',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFDC800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _PremiumHeader extends StatelessWidget {
  final int selectedPlanIndex;
  final ValueChanged<int> onPlanSelected;
  final String? currentPlan;
  final bool isSubscribed;

  const _PremiumHeader({
    required this.selectedPlanIndex,
    required this.onPlanSelected,
    this.currentPlan,
    this.isSubscribed = false,
  });

  bool _isCurrentPlanTab(int index) {
    if (!isSubscribed) return false;
    if (currentPlan == 'yearly' && index == 2) return true;
    if (currentPlan == 'monthly' && index == 1) return true;
    return false;
  }

  Widget _buildToggleItem(BuildContext context, int index, String label,
      int selectedIndex, ValueChanged<int> onSelect) {
    final isSelected = selectedIndex == index;
    final isCurrent = _isCurrentPlanTab(index);

    return GestureDetector(
      onTap: () => onSelect(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'NotoSansArabic',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? const Color(0xFF0F172A)
                    : Colors.white,
              ),
            ),
            // Small green dot for the tab that is the user's active plan
            if (isCurrent) ...[
              const SizedBox(width: 5),
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF4ADE80),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.loc.isAr;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border(
          bottom: BorderSide(
              color: const Color(0xFFFDC800).withOpacity(0.2), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Back + title row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 24, color: Colors.white),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: isAr
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _PlusIconBadge(),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: isAr
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) =>
                                  const LinearGradient(
                                colors: [
                                  Color(0xFFFDC800),
                                  Color(0xFFFFA500)
                                ],
                              ).createShader(bounds),
                              child: Text(
                                context.loc.premiumPlusTitle,
                                style: const TextStyle(
                                  fontFamily: 'NotoSansArabic',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              context.loc.premiumPlusSubtitle,
                              style: TextStyle(
                                fontFamily: 'NotoSansArabic',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            if (SessionService().isAdmin) ...[
              const SizedBox(height: 12),
              Align(
                alignment:
                    isAr ? Alignment.centerLeft : Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const EditPlanPage()));
                  },
                  icon: const Icon(Icons.edit_calendar_rounded,
                      color: Colors.white, size: 18),
                  label: const Text('Edit Plan',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(
                      backgroundColor: Colors.white24,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // 3-Way Toggle
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleItem(context, 0, context.loc.freePlanTitle,
                        selectedPlanIndex, onPlanSelected),
                    _buildToggleItem(context, 1, context.loc.monthly,
                        selectedPlanIndex, onPlanSelected),
                    _buildToggleItem(context, 2, context.loc.yearly,
                        selectedPlanIndex, onPlanSelected),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            Align(
              alignment:
                  isAr ? Alignment.centerRight : Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (isAr) ...[
                    _LargePriceAr(selectedPlanIndex: selectedPlanIndex),
                    const SizedBox(width: 16),
                    _PriceDetailsAr(selectedPlanIndex: selectedPlanIndex),
                  ] else ...[
                    _PriceBlock(selectedPlanIndex: selectedPlanIndex),
                    const SizedBox(width: 16),
                    _PriceDetailsEn(selectedPlanIndex: selectedPlanIndex),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small reusable widgets
// ─────────────────────────────────────────────────────────────────────────────

class _PlusIconBadge extends StatelessWidget {
  const _PlusIconBadge();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFFFDC800).withOpacity(0.3)),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10)
        ],
      ),
      child: const Icon(Icons.auto_awesome_rounded,
          size: 24, color: Color(0xFFFDC800)),
    );
  }
}

class _PriceBlock extends StatelessWidget {
  final int selectedPlanIndex;
  const _PriceBlock({required this.selectedPlanIndex});
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          selectedPlanIndex == 2
              ? '2990'
              : (selectedPlanIndex == 1 ? '299' : context.loc.freePlanPrice),
          style: const TextStyle(
            fontFamily: 'NotoSansArabic',
            fontSize: 54,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1,
          ),
        ),
        const SizedBox(width: 8),
        if (selectedPlanIndex != 0)
          Text(
            context.loc.egp,
            style: const TextStyle(
              fontFamily: 'NotoSansArabic',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
      ],
    );
  }
}

class _PriceDetailsEn extends StatelessWidget {
  final int selectedPlanIndex;
  const _PriceDetailsEn({required this.selectedPlanIndex});
  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          selectedPlanIndex == 2
              ? 'Yearly'
              : (selectedPlanIndex == 1 ? loc.monthlyLabelSmall : ''),
          style: const TextStyle(
            fontFamily: 'NotoSansArabic',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          selectedPlanIndex == 0
              ? loc.freePlanPriceDesc
              : loc.paymentYearlySavings,
          style: TextStyle(
            fontFamily: 'NotoSansArabic',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class _PriceDetailsAr extends StatelessWidget {
  final int selectedPlanIndex;
  const _PriceDetailsAr({required this.selectedPlanIndex});
  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          selectedPlanIndex == 2
              ? context.loc.yearly
              : (selectedPlanIndex == 1 ? context.loc.monthlyLabelSmall : ''),
          style: const TextStyle(
            fontFamily: 'NotoSansArabic',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          selectedPlanIndex == 0
              ? loc.freePlanPriceDesc
              : loc.paymentYearlySavings,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontFamily: 'NotoSansArabic',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class _LargePriceAr extends StatelessWidget {
  final int selectedPlanIndex;
  const _LargePriceAr({required this.selectedPlanIndex});
  @override
  Widget build(BuildContext context) {
    return Text(
      selectedPlanIndex == 0
          ? context.loc.freePlanPrice
          : (selectedPlanIndex == 2
              ? '${context.loc.yearlyPrice} ${context.loc.egp}'
              : '${context.loc.monthlyPrice} ${context.loc.egp}'),
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      style: const TextStyle(
        fontFamily: 'NotoSansArabic',
        fontSize: 48,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        height: 1,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAr = context.loc.isAr;
    return Row(
      mainAxisAlignment:
          isAr ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isAr) ...[
          _SectionIcon(icon: icon),
          const SizedBox(width: 12)
        ],
        Text(
          title,
          style: TextStyle(
            fontFamily: 'NotoSansArabic',
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.onSurface,
          ),
        ),
        if (isAr) ...[const SizedBox(width: 12), _SectionIcon(icon: icon)],
      ],
    );
  }
}

class _SectionIcon extends StatelessWidget {
  const _SectionIcon({required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDC800).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFFFDC800).withOpacity(0.2)),
      ),
      child: Icon(icon, size: 20, color: const Color(0xFFFDC800)),
    );
  }
}

class _FeatureItemCard extends StatelessWidget {
  const _FeatureItemCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAr = context.loc.isAr;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
                alpha:
                    theme.brightness == Brightness.dark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isAr) ...[
            _FeatureIcon(icon: icon),
            const SizedBox(width: 16)
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: isAr
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      fontFamily: 'NotoSansArabic',
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                    )),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  textAlign:
                      isAr ? TextAlign.right : TextAlign.left,
                  style: TextStyle(
                    fontFamily: 'NotoSansArabic',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.65),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          if (isAr) ...[
            const SizedBox(width: 16),
            _FeatureIcon(icon: icon)
          ],
        ],
      ),
    );
  }
}

class _FeatureIcon extends StatelessWidget {
  const _FeatureIcon({required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDC800).withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFFFDC800).withOpacity(0.1)),
      ),
      child: Icon(icon, size: 24, color: const Color(0xFFFDC800)),
    );
  }
}

class _ServiceCategoryCard extends StatelessWidget {
  const _ServiceCategoryCard({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.features,
  });
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final List<String> features;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAr = context.loc.isAr;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment:
                isAr ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isAr) ...[
                _CategoryIcon(
                    icon: icon, bg: iconBackground, color: iconColor),
                const SizedBox(width: 14),
              ],
              Text(title,
                  style: TextStyle(
                    fontFamily: 'NotoSansArabic',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                  )),
              if (isAr) ...[
                const SizedBox(width: 14),
                _CategoryIcon(
                    icon: icon, bg: iconBackground, color: iconColor),
              ],
            ],
          ),
          const SizedBox(height: 18),
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: isAr
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                children: [
                  if (!isAr) ...[
                    _CheckIcon(theme: theme),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      feature,
                      textAlign:
                          isAr ? TextAlign.right : TextAlign.left,
                      style: TextStyle(
                        fontFamily: 'NotoSansArabic',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.8),
                        height: 1.4,
                      ),
                    ),
                  ),
                  if (isAr) ...[
                    const SizedBox(width: 12),
                    _CheckIcon(theme: theme),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon(
      {required this.icon, required this.bg, required this.color});
  final IconData icon;
  final Color bg;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(14)),
      child: Icon(icon, size: 22, color: color),
    );
  }
}

class _CheckIcon extends StatelessWidget {
  const _CheckIcon({required this.theme});
  final ThemeData theme;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Icon(
        Icons.check_circle_rounded,
        size: 16,
        color: theme.brightness == Brightness.dark
            ? const Color(0xFF4ADE80)
            : const Color(0xFF16A34A),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sticky Footer — now handles all 5 real states cleanly
// ─────────────────────────────────────────────────────────────────────────────

class _StickyFooter extends StatelessWidget {
  final int selectedPlanIndex;
  final String? currentPlan;
  final bool isSubscribed;
  final bool isViewingCurrentPlan;

  const _StickyFooter({
    required this.selectedPlanIndex,
    required this.isViewingCurrentPlan,
    this.currentPlan,
    this.isSubscribed = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAr = context.loc.isAr;

    // ── State 1: Viewing their own active plan (monthly OR yearly) ──────────
    if (isViewingCurrentPlan) {
      final isYearly = currentPlan == 'yearly';
      return _FooterShell(
        theme: theme,
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF15803D).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFF15803D).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.verified_rounded,
                        color: Color(0xFF4ADE80), size: 22),
                    const SizedBox(width: 10),
                    Text(
                      isAr
                          ? (isYearly
                              ? 'أنت على أفضل خطة متاحة 🎉'
                              : 'اشتراكك الشهري نشط ✓')
                          : (isYearly
                              ? "You're on the best plan available 🎉"
                              : 'Your monthly subscription is active ✓'),
                      style: const TextStyle(
                        fontFamily: 'NotoSansArabic',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4ADE80),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Monthly subscribers see an upgrade CTA here too
              if (!isYearly) ...[
                SizedBox(
                  height: 58,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFDC800),
                      foregroundColor: const Color(0xFF0F172A),
                      elevation: 6,
                      shadowColor:
                          const Color(0xFFFDC800).withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => PaymentPage(
                            isYearly: true,
                            amount: 2990,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      isAr
                          ? 'ترقية إلى السنوية ووفّر أكثر'
                          : 'Upgrade to Yearly & Save More',
                      style: const TextStyle(
                        fontFamily: 'NotoSansArabic',
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                height: 52,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: theme.brightness == Brightness.dark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFF3F4F6),
                    side: BorderSide(
                        color: theme.dividerColor.withValues(alpha: 0.1)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    isAr ? 'رجوع' : 'Go Back',
                    style: TextStyle(
                      fontFamily: 'NotoSansArabic',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── State 2: Subscribed monthly, viewing yearly tab → upgrade ──────────
    if (isSubscribed && currentPlan == 'monthly' && selectedPlanIndex == 2) {
      return _FooterShell(
        theme: theme,
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 58,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFDC800),
                    foregroundColor: const Color(0xFF0F172A),
                    elevation: 6,
                    shadowColor: const Color(0xFFFDC800).withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => PaymentPage(
                          isYearly: true,
                          amount: 2990,
                        ),
                      ),
                    );
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Center(
                        child: Text(
                          isAr
                              ? 'ترقية إلى الخطة السنوية'
                              : 'Upgrade to Yearly Plan',
                          style: const TextStyle(
                            fontFamily: 'NotoSansArabic',
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const PositionedDirectional(
                        end: 16,
                        child: Icon(Icons.workspace_premium_rounded,
                            size: 22),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 52,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: theme.brightness == Brightness.dark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFF3F4F6),
                    side: BorderSide(
                        color: theme.dividerColor.withValues(alpha: 0.1)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    context.loc.maybeLater,
                    style: TextStyle(
                      fontFamily: 'NotoSansArabic',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── State 3: Viewing free tab while subscribed → downgrade option ───────
    if (selectedPlanIndex == 0 && isSubscribed) {
      return _FooterShell(
        theme: theme,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 52,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(isAr
                  ? 'تغيير إلى الخطة المجانية'
                  : 'Downgrade to Free Plan'),
            ),
          ),
        ),
      );
    }

    // ── State 4 & 5: Not subscribed → normal subscribe flow ─────────────────
    final targetIsYearly = selectedPlanIndex == 2;
    final price = targetIsYearly ? 2990.0 : 299.0;

    return _FooterShell(
      theme: theme,
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 58,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFDC800),
                  foregroundColor: const Color(0xFF0F172A),
                  elevation: 6,
                  shadowColor: const Color(0xFFFDC800).withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => PaymentPage(
                        isYearly: targetIsYearly,
                        amount: price,
                      ),
                    ),
                  );
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Text(
                        context.loc.upgradeToPlus,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'NotoSansArabic',
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const PositionedDirectional(
                      end: 16,
                      child: Icon(Icons.workspace_premium_rounded, size: 22),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 52,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: theme.brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFFF3F4F6),
                  side: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.1)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  context.loc.maybeLater,
                  textAlign:
                      isAr ? TextAlign.right : TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'NotoSansArabic',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.loc.moneyBackGuarantee,
              textAlign: isAr ? TextAlign.right : TextAlign.center,
              style: TextStyle(
                fontFamily: 'NotoSansArabic',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared decoration wrapper for all footer states.
class _FooterShell extends StatelessWidget {
  final ThemeData theme;
  final Widget child;
  const _FooterShell({required this.theme, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
                alpha:
                    theme.brightness == Brightness.dark ? 0.4 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: child,
    );
  }
}