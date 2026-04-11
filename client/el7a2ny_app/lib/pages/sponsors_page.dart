import 'package:flutter/material.dart';

enum SponsorCategory { all, cars, insurance }

class SponsorsPage extends StatefulWidget {
  const SponsorsPage({super.key});

  @override
  State<SponsorsPage> createState() => _SponsorsPageState();
}

class _SponsorsPageState extends State<SponsorsPage> {
  SponsorCategory _selectedCategory = SponsorCategory.all;

  final List<Map<String, dynamic>> _allSponsors = [
    {
      'category': SponsorCategory.cars,
      'topLabel': 'شريك مميز',
      'topColor': const Color(0xFFFF8C00),
      'borderColor': const Color(0xFFF97316),
      'buttonColor': const Color(0xFFEA580C),
      'iconBackground': const Color(0xFFFFEBE5),
      'iconColor': const Color(0xFFDC2626),
      'title': 'بافاريان أوتو جروب',
      'rating': '4.8',
      'badgeLabel': 'مركز سيارات',
      'badgeBackground': const Color(0xFFFFEDD5),
      'badgeTextColor': const Color(0xFFEA580C),
      'description': 'خدمات سيارات مميزة في جميع أنحاء مصر',
      'services': ['مساعدة على الطريق', 'ونش طوارئ', 'فحص مجاني', 'دعم 24/7'],
      'phone': '16625',
      'branch': 'فرع 15',
    },
    {
      'category': SponsorCategory.cars,
      'topLabel': null,
      'topColor': Colors.transparent,
      'borderColor': Colors.transparent,
      'buttonColor': const Color(0xFFEA580C),
      'iconBackground': const Color(0xFFE0F2FE),
      'iconColor': const Color(0xFF2563EB),
      'title': 'غبور أوتو',
      'rating': '4.7',
      'badgeLabel': 'مركز سيارات',
      'badgeBackground': const Color(0xFFFFF7ED),
      'badgeTextColor': const Color(0xFFF97316),
      'description': 'موزع ومقدم خدمات سيارات رائد',
      'services': [
        'خدمة الونش',
        'دعم الحوادث',
        'مطالبات التأمين',
        'إصلاحات طارئة',
      ],
      'phone': '16662',
      'branch': 'فرع 25',
    },
    {
      'category': SponsorCategory.insurance,
      'topLabel': 'شريك مميز',
      'topColor': const Color(0xFF16A34A),
      'borderColor': const Color(0xFF16A34A),
      'buttonColor': const Color(0xFF16A34A),
      'iconBackground': const Color(0xFFD1FAE5),
      'iconColor': const Color(0xFF16A34A),
      'title': 'أليانز مصر',
      'rating': '4.9',
      'badgeLabel': 'تأمين',
      'badgeBackground': const Color(0xFFD1FAE5),
      'badgeTextColor': const Color(0xFF166534),
      'description': 'رائد التأمين العالمي بتغطية شاملة',
      'services': [
        'شبكة دولية',
        'تغطية طبية شاملة',
        'رعاية طوارئ',
        'علاج بدون نقدي',
      ],
      'phone': '16555',
      'branch': 'فرع 200',
    },
    {
      'category': SponsorCategory.insurance,
      'topLabel': null,
      'topColor': Colors.transparent,
      'borderColor': Colors.transparent,
      'buttonColor': const Color(0xFF16A34A),
      'iconBackground': const Color(0xFFE0F2FE),
      'iconColor': const Color(0xFF2563EB),
      'title': 'مصر للتأمين',
      'rating': '4.5',
      'badgeLabel': 'تأمين',
      'badgeBackground': const Color(0xFFD1FAE5),
      'badgeTextColor': const Color(0xFF166534),
      'description': 'شركة التأمين المصرية الموثوقة',
      'services': ['باقات معقولة', 'معالجة سريعة', 'شبكة واسعة', 'تغطية محلية'],
      'phone': '16223',
      'branch': 'فرع 106',
    },
  ];

