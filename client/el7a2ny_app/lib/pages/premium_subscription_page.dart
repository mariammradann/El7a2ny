import 'package:flutter/material.dart';
import 'payment_page.dart';
import '../core/localization/app_strings.dart';

class PremiumSubscriptionPage extends StatelessWidget {
  const PremiumSubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAr = context.loc.isAr;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _PremiumHeader(),
            Expanded(
              child: Container(
                color: theme.scaffoldBackgroundColor,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                        title: context.loc.support24_7_Title,
                        subtitle: context.loc.support24_7_Desc,
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
                        iconBackground: const Color(0xFFEF4444).withOpacity(0.12),
                        iconColor: const Color(0xFFEF4444),
                        title: context.loc.medicalServicesTitle,
                        features: isAr ? [
                          'دخول المستشفى بأولوية',
                          'استشارات مع أخصائيين',
                          'زيارات رعاية صحية منزلية',
                          'توصيل الأدوية',
                        ] : [
                          'Priority hospital admission',
                          'Consultation with specialists',
                          'Home healthcare visits',
                          'Medicine delivery',
                        ],
                      ),
                      const SizedBox(height: 14),
                      _ServiceCategoryCard(
                        icon: Icons.local_airport_rounded,
                        iconBackground: const Color(0xFF2563EB).withOpacity(0.12),
                        iconColor: const Color(0xFF2563EB),
                        title: context.loc.transportServicesTitle,
                        features: isAr ? [
                          'خدمة الإسعاف الجوي',
                          'إسعاف أرضي مميز',
                        ] : [
                          'Air ambulance service',
                          'Premium ground ambulance',
                        ],
                      ),
                      const SizedBox(height: 14),
                      _ServiceCategoryCard(
                        icon: Icons.gpp_good_rounded,
                        iconBackground: const Color(0xFF15803D).withOpacity(0.12),
                        iconColor: const Color(0xFF15803D),
                        title: context.loc.insuranceCoverageTitle,
                        features: isAr ? [
                          'بدون حدود للمطالبات',
                          'تغطية الأمراض المزمنة',
                          'تشمل الأسنان والعيون',
                          'دعم الصحة النفسية',
                        ] : [
                          'Unlimited claims',
                          'Chronic disease coverage',
                          'Dental and vision included',
                          'Mental health support',
                        ],
                      ),
                      const SizedBox(height: 14),
                      _ServiceCategoryCard(
                        icon: Icons.headset_mic_rounded,
                        iconBackground: const Color(0xFF7C3AED).withOpacity(0.12),
                        iconColor: const Color(0xFF7C3AED),
                        title: context.loc.supportServicesTitle,
                        features: isAr ? [
                          'خط ساخن مخصص',
                          'مستشار صحي شخصي',
                          'مساعدة قانونية',
                          'دعم طوارئ السفر',
                        ] : [
                          'Dedicated hotline',
                          'Personal health advisor',
                          'Legal assistance',
                          'Travel emergency support',
                        ],
                      ),
                      const SizedBox(height: 32),
                      const _TestimonialCard(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
            const _StickyFooter(),
          ],
        ),
      ),
    );
  }
}

class _PremiumHeader extends StatelessWidget {
  const _PremiumHeader();

  @override
  Widget build(BuildContext context) {
    final isAr = context.loc.isAr;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF9500), Color(0xFFFF6B35), Color(0xFFF92E1C)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x40FF6B35),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.close_rounded, size: 24, color: Colors.white),
                ),
              ),
              Row(
                children: [
                  if (!isAr) ...[
                    const _PlusIconBadge(),
                    const SizedBox(width: 14),
                  ],
                  Column(
                    crossAxisAlignment: isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.loc.premiumPlusTitle,
                        style: const TextStyle(
                          fontFamily: 'NotoSansArabic',
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.loc.premiumPlusSubtitle,
                        style: TextStyle(
                          fontFamily: 'NotoSansArabic',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                  if (isAr) ...[
                    const SizedBox(width: 14),
                    const _PlusIconBadge(),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 36),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: isAr ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isAr) const _PriceBlock(),
              if (isAr) ...[
                const _PriceDetailsAr(),
                const SizedBox(width: 16),
                const _LargePriceAr(),
              ],
              if (!isAr) ...[
                const SizedBox(width: 16),
                const _PriceDetailsEn(),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _PlusIconBadge extends StatelessWidget {
  const _PlusIconBadge();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
          ),
        ],
      ),
      child: const Icon(
        Icons.auto_awesome_rounded,
        size: 24,
        color: Color(0xFFFF6B35),
      ),
    );
  }
}

