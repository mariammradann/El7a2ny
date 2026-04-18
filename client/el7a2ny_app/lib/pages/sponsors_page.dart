import 'package:flutter/material.dart';
import '../models/sponsor_model.dart';
import '../services/api_service.dart';
import '../core/localization/app_strings.dart';

enum SponsorCategoryFilter { all, cars, insurance }

class SponsorsPage extends StatefulWidget {
  const SponsorsPage({super.key});

  @override
  State<SponsorsPage> createState() => _SponsorsPageState();
}

class _SponsorsPageState extends State<SponsorsPage> {
  SponsorCategoryFilter _selectedCategory = SponsorCategoryFilter.all;
  List<SponsorModel> _sponsors = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() { _loading = true; _error = null; });
      final data = await ApiService.fetchSponsors();
      if (mounted) setState(() { _sponsors = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<SponsorModel> _filteredSponsors() {
    if (_selectedCategory == SponsorCategoryFilter.all) return _sponsors;
    final cat = _selectedCategory == SponsorCategoryFilter.cars 
        ? SponsorCategory.cars 
        : SponsorCategory.insurance;
    return _sponsors.where((s) => s.category == cat).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredSponsors();
    final isAr = context.loc.isAr;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                      alignment: isAr ? Alignment.centerRight : Alignment.centerLeft,
                      child: Text(
                        _selectedCategory == SponsorCategoryFilter.all
                            ? context.loc.viewAllPartners
                            : _selectedCategory == SponsorCategoryFilter.cars
                            ? '${context.loc.viewCarCentersCount} (${filtered.length})'
                            : '${context.loc.viewInsuranceCount} (${filtered.length})',
                        style: TextStyle(
                          fontFamily: 'NotoSansArabic',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _loading 
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(_error!),
                        ElevatedButton(onPressed: _load, child: Text(context.loc.tryAgain)),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      ...filtered
                          .asMap()
                          .entries
                          .map((entry) {
                            int idx = entry.key;
                            SponsorModel sponsor = entry.value;

                            // Derive UI styles from category
                            final isInsurance = sponsor.category == SponsorCategory.insurance;
                            
                            return [
                              SponsorCard(
                                topLabel: sponsor.isFeatured ? context.loc.featuredPartner : null,
                                topColor: isInsurance ? const Color(0xFF16A34A) : const Color(0xFFFF8C00),
                                borderColor: sponsor.isFeatured 
                                    ? (isInsurance ? const Color(0xFF16A34A) : const Color(0xFFF97316))
                                    : Colors.transparent,
                                buttonColor: isInsurance ? const Color(0xFF16A34A) : const Color(0xFFEA580C),
                                iconBackground: isInsurance ? const Color(0xFFD1FAE5) : const Color(0xFFFFEBE5),
                                iconColor: isInsurance ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                title: sponsor.title,
                                rating: sponsor.rating,
                                badgeLabel: sponsor.badgeLabel,
                                badgeBackground: isInsurance ? const Color(0xFFD1FAE5) : const Color(0xFFFFEDD5),
                                badgeTextColor: isInsurance ? const Color(0xFF166534) : const Color(0xFFEA580C),
                                description: sponsor.description,
                                services: sponsor.services,
                                phone: sponsor.phone,
                                branch: sponsor.branch,
                              ),
                              if (idx < filtered.length - 1)
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
          Align(
            alignment: context.loc.isAr ? Alignment.centerRight : Alignment.centerLeft,
            child: Text(
              context.loc.trustedSponsors,
              style: const TextStyle(
                fontFamily: 'NotoSansArabic',
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: context.loc.isAr ? Alignment.centerRight : Alignment.centerLeft,
            child: Text(
              context.loc.sponsorsSubtitle,
              style: const TextStyle(
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

  final SponsorCategoryFilter selectedCategory;
  final Function(SponsorCategoryFilter) onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return Row(
      textDirection: loc.isAr ? TextDirection.rtl : TextDirection.ltr,
      children: [
        Expanded(
          child: _SponsorTab(
            label: loc.allSponsors,
            active: selectedCategory == SponsorCategoryFilter.all,
            onTap: () => onCategoryChanged(SponsorCategoryFilter.all),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SponsorTab(
            label: loc.carCenters,
            icon: Icons.local_taxi,
            active: selectedCategory == SponsorCategoryFilter.cars,
            onTap: () => onCategoryChanged(SponsorCategoryFilter.cars),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SponsorTab(
            label: loc.insuranceSponsors,
            icon: Icons.shield,
            active: selectedCategory == SponsorCategoryFilter.insurance,
            onTap: () => onCategoryChanged(SponsorCategoryFilter.insurance),
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
          color: active
              ? const Color(0xFF2563EB)
              : (Theme.of(context).brightness == Brightness.dark
                  ? Colors.white10
                  : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(999),
          border: active
              ? null
              : Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white10
                      : const Color(0xFFE2E8F0)),
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
                color: active
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderColor == Colors.transparent
              ? (Theme.of(context).brightness == Brightness.dark
                  ? Colors.white10
                  : Colors.transparent)
              : borderColor,
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black26
                : Colors.black.withOpacity(0.06),
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
                    SizedBox(width: context.loc.isAr ? 14 : 0),
                    if (!context.loc.isAr) const Spacer(),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontFamily: 'NotoSansArabic',
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).colorScheme.onSurface,
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
                                style: TextStyle(
                                  fontFamily: 'NotoSansArabic',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.onSurface,
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
                  style: TextStyle(
                    fontFamily: 'NotoSansArabic',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  context.loc.servicesProvided,
                  style: TextStyle(
                    fontFamily: 'NotoSansArabic',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                _SponsorServicesGrid(services: services),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white10
                        : const Color(0xFFF3F4F6),
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
                        style: TextStyle(
                          fontFamily: 'NotoSansArabic',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
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
                        style: TextStyle(
                          fontFamily: 'NotoSansArabic',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
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
                  child: Text(
                    context.loc.callNowBtn,
                    style: const TextStyle(
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
          Text(
            context.loc.becomePartner,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'NotoSansArabic',
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            context.loc.partnerProgramDesc,
            textAlign: TextAlign.center,
            style: const TextStyle(
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
            child: Text(
              context.loc.applyForPartnership,
              style: const TextStyle(
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
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white10
                : const Color(0xFFF8FAFC),
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
                  style: TextStyle(
                    fontFamily: 'NotoSansArabic',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
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