  List<Map<String, dynamic>> get _filteredSponsors {
    if (_selectedCategory == SponsorCategory.all) {
      return _allSponsors;
    }
    return _allSponsors
        .where((sponsor) => sponsor['category'] == _selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SponsorsHeader(),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SponsorsTabs(
                      selectedCategory: _selectedCategory,
                      onCategoryChanged: (category) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        _selectedCategory == SponsorCategory.all
                            ? 'عرض جميع 8 شركاء موثوقين'
                            : _selectedCategory == SponsorCategory.cars
                            ? 'عرض ${_filteredSponsors.length} مركز سيارات'
                            : 'عرض ${_filteredSponsors.length} شركات تأمين',
                        style: const TextStyle(
                          fontFamily: 'NotoSansArabic',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      ..._filteredSponsors
                          .asMap()
                          .entries
                          .map((entry) {
                            int idx = entry.key;
                            Map<String, dynamic> sponsor = entry.value;
                            return [
                              SponsorCard(
                                topLabel: sponsor['topLabel'],
                                topColor: sponsor['topColor'],
                                borderColor: sponsor['borderColor'],
                                buttonColor: sponsor['buttonColor'],
                                iconBackground: sponsor['iconBackground'],
                                iconColor: sponsor['iconColor'],
                                title: sponsor['title'],
                                rating: sponsor['rating'],
                                badgeLabel: sponsor['badgeLabel'],
                                badgeBackground: sponsor['badgeBackground'],
                                badgeTextColor: sponsor['badgeTextColor'],
                                description: sponsor['description'],
                                services: List<String>.from(
                                  sponsor['services'],
                                ),
                                phone: sponsor['phone'],
                                branch: sponsor['branch'],
                              ),
                              if (idx < _filteredSponsors.length - 1)
                                const SizedBox(height: 16),
                            ];
                          })
                          .expand((list) => list),
                      const SizedBox(height: 24),
                      const _PartnerFooterCard(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SponsorsHeader extends StatelessWidget {
  const _SponsorsHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.close, size: 22, color: Colors.white),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(10),
                child: const Icon(
                  Icons.apartment,
                  size: 22,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'الرعاة الموثوقون',
              style: TextStyle(
                fontFamily: 'NotoSansArabic',
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'شركاء متميزون لاحتياجات الطوارئ',
              style: TextStyle(
                fontFamily: 'NotoSansArabic',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SponsorsTabs extends StatelessWidget {
  const _SponsorsTabs({
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  final SponsorCategory selectedCategory;
  final Function(SponsorCategory) onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Expanded(
          child: _SponsorTab(
            label: 'جميع الرعاة',
            active: selectedCategory == SponsorCategory.all,
            onTap: () => onCategoryChanged(SponsorCategory.all),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SponsorTab(
            label: 'مراكز السيارات',
            icon: Icons.local_taxi,
            active: selectedCategory == SponsorCategory.cars,
            onTap: () => onCategoryChanged(SponsorCategory.cars),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SponsorTab(
            label: 'التأمين الصحي',
            icon: Icons.shield,
            active: selectedCategory == SponsorCategory.insurance,
            onTap: () => onCategoryChanged(SponsorCategory.insurance),
          ),
        ),
      ],
    );
  }
}

class _SponsorTab extends StatelessWidget {
  const _SponsorTab({
    required this.label,
    this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(999),
          border: active ? null : Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: active ? Colors.white : const Color(0xFF475569),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'NotoSansArabic',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SponsorCard extends StatelessWidget {
  const SponsorCard({
    super.key,
    required this.title,
    required this.rating,
    required this.badgeLabel,
    required this.badgeBackground,
    required this.badgeTextColor,
    required this.description,
    required this.services,
    required this.phone,
    required this.branch,
    required this.buttonColor,
    required this.iconBackground,
    required this.iconColor,
    required this.borderColor,
    required this.topColor,
    this.topLabel,
  });

  final String title;
  final String rating;
  final String badgeLabel;
  final Color badgeBackground;
  final Color badgeTextColor;
  final String description;
  final List<String> services;
  final String phone;
  final String branch;
  final Color buttonColor;
  final Color iconBackground;
  final Color iconColor;
  final Color borderColor;
  final Color topColor;
  final String? topLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderColor,
          width: borderColor == Colors.transparent ? 0 : 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (topLabel != null) ...[
            Container(
              decoration: BoxDecoration(
                color: topColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Icon(Icons.star, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    topLabel!,
                    style: const TextStyle(
                      fontFamily: 'NotoSansArabic',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: iconBackground,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Icon(Icons.apartment, color: iconColor, size: 26),
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
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 14,
                                color: Color(0xFFF59E0B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                rating,
                                style: const TextStyle(
                                  fontFamily: 'NotoSansArabic',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: badgeBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Text(
                        badgeLabel,
                        style: TextStyle(
                          fontFamily: 'NotoSansArabic',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: badgeTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'NotoSansArabic',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4B5563),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'الخدمات المقدمة:',
                  style: TextStyle(
                    fontFamily: 'NotoSansArabic',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 12),
                _SponsorServicesGrid(services: services),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.phone,
                        color: Color(0xFF2563EB),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        phone,
                        style: const TextStyle(
                          fontFamily: 'NotoSansArabic',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.location_on,
                        color: Color(0xFFDC2626),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        branch,
                        style: const TextStyle(
                          fontFamily: 'NotoSansArabic',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {},
                  child: const Text(
                    'اتصل الآن',
                    style: TextStyle(
                      fontFamily: 'NotoSansArabic',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
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

class _PartnerFooterCard extends StatelessWidget {
  const _PartnerFooterCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.apartment, size: 32, color: Colors.white),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'كن شريكاً',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'NotoSansArabic',
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'انضم لبرنامج الشركاء وتمتع بوصول أسرع إلى العملاء الموثوقين',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'NotoSansArabic',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () {},
            child: const Text(
              'التقدم للشراكة',
              style: TextStyle(
                fontFamily: 'NotoSansArabic',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2563EB),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SponsorServicesGrid extends StatelessWidget {
  const _SponsorServicesGrid({required this.services});

  final List<String> services;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 3.8,
      children: services.map((service) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle,
                size: 16,
                color: Color(0xFF16A34A),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  service,
                  style: const TextStyle(
                    fontFamily: 'NotoSansArabic',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
