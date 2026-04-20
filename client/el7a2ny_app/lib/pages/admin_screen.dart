import 'package:flutter/material.dart';
import '../core/localization/app_strings.dart';
import '../services/session_service.dart';
import 'sponsors_page.dart';
import 'premium_subscription_page.dart';
import 'stat_card.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../models/admin_stats_model.dart';

class AdminScreen extends StatefulWidget {
  final bool isNested;
  const AdminScreen({super.key, this.isNested = false});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  AdminStats? _stats;
  List<UserModel> _users = [];
  bool _loadingStats = true;
  bool _loadingUsers = true;
  String? _statsError;
  String? _usersError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadStats();
    _loadUsers();
  }

  Future<void> _loadStats() async {
    try {
      setState(() { _loadingStats = true; _statsError = null; });
      final data = await ApiService.fetchAdminStats();
      if (mounted) setState(() { _stats = data; _loadingStats = false; });
    } catch (e) {
      if (mounted) setState(() { _statsError = e.toString(); _loadingStats = false; });
    }
  }

  Future<void> _loadUsers() async {
    try {
      setState(() { _loadingUsers = true; _usersError = null; });
      final data = await ApiService.fetchUserList();
      if (mounted) setState(() { _users = data; _loadingUsers = false; });
    } catch (e) {
      if (mounted) setState(() { _usersError = e.toString(); _loadingUsers = false; });
    }
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

    if (widget.isNested) {
      return Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: primary,
            unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            indicatorColor: primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'NotoSansArabic'),
            tabs: [
              Tab(text: loc.dashboard),
              Tab(text: loc.userManagement),
              const Tab(text: 'Resources'),
              const Tab(text: 'Admin Logs'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                RefreshIndicator(onRefresh: _loadStats, color: primary, child: _buildDashboardTab(context)),
                RefreshIndicator(onRefresh: _loadUsers, color: primary, child: _buildUsersTab(context)),
                _buildResourcesTab(context),
                _buildLogsTab(context),
              ],
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(loc.adminDashboard, style: const TextStyle(fontWeight: FontWeight.w900, fontFamily: 'NotoSansArabic')),
        bottom: TabBar(
          controller: _tabController,
          labelColor: primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
          RefreshIndicator(onRefresh: _loadStats, color: primary, child: _buildDashboardTab(context)),
          RefreshIndicator(onRefresh: _loadUsers, color: primary, child: _buildUsersTab(context)),
          _buildResourcesTab(context),
          _buildLogsTab(context),
        ],
      ),
    );
  }

  Widget _buildDashboardTab(BuildContext context) {
    final loc = context.loc;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: loc.systemHealth),
          const SizedBox(height: 16),
          if (_loadingStats)
            const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: CircularProgressIndicator()))
          else if (_statsError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('Error loading stats: $_statsError')),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: loc.totalUsers,
                    value: _stats?.totalUsers.toString() ?? '0',
                    unit: '',
                    gradientColors: const [Color(0xFF6366F1), Color(0xFF4F46E5)],
                    icon: Icons.people_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    label: loc.globalAlerts,
                    value: _stats?.activeAlerts.toString() ?? '0',
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
                    value: _stats?.avgResponseTime ?? '0:00',
                    unit: loc.minute,
                    gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
                    icon: Icons.timer_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    label: loc.successRate,
                    value: ((_stats?.successRate ?? 0.0) * 100).toInt().toString(),
                    unit: '%',
                    gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                    icon: Icons.verified_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _SectionHeader(title: 'Response Efficiency (Daily Trend)'),
            const SizedBox(height: 20),
            _CustomBarChart(values: _stats?.weeklyEfficiency ?? []),
          ],
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

    if (_loadingUsers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_usersError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text('Error: $_usersError'),
            TextButton(onPressed: _loadUsers, child: Text(loc.retry)),
          ],
        ),
      );
    }

    if (_users.isEmpty) {
      return const Center(child: Text('No users found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        return _AdminCard(
          title: user.name,
          subtitle: user.email,
          trailingText: user.role.toUpperCase(),
          statusText: user.status.toUpperCase(),
          icon: user.role == 'volunteer' ? Icons.volunteer_activism_rounded : Icons.person_rounded,
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
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.history_rounded, size: 16, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
          Text(time, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
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
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: theme.primaryColor),
            ),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Text(subtitle, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(trailingText, style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryColor)),
                Text(statusText, style: TextStyle(fontSize: 12, color: _getStatusColor(context, statusText))),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.1)),
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
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: theme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: theme.primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 13)),
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
  final List<double> values;
  const _CustomBarChart({required this.values});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<String> days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
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
                height: 130 * (index < values.length ? values[index] : 0.0),
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
              if (index < days.length)
                Text(days[index], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          );
        }),
      ),
    );
  }
}
