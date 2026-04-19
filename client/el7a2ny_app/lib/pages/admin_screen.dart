import 'package:flutter/material.dart';
import '../core/localization/app_strings.dart';
import '../services/session_service.dart';
import 'sponsors_page.dart';
import 'premium_subscription_page.dart';
import 'stat_card.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock data moved into builder methods for direct localization access

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = context.loc;
    final primary = theme.primaryColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(loc.adminDashboard, style: const TextStyle(fontWeight: FontWeight.w900, fontFamily: 'NotoSansArabic')),
        bottom: TabBar(
          controller: _tabController,
          labelColor: primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.5),
          indicatorColor: primary,
          indicatorWeight: 3,
          tabs: [
            Tab(text: loc.dashboard),
            Tab(text: loc.userManagement),
            const Tab(text: 'Resources'),
            const Tab(text: 'Admin Logs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(context),
          _buildUsersTab(context),
          _buildResourcesTab(context),
          _buildLogsTab(context),
        ],
      ),
    );
  }

  Widget _buildDashboardTab(BuildContext context) {
    final loc = context.loc;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: loc.systemHealth),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: loc.totalUsers,
                  value: '1,240',
                  unit: '',
                  gradientColors: const [Color(0xFF6366F1), Color(0xFF4F46E5)],
                  icon: Icons.people_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: loc.globalAlerts,
                  value: '42',
                  unit: '',
                  gradientColors: const [Color(0xFFF43F5E), Color(0xFFE11D48)],
                  icon: Icons.notifications_active_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: loc.responseTime,
                  value: '3:45',
                  unit: loc.minute,
                  gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
                  icon: Icons.timer_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: loc.successRate,
                  value: '98',
                  unit: '%',
                  gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                  icon: Icons.verified_rounded,
                ),
              ),
            ],
          ),
          _SectionHeader(title: 'Response Efficiency (Hours)'),
          const SizedBox(height: 20),
          const _CustomBarChart(),
          const SizedBox(height: 32),
          _SectionHeader(title: 'Recent Activity Snippet'),
          const SizedBox(height: 16),
          ListenableBuilder(
            listenable: SessionService(),
            builder: (context, _) {
              final logs = SessionService().activityLog;
              if (logs.isEmpty) {
                return const Text('No recent actions recorded', style: TextStyle(color: Colors.grey, fontSize: 13));
              }
              return Column(
                children: logs.take(3).map((log) => _buildActivityItem(log, '')).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogsTab(BuildContext context) {
    return ListenableBuilder(
      listenable: SessionService(),
      builder: (context, _) {
        final logs = SessionService().activityLog;
        if (logs.isEmpty) {
          return const Center(child: Text('No activity logs yet.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: logs.length,
          itemBuilder: (context, index) {
             return _buildActivityItem(logs[index], '');
          },
        );
      },
    );
  }

  Widget _buildResourcesTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _ResourceLink(
          title: 'Sponsor Management',
          subtitle: 'Add, edit, or remove app sponsors',
          icon: Icons.handshake_rounded,
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SponsorsPage()));
          },
        ),
        const SizedBox(height: 16),
        _ResourceLink(
          title: 'Subscription Plans',
          subtitle: 'Modify pricing and premium features',
          icon: Icons.card_membership_rounded,
          onTap: () {
             Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PremiumSubscriptionPage()));
          },
        ),
        const SizedBox(height: 16),
        _ResourceLink(
          title: 'Incident Analysis',
          subtitle: 'View heatmaps and historical data',
          icon: Icons.analytics_rounded,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildUsersTab(BuildContext context) {
    final loc = context.loc;
    final List<Map<String, dynamic>> users = [
      {'name': 'Ahmed Ali', 'email': 'ahmed@example.com', 'role': loc.roleCitizen, 'status': loc.statusActiveAdmin, 'roleKey': 'Citizen'},
      {'name': 'Sara Mohamed', 'email': 'sara@example.com', 'role': loc.roleVolunteer, 'status': loc.statusPending, 'roleKey': 'Volunteer'},
      {'name': 'Khaled Omar', 'email': 'khaled@example.com', 'role': loc.roleCitizen, 'status': loc.statusActiveAdmin, 'roleKey': 'Citizen'},
      {'name': 'Mona Zayed', 'email': 'mona@example.com', 'role': loc.roleVolunteer, 'status': loc.statusSuspended, 'roleKey': 'Volunteer'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return _AdminCard(
          title: user['name'],
          subtitle: user['email'],
          trailingText: user['role'],
          statusText: user['status'],
          icon: user['roleKey'] == 'Volunteer' ? Icons.volunteer_activism_rounded : Icons.person_rounded,
          actions: [
            _AdminAction(
              label: loc.actionVerify,
              color: Colors.green,
              onTap: () => _showActionFeedback(context, loc.userVerifiedMsg),
            ),
            _AdminAction(
              label: loc.actionSuspend,
              color: Colors.red,
              onTap: () => _showActionFeedback(context, loc.userSuspendedMsg),
            ),
          ],
        );
      },
    );
  }

  void _showActionFeedback(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'NotoSansArabic')),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildActivityItem(String text, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.history_rounded, size: 16, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
          Text(time, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: Theme.of(context).colorScheme.onSurface,
        fontFamily: 'NotoSansArabic',
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String trailingText;
  final String statusText;
  final IconData icon;
  final List<_AdminAction> actions;

  const _AdminCard({
    required this.title,
    required this.subtitle,
    required this.trailingText,
    required this.statusText,
    required this.icon,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: theme.primaryColor),
            ),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Text(subtitle, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(trailingText, style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryColor)),
                Text(statusText, style: TextStyle(fontSize: 12, color: _getStatusColor(context, statusText))),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor.withOpacity(0.1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions.map((a) => _buildActionButton(context, a)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BuildContext context, String status) {
    final loc = context.loc;
    if (status == loc.statusActiveAdmin || status == loc.statusResolvedAdmin) return Colors.green;
    if (status == loc.statusPending || status == loc.statusDispatched || status == loc.statusInProgress) return Colors.orange;
    return Colors.red;
  }

  Widget _buildActionButton(BuildContext context, _AdminAction action) {
    return TextButton(
      onPressed: action.onTap,
      child: Text(
        action.label,
        style: TextStyle(color: action.color, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _AdminAction {
  final String label;
  final Color color;
  final VoidCallback onTap;
  _AdminAction({required this.label, required this.color, required this.onTap});
}

class _ResourceLink extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ResourceLink({required this.title, required this.subtitle, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: theme.primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _CustomBarChart extends StatelessWidget {
  const _CustomBarChart();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<double> values = [0.4, 0.7, 0.5, 0.9, 0.6, 0.8, 0.3];
    final List<String> days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (index) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AnimatedContainer(
                duration: const Duration(seconds: 1),
                width: 20,
                height: 130 * values[index],
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 8),
              Text(days[index], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          );
        }),
      ),
    );
  }
}