class _PriceBlock extends StatelessWidget {
  const _PriceBlock();
  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '299',
          style: TextStyle(
            fontFamily: 'NotoSansArabic',
            fontSize: 54,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1,
          ),
        ),
        SizedBox(width: 8),
        Text(
          'EGP',
          style: TextStyle(
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
  const _PriceDetailsEn();
  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.monthlyLabelSmall,
          style: const TextStyle(
            fontFamily: 'NotoSansArabic',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          loc.paymentYearlySavings,
          style: TextStyle(
            fontFamily: 'NotoSansArabic',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}

class _PriceDetailsAr extends StatelessWidget {
  const _PriceDetailsAr();
  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          loc.monthlyLabelSmall,
          style: const TextStyle(
            fontFamily: 'NotoSansArabic',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          loc.paymentYearlySavings,
          style: TextStyle(
            fontFamily: 'NotoSansArabic',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}

class _LargePriceAr extends StatelessWidget {
  const _LargePriceAr();
  @override
  Widget build(BuildContext context) {
    return const Text(
      '299 جنيه',
      style: TextStyle(
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
      mainAxisAlignment: isAr ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isAr) ...[
          _SectionIcon(icon: icon),
          const SizedBox(width: 12),
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
        if (isAr) ...[
          const SizedBox(width: 12),
          _SectionIcon(icon: icon),
        ],
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
        color: const Color(0xFFFF9500).withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 20, color: const Color(0xFFFF9500)),
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
        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.2 : 0.04),
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
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'NotoSansArabic',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  textAlign: isAr ? TextAlign.right : TextAlign.left,
                  style: TextStyle(
                    fontFamily: 'NotoSansArabic',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withOpacity(0.65),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          if (isAr) ...[
            const SizedBox(width: 16),
            _FeatureIcon(icon: icon),
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
        color: const Color(0xFFFF9500).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, size: 24, color: const Color(0xFFFF9500)),
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
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: isAr ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isAr) ...[
                _CategoryIcon(icon: icon, bg: iconBackground, color: iconColor),
                const SizedBox(width: 14),
              ],
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'NotoSansArabic',
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (isAr) ...[
                const SizedBox(width: 14),
                _CategoryIcon(icon: icon, bg: iconBackground, color: iconColor),
              ],
            ],
          ),
          const SizedBox(height: 18),
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: isAr ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  if (!isAr) ...[
                    _CheckIcon(theme: theme),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      feature,
                      textAlign: isAr ? TextAlign.right : TextAlign.left,
                      style: TextStyle(
                        fontFamily: 'NotoSansArabic',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
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
  const _CategoryIcon({required this.icon, required this.bg, required this.color});
  final IconData icon;
  final Color bg;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
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
        color: theme.brightness == Brightness.dark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
      ),
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  const _TestimonialCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFEFCF3),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 3),
              child: Icon(Icons.star_rounded, size: 22, color: Color(0xFFF59E0B)),
            )),
          ),
          const SizedBox(height: 20),
          Text(
            context.loc.testimonialText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'NotoSansArabic',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.9),
              fontStyle: FontStyle.italic,
              height: 1.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _StickyFooter extends StatelessWidget {
  const _StickyFooter();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.4 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 58,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9500),
                  foregroundColor: Colors.white,
                  elevation: 6,
                  shadowColor: const Color(0xFFFF9500).withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => const PaymentPage(),
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.workspace_premium_rounded, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      context.loc.upgradeToPlus,
                      style: const TextStyle(
                        fontFamily: 'NotoSansArabic',
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
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
                  backgroundColor: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F4F6),
                  side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  context.loc.maybeLater,
                  style: TextStyle(
                    fontFamily: 'NotoSansArabic',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.loc.moneyBackGuarantee,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'NotoSansArabic',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
