import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';

class CommunityTabPage extends StatelessWidget {
  const CommunityTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAr = context.loc.isAr;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, theme, isAr),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildStatsGrid(context, theme),
                const SizedBox(height: 28),
                _SectionTitle(title: context.loc.communityPosts),
                const SizedBox(height: 16),
                _CommunityPostCard(
                  name: isAr ? 'أحمد كمال' : 'Ahmed Kamal',
                  time: isAr ? 'منذ ١٠ دقائق' : '10m ago',
                  content: isAr 
                      ? 'شكراً جداً للمسعفين اللي ساعدوا في حادثة طريق الجلاء النهاردة. الاستجابة كانت سريعة جداً.' 
                      : 'Big thanks to the paramedics who helped at the El Galaa road accident today. Response was very fast.',
                  isVolunteer: true,
                ),
                const SizedBox(height: 16),
                _CommunityPostCard(
                  name: isAr ? 'منى السيد' : 'Mona El-Sayed',
                  time: isAr ? 'منذ ساعة' : '1h ago',
                  content: isAr 
                      ? 'متاح أجهزة أكسجين للمساعدة في حالات الطوارئ بمنطقة المعادي. اللي محتاج يتواصل معايا.' 
                      : 'Oxygen concentrators available for emergency help in Maadi area. Contact me if needed.',
                  isVolunteer: false,
                  hasAction: true,
                ),
                const SizedBox(height: 16),
                _CommunityPostCard(
                  name: isAr ? 'نظام إلحقني' : 'El7a2ny System',
                  time: isAr ? 'أمس' : 'Yesterday',
                  content: isAr 
                      ? 'تم تحديث خريطة وحدات الإسعاف لتشمل المناطق الجديدة في التجمع الخامس.' 
                      : 'Ambulance unit map updated to include new areas in the 5th Settlement.',
                  isSystem: true,
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context, ThemeData theme, bool isAr) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: theme.primaryColor,
      automaticallyImplyLeading: false,
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
                    context.loc.communityTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.loc.communityDesc,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
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
            label: isAr ? 'حالات تم حلها' : 'Cases Resolved',
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
        border: Border.all(color: color.withOpacity(0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
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
              color: color.withOpacity(0.1),
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
              color: theme.colorScheme.onSurface.withOpacity(0.6),
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

class _CommunityPostCard extends StatelessWidget {
  final String name;
  final String time;
  final String content;
  final bool isVolunteer;
  final bool isSystem;
  final bool hasAction;

  const _CommunityPostCard({
    required this.name,
    required this.time,
    required this.content,
    this.isVolunteer = false,
    this.isSystem = false,
    this.hasAction = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: isSystem ? theme.primaryColor : (isVolunteer ? const Color(0xFF10B981) : Colors.orange),
                radius: 18,
                child: Icon(
                  isSystem ? Icons.notifications_active : (isVolunteer ? Icons.person : Icons.person_outline),
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              if (isVolunteer)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'متطوع',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: theme.colorScheme.onSurface.withOpacity(0.85),
            ),
          ),
          if (hasAction) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: theme.primaryColor),
                ),
                child: Text(
                  context.loc.isAr ? 'تواصل الآن' : 'Contact Now',
                  style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryColor),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
