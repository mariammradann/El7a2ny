import 'package:flutter/material.dart';

import '../core/localization/app_strings.dart';
import '../services/session_service.dart';
import '../models/sponsor_model.dart';
import '../services/api_service.dart';
import 'add_sponsor_page.dart';
import 'become_partner_page.dart';

// ─────────────────────────────────────────────
//  SPONSORS PAGE
// ─────────────────────────────────────────────
class SponsorsPage extends StatefulWidget {
  const SponsorsPage({super.key});

  @override
  State<SponsorsPage> createState() => _SponsorsPageState();
}

class _SponsorsPageState extends State<SponsorsPage> {
  String _selectedCategory = 'all';
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
      setState(() {
        _loading = true;
        _error = null;
      });
      final data = await ApiService.fetchSponsors();
      if (mounted) {
        setState(() {
          _sponsors = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _load,
        color: theme.primaryColor,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 140,
              pinned: true,
              backgroundColor: theme.scaffoldBackgroundColor,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface),
                onPressed: () => Navigator.of(context).pop(),
              ),
              centerTitle: true,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                titlePadding: const EdgeInsets.only(bottom: 16),
                title: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(loc.trustedSponsors, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, fontFamily: 'NotoSansArabic')),
                    Text(loc.sponsorsSubtitle, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                  ],
                ),
              ),
              actions: [
                if (SessionService().isAdmin)
                  IconButton(
                    icon: const Icon(Icons.add_business_rounded, color: Colors.blue),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddSponsorPage()));
                    },
                  ),
                IconButton(
                  icon: Icon(Icons.handshake_rounded, color: theme.primaryColor),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BecomePartnerPage()));
                  },
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Row(
                  children: [
                    if (SessionService().isAdmin) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddSponsorPage()));
                          },
                          icon: const Icon(Icons.add_business_rounded, size: 18),
                          label: Text(loc.addSponsor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'NotoSansArabic')),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            side: const BorderSide(color: Colors.blue),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BecomePartnerPage()));
                        },
                        icon: const Icon(Icons.handshake_rounded, size: 18),
                        label: Text(loc.becomePartner, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'NotoSansArabic')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _CategoryChip(label: loc.allSponsors, icon: Icons.all_inclusive, selected: _selectedCategory == 'all', onTap: () => setState(() => _selectedCategory = 'all')),
                    const SizedBox(width: 12),
                    _CategoryChip(label: loc.carCenters, icon: Icons.car_repair, selected: _selectedCategory == 'cars', onTap: () => setState(() => _selectedCategory = 'cars')),
                    const SizedBox(width: 12),
                    _CategoryChip(label: loc.insuranceSponsors, icon: Icons.health_and_safety, selected: _selectedCategory == 'medical', onTap: () => setState(() => _selectedCategory = 'medical')),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (_loading)
                    const Padding(padding: EdgeInsets.symmetric(vertical: 80), child: Center(child: CircularProgressIndicator()))
                  else if (_error != null)
                    Center(
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.orange, size: 48),
                          const SizedBox(height: 12),
                          Text(loc.connError, style: const TextStyle(fontWeight: FontWeight.bold)),
                          TextButton(onPressed: _load, child: Text(loc.retry)),
                        ],
                      ),
                    )
                  else ...[
                    ..._sponsors.where((s) {
                      if (_selectedCategory == 'all') return true;
                      if (_selectedCategory == 'cars') return s.category == SponsorCategory.cars;
                      if (_selectedCategory == 'medical') {
                        return s.category == SponsorCategory.insurance || s.category == SponsorCategory.medical;
                      }
                      return true;
                    }).map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: _SponsorCard(
                        title: s.title,
                        badge: s.badgeLabel,
                        imageUrl: 'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?w=128&h=128&auto=format&fit=crop', // fallback image
                        services: s.services,
                        phone: s.phone,
                      ),
                    )),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? theme.primaryColor : theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          boxShadow: selected ? [BoxShadow(color: theme.primaryColor.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))] : [],
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: selected ? Colors.white : theme.colorScheme.onSurface),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: selected ? Colors.white : theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontFamily: 'NotoSansArabic')),
          ],
        ),
      ),
    );
  }
}

class _SponsorCard extends StatelessWidget {
  final String title, badge, imageUrl, phone;
  final List<String> services;

  const _SponsorCard({required this.title, required this.badge, required this.imageUrl, required this.phone, required this.services});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(imageUrl, width: 64, height: 64, fit: BoxFit.cover, errorBuilder: (_, _, _) => Container(color: theme.primaryColor.withValues(alpha: 0.1), width: 64, height: 64, child: const Icon(Icons.business))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: theme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Text(badge, style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w900, fontSize: 10, fontFamily: 'NotoSansArabic'))),
                      const SizedBox(height: 6),
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, fontFamily: 'NotoSansArabic')),
                    ],
                  ),
                ),
                IconButton.filledTonal(onPressed: () {}, icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16)),
                if (SessionService().isAdmin) ...[
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: () {
                      SessionService().logAction('Started editing sponsor: $title');
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit Sponsor Mode Active')));
                    },
                    icon: const Icon(Icons.edit_rounded, size: 16, color: Colors.blue),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: () {
                      SessionService().logAction('Deleted sponsor: $title');
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sponsor Deleted')));
                    },
                    icon: const Icon(Icons.delete_forever_rounded, size: 16, color: Colors.red),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.servicesProvided, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, fontFamily: 'NotoSansArabic')),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: services.map((s) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: theme.colorScheme.onSurface.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(12)), child: Text(s, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.bold)))).toList()),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1))),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(Icons.phone_rounded, color: theme.primaryColor, size: 20),
                        const SizedBox(width: 12),
                        Text(phone, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                        const Spacer(),
                        Text(loc.callNowBtn, style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w900, fontSize: 13, fontFamily: 'NotoSansArabic')),
                      ],
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
