import 'package:flutter/material.dart';
import 'payment_page.dart';

class PremiumSubscriptionPage extends StatelessWidget {
  const PremiumSubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const _PremiumHeader(),
              Expanded(
                child: Container(
                  color: const Color(0xFFF8F9FA),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: const [
                        _SectionHeader(
                          title: 'المميزات الحصرية',
                          icon: Icons.star,
                        ),
                        SizedBox(height: 16),
                        _FeatureItemCard(
                          icon: Icons.flash_on,
                          title: 'استجابة فورية',
                          subtitle: 'توصيل بخدمات الطوارئ أسرع 10 مرات',
                        ),
                        SizedBox(height: 12),
                        _FeatureItemCard(
                          icon: Icons.shield,
                          title: 'تأمين مميز',
                          subtitle: 'تغطية موسعة مع أفضل شركات التأمين',
                        ),
                        SizedBox(height: 12),
                        _FeatureItemCard(
                          icon: Icons.access_time,
                          title: 'دعم 24/7',
                          subtitle: 'استشارات طبية متاحة على مدار الساعة',
                        ),
                        SizedBox(height: 12),
                        _FeatureItemCard(
                          icon: Icons.people,
                          title: 'حماية العائلة',
                          subtitle: 'تغطية تصل لـ 5 أفراد من العائلة',
                        ),
                        SizedBox(height: 12),
                        _FeatureItemCard(
                          icon: Icons.navigation,
                          title: 'تتبع مباشر',
                          subtitle: 'تتبع الإسعاف والخدمات في الوقت الفعلي',
                        ),
                        SizedBox(height: 12),
                        _FeatureItemCard(
                          icon: Icons.favorite,
                          title: 'السجلات الصحية',
                          subtitle: 'الوصول للتاريخ الطبي والتقارير الكاملة',
                        ),
                        SizedBox(height: 24),
                        _SectionHeader(
                          title: 'فئات الخدمات',
                          icon: Icons.flash_on,
                        ),
                        SizedBox(height: 16),
                        _ServiceCategoryCard(
                          icon: Icons.favorite,
                          iconBackground: Color(0xFFFFF1F2),
                          iconColor: Color(0xFFEF4444),
                          title: 'الخدمات الطبية',
                          features: [
                            'دخول المستشفى بأولوية',
                            'استشارات مع أخصائيين',
                            'زيارات رعاية صحية منزلية',
                            'توصيل الأدوية',
                          ],
                        ),
                        SizedBox(height: 12),
                        _ServiceCategoryCard(
                          icon: Icons.navigation,
                          iconBackground: Color(0xFFE0F2FE),
                          iconColor: Color(0xFF2563EB),
                          title: 'النقل الطارئ',
                          features: [
                            'خدمة الإسعاف الجوي',
                            'إسعاف أرضي مميز',
                          ],
                        ),
                        SizedBox(height: 12),
                        _ServiceCategoryCard(
                          icon: Icons.shield,
                          iconBackground: Color(0xFFD1FAE5),
                          iconColor: Color(0xFF15803D),
                          title: 'التأمين والتغطية',
                          features: [
                            'بدون حدود للمطالبات',
                            'تغطية الأمراض المزمنة',
                            'تشمل الأسنان والعيون',
                            'دعم الصحة النفسية',
                          ],
                        ),
                        SizedBox(height: 12),
                        _ServiceCategoryCard(
                          icon: Icons.phone,
                          iconBackground: Color(0xFFF3E8FF),
                          iconColor: Color(0xFF7C3AED),
                          title: 'خدمات الدعم',
                          features: [
                            'خط ساخن مخصص',
                            'مستشار صحي شخصي',
                            'مساعدة قانونية',
                            'دعم طوارئ السفر',
                          ],
                        ),
                        SizedBox(height: 24),
                        _TestimonialCard(),
                        SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
              const _StickyFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumHeader extends StatelessWidget {
  const _PremiumHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFFFF9500), Color(0xFFFF6B35), Color(0xFFF92E1C)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
                  child: const Icon(Icons.close, size: 24, color: Colors.white),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.emoji_events,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'إلحقني بلس',
                        style: TextStyle(
                          fontFamily: 'NotoSansArabic',
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'خدمات الطوارئ المميزة',
                        style: TextStyle(
                          fontFamily: 'NotoSansArabic',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'شهرياً',
                    style: TextStyle(
                      fontFamily: 'NotoSansArabic',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'أو 2,990 جنيه/سنوياً (وفر 17%)',
                    style: TextStyle(
                      fontFamily: 'NotoSansArabic',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              const Text(
                '299 جنيه',
                style: TextStyle(
                  fontFamily: 'NotoSansArabic',
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'NotoSansArabic',
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1E0),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFFFF9500)),
        ),
      ],
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 24, color: const Color(0xFFFF9500)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'NotoSansArabic',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'NotoSansArabic',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'NotoSansArabic',
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      feature,
                      style: const TextStyle(
                        fontFamily: 'NotoSansArabic',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  const _TestimonialCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFEFCF3),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.star, size: 18, color: Color(0xFFF59E0B)),
              SizedBox(width: 6),
              Icon(Icons.star, size: 18, color: Color(0xFFF59E0B)),
              SizedBox(width: 6),
              Icon(Icons.star, size: 18, color: Color(0xFFF59E0B)),
              SizedBox(width: 6),
              Icon(Icons.star, size: 18, color: Color(0xFFF59E0B)),
              SizedBox(width: 6),
              Icon(Icons.star, size: 18, color: Color(0xFFF59E0B)),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '"إلحقني بلس أنقذ حياتي. الاستجابة السريعة وصلتني للمستشفى في وقت قياسي."',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'NotoSansArabic',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
              height: 1.7,
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.08),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9500),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
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
                children: const [
                  Icon(Icons.emoji_events, size: 18, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'الترقية لإلحقني بلس',
                    style: TextStyle(
                      fontFamily: 'NotoSansArabic',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFF3F4F6),
                side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'ربما لاحقاً',
                style: TextStyle(
                  fontFamily: 'NotoSansArabic',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.center,
              child: Text(
                'ضمان استرجاع المال لمدة 30 يوم • يمكن الإلغاء في أي وقت',
                style: TextStyle(
                  fontFamily: 'NotoSansArabic',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF9CA3AF),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
