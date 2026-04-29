import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../services/api_service.dart';
import '../../models/help_initiative_model.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/main_shell_screen.dart';
import '../create_initiative_screen.dart';

class CommunityTabPage extends StatefulWidget {
  const CommunityTabPage({super.key});

  @override
  State<CommunityTabPage> createState() => _CommunityTabPageState();
}

class _CommunityTabPageState extends State<CommunityTabPage> {
  List<HelpInitiative> _initiatives = [];
  bool _loading = true;
  String? _error;
  HelpCategory? _selectedCategory;

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
      final data = await ApiService.fetchHelpInitiatives();
      if (mounted)
        setState(() {
          _initiatives = data;
          _loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _loading = false;
        });
    }
  }

  List<HelpInitiative> _getFilteredInitiatives() {
    if (_selectedCategory == null) return _initiatives;
    return _initiatives
        .where((initiative) => initiative.category == _selectedCategory)
        .toList();
  }

  Widget _buildCategoryFilters(BuildContext context) {
    final categories = HelpCategory.values;
    final loc = context.loc;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _CategoryChip(
            label: loc.allLabel,
            icon: Icons.all_inclusive,
            selected: _selectedCategory == null,
            onTap: () => setState(() => _selectedCategory = null),
          ),
          const SizedBox(width: 12),
          ...categories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _CategoryChip(
                label: loc.helpCategoryName(category.name),
                iconText: category.categoryIcon,
                selected: _selectedCategory == category,
                onTap: () => setState(() => _selectedCategory = category),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAr = context.loc.isAr;
    final loc = context.loc;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _load,
        color: theme.primaryColor,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            _buildSliverAppBar(context, theme, isAr),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildStatsGrid(context, theme),
                  const SizedBox(height: 28),
                  _SectionTitle(title: loc.helpInitiatives),
                  const SizedBox(height: 16),
                  _buildCategoryFilters(context),
                  const SizedBox(height: 16),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: Colors.orange,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            loc.connError,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextButton(onPressed: _load, child: Text(loc.retry)),
                        ],
                      ),
                    )
                  else ...[
                    ..._getFilteredInitiatives().map(
                      (initiative) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _HelpInitiativeCard(initiative: initiative),
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(
    BuildContext context,
    ThemeData theme,
    bool isAr,
  ) {
    final loc = context.loc;
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: theme.primaryColor,
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: const Icon(
            Icons.add_circle_outline_rounded,
            color: Colors.white,
            size: 28,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          onPressed: () async {
            final result = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (context) => const CreateInitiativeScreen(),
                settings: const RouteSettings(name: '/create-initiative'),
              ),
            );
            if (result == true) {
              _load();
            }
          },

        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.primaryColor,
                const Color(0xFF6366F1), // Indigo
              ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    loc.helpInitiativesHeaderTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loc.helpInitiativesHeaderSubtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, ThemeData theme) {
    final isAr = context.loc.isAr;
    final loc = context.loc;
    return Row(
      children: [
        Expanded(
          child: _StatBox(
            label: context.loc.activeVolunteers,
            value: isAr ? '١,٢٤٠' : '1,240',
            icon: Icons.volunteer_activism_rounded,
            color: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatBox(
            label: loc.casesResolved,
            value: isAr ? '٤٥٠' : '450',
            icon: Icons.task_alt_rounded,
            color: const Color(0xFF3B82F6),
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final String? iconText;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    this.icon,
    this.iconText,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? theme.primaryColor : theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? theme.primaryColor
                : theme.dividerColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: selected
                    ? Colors.white
                    : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
            ] else if (iconText != null) ...[
              Text(
                iconText!,
                style: TextStyle(
                  fontSize: 14,
                  color: selected
                      ? Colors.white
                      : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected
                    ? Colors.white
                    : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpInitiativeCard extends StatelessWidget {
  final HelpInitiative initiative;

  const _HelpInitiativeCard({required this.initiative});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = context.loc;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with category and time
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      initiative.categoryIcon,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      loc.helpCategoryDisplayName(initiative.category.name),
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                _formatTime(initiative.createdAt, loc),
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            initiative.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            initiative.description,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 12),

          // Location
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  initiative.location,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Author and participants
          Row(
            children: [
              CircleAvatar(
                backgroundColor: initiative.authorRole == 'volunteer'
                    ? const Color(0xFF10B981)
                    : Colors.orange,
                radius: 14,
                child: Text(
                  initiative.authorName[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      initiative.authorName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '${initiative.participantsCount} ${loc.participantsLabel(initiative.participantsCount)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (initiative.authorRole == 'volunteer')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    loc.volunteerLabel,
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          // Contact button
          if (initiative.contactInfo.isNotEmpty) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final contact = initiative.contactInfo.first;
                  final Uri url;
                  if (contact.contains('@')) {
                    url = Uri.parse('mailto:$contact');
                  } else {
                    url = Uri.parse(
                      'tel:${contact.replaceAll(RegExp(r'[^\d+]'), '')}',
                    );
                  }
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  loc.contactNow,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dt, AppStrings loc) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60)
      return loc.isAr
          ? 'منذ ${diff.inMinutes} دقيقة'
          : '${diff.inMinutes}m ago';
    if (diff.inHours < 24)
      return loc.isAr ? 'منذ ${diff.inHours} ساعة' : '${diff.inHours}h ago';
    return loc.isAr ? 'أمس' : 'Yesterday';
  }
}
