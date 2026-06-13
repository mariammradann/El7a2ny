// lib/pages/admin_profile_page.dart
import 'package:flutter/material.dart';
import 'package:el7a2ny_app/models/admin_profile_model.dart';
import 'package:el7a2ny_app/services/admin_profile_service.dart';

class AdminProfilePage extends StatefulWidget {
  final String adminId;
  const AdminProfilePage({Key? key, required this.adminId}) : super(key: key);

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  late Future<AdminProfile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = AdminProfileService.fetchProfile(widget.adminId);
  }

  void _refresh() {
    setState(() {
      _profileFuture = AdminProfileService.fetchProfile(widget.adminId);
    });
  }

  // ── DESIGN SYSTEM GETTERS ──────────────────────────────────────────────────
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _pageBg => _isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
  Color get _cardBg => _isDark ? const Color(0xFF1E293B) : Colors.white;
  Color get _borderColor => _isDark ? const Color(0xFF334155).withOpacity(0.6) : const Color(0xFFE2E8F0);
  Color get _textMain => _isDark ? Colors.white : const Color(0xFF0F172A);
  Color get _textSub => _isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF475569);
  Color get _textMuted => _isDark ? Colors.white.withOpacity(0.4) : const Color(0xFF94A3B8);
  Color get _accentColor => const Color(0xFFE11D48);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _cardBg,
        elevation: 0,
        titleSpacing: 24,
        iconTheme: IconThemeData(color: _textMain),
        title: Text(
          'El7a2ny Plus - Admin Dashboard',
          style: TextStyle(
            color: _textMain,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            fontFamily: 'NotoSansArabic',
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(
                    'https://i.pravatar.cc/150?img=47',
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {},
                  icon: Text(
                    'Profile',
                    style: TextStyle(
                      color: _textMain,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'NotoSansArabic',
                    ),
                  ),
                  label: Icon(
                    Icons.arrow_drop_down,
                    color: _textMain,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        color: _accentColor,
        child: FutureBuilder<AdminProfile>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFE11D48)));
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(color: _textSub, fontFamily: 'NotoSansArabic'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _refresh,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            final profile = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Row 1: Info card + Quick Actions ──────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left: Admin Info & Security
                      Expanded(
                        flex: 3,
                        child: _InfoSecurityCard(
                          profile: profile,
                          cardBg: _cardBg,
                          borderColor: _borderColor,
                          textMain: _textMain,
                          textSub: _textSub,
                          textMuted: _textMuted,
                          isDark: _isDark,
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Right: Quick Actions Panel
                      SizedBox(
                        width: 240,
                        child: _QuickActionsPanel(
                          cardBg: _cardBg,
                          borderColor: _borderColor,
                          textMain: _textMain,
                          textSub: _textSub,
                          isDark: _isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Row 2: Quick Statistics ────────────────────────────────
                  _SectionTitle(title: 'Quick Statistics', textMain: _textMain),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _StatCard(
                        title: 'Total Users Managed',
                        value: '${profile.totalUsers}+',
                        icon: Icons.people_alt_rounded,
                        color: _isDark ? const Color(0xFF1E3A8A).withOpacity(0.2) : const Color(0xFFEFF6FF),
                        iconColor: const Color(0xFF3B82F6),
                        borderColor: _isDark ? const Color(0xFF2563EB).withOpacity(0.3) : const Color(0xFFDBEAFE),
                        textMain: _textMain,
                        textSub: _textSub,
                      ),
                      const SizedBox(width: 16),
                      _StatCard(
                        title: 'Total Actions Taken Today',
                        value: '${profile.actionsToday}',
                        icon: Icons.assignment_turned_in_rounded,
                        color: _isDark ? const Color(0xFF581C87).withOpacity(0.2) : const Color(0xFFFAF5FF),
                        iconColor: const Color(0xFFA855F7),
                        borderColor: _isDark ? const Color(0xFF7C3AED).withOpacity(0.3) : const Color(0xFFF3E8FF),
                        textMain: _textMain,
                        textSub: _textSub,
                      ),
                      const SizedBox(width: 16),
                      _StatCard(
                        title: 'Pending Requests & Reports',
                        value: '${profile.pendingRequests + profile.emergencyReports}',
                        icon: Icons.notifications_active_rounded,
                        color: _isDark ? const Color(0xFF7F1D1D).withOpacity(0.2) : const Color(0xFFFEF2F2),
                        iconColor: const Color(0xFFEF4444),
                        borderColor: _isDark ? const Color(0xFFDC2626).withOpacity(0.3) : const Color(0xFFFEE2E2),
                        textMain: _textMain,
                        textSub: _textSub,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Row 3: Audit Log ───────────────────────────────────────
                  _SectionTitle(title: 'Admin Activity / Audit Log', textMain: _textMain),
                  const SizedBox(height: 12),
                  _AuditLogTable(
                    actions: profile.recentActions,
                    cardBg: _cardBg,
                    borderColor: _borderColor,
                    textMain: _textMain,
                    textSub: _textSub,
                    textMuted: _textMuted,
                    isDark: _isDark,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Admin Info & Security Card ───────────────────────────────────────────────
class _InfoSecurityCard extends StatelessWidget {
  final AdminProfile profile;
  final Color cardBg;
  final Color borderColor;
  final Color textMain;
  final Color textSub;
  final Color textMuted;
  final bool isDark;

  const _InfoSecurityCard({
    required this.profile,
    required this.cardBg,
    required this.borderColor,
    required this.textMain,
    required this.textSub,
    required this.textMuted,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar with Online badge
          Column(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundImage: profile.avatarUrl.isNotEmpty
                        ? NetworkImage(profile.avatarUrl)
                        : const NetworkImage('https://i.pravatar.cc/150?img=47'),
                    backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: profile.isOnline ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(color: cardBg, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 10,
                    color: profile.isOnline ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    profile.isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontSize: 13,
                      color: profile.isOnline ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'NotoSansArabic',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 24),

          // Info details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Information & Security',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textMuted,
                    fontFamily: 'NotoSansArabic',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.fullName,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: textMain,
                    fontFamily: 'NotoSansArabic',
                  ),
                ),
                const SizedBox(height: 16),
                _InfoRow(label: 'Admin ID:', value: profile.adminId, textMain: textMain, textSub: textSub),
                _InfoRow(
                  label: 'Contact:',
                  value: '${profile.email} | ${profile.phone}',
                  textMain: textMain,
                  textSub: textSub,
                ),
                _InfoRow(label: 'Address:', value: profile.address, textMain: textMain, textSub: textSub),
                const SizedBox(height: 20),
                Text(
                  'Security Settings',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: textMain,
                    fontFamily: 'NotoSansArabic',
                  ),
                ),
                const SizedBox(height: 8),
                _InfoRow(label: 'Role:', value: profile.roleLevel, textMain: textMain, textSub: textSub),
                _InfoRow(
                  label: '2FA Status:',
                  value: profile.twoFactorEnabled
                      ? 'Enabled (Google Authenticator)'
                      : 'Disabled',
                  textMain: textMain,
                  textSub: textSub,
                ),
                _InfoRow(label: 'Last Login:', value: profile.lastLogin, textMain: textMain, textSub: textSub),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color textMain;
  final Color textSub;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.textMain,
    required this.textSub,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: textMain,
                fontSize: 13,
                fontFamily: 'NotoSansArabic',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: textSub,
                fontSize: 13,
                fontFamily: 'NotoSansArabic',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick Actions Panel ───────────────────────────────────────────────────────
class _QuickActionsPanel extends StatelessWidget {
  final Color cardBg;
  final Color borderColor;
  final Color textMain;
  final Color textSub;
  final bool isDark;

  const _QuickActionsPanel({
    required this.cardBg,
    required this.borderColor,
    required this.textMain,
    required this.textSub,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions Panel',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: textMain,
              fontFamily: 'NotoSansArabic',
            ),
          ),
          const SizedBox(height: 16),
          _ActionButton(
            icon: Icons.add_rounded,
            label: 'Add New User',
            onTap: () {},
            isDark: isDark,
            textMain: textMain,
          ),
          const SizedBox(height: 12),
          _ActionButton(
            icon: Icons.download_rounded,
            label: 'Export Activity Log',
            onTap: () {},
            isDark: isDark,
            textMain: textMain,
          ),
          const SizedBox(height: 12),
          _ActionButton(
            icon: Icons.settings_rounded,
            label: 'System Settings',
            onTap: () {},
            isDark: isDark,
            textMain: textMain,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final Color textMain;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    required this.textMain,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: const Color(0xFFE11D48)),
        label: Text(
          label,
          style: TextStyle(
            color: textMain, 
            fontSize: 13, 
            fontWeight: FontWeight.w700,
            fontFamily: 'NotoSansArabic',
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          side: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFF3E8FF),
          ),
          backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFF5F5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }
}

// ─── Stat Card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color iconColor;
  final Color borderColor;
  final Color textMain;
  final Color textSub;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.borderColor,
    required this.textMain,
    required this.textSub,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: textSub,
                      fontFamily: 'NotoSansArabic',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: textMain,
                      fontFamily: 'NotoSansArabic',
                    ),
                  ),
                ],
              ),
            ),
            Icon(icon, size: 36, color: iconColor),
          ],
        ),
      ),
    );
  }
}

// ─── Section Title ─────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  final Color textMain;

  const _SectionTitle({required this.title, required this.textMain});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: textMain,
        fontFamily: 'NotoSansArabic',
      ),
    );
  }
}

// ─── Audit Log Table ───────────────────────────────────────────────────────────
class _AuditLogTable extends StatelessWidget {
  final List<RecentAction> actions;
  final Color cardBg;
  final Color borderColor;
  final Color textMain;
  final Color textSub;
  final Color textMuted;
  final bool isDark;

  const _AuditLogTable({
    required this.actions,
    required this.cardBg,
    required this.borderColor,
    required this.textMain,
    required this.textSub,
    required this.textMuted,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Last Actions',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: textMain,
                fontFamily: 'NotoSansArabic',
              ),
            ),
          ),
          // Header row
          Container(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Date/Time',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: textMain,
                      fontFamily: 'NotoSansArabic',
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Action Taken',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: textMain,
                      fontFamily: 'NotoSansArabic',
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Target User ID/Name',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: textMain,
                      fontFamily: 'NotoSansArabic',
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),
          // Data rows
          if (actions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'No recent actions.',
                style: TextStyle(color: textMuted, fontFamily: 'NotoSansArabic'),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: actions.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: borderColor),
              itemBuilder: (context, index) {
                final act = actions[index];
                final parts = act.action.split('|');
                final actionText = parts.isNotEmpty ? parts[0].trim() : act.action;
                final targetText = parts.length > 1 ? parts[1].trim() : '—';
                return Container(
                  color: index.isEven
                      ? cardBg
                      : (isDark ? const Color(0xFF1E293B).withOpacity(0.5) : const Color(0xFFF8FAFC)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          act.timestamp,
                          style: TextStyle(
                            fontSize: 13,
                            color: textSub,
                            fontFamily: 'NotoSansArabic',
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          actionText,
                          style: TextStyle(
                            fontSize: 13,
                            color: textMain,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'NotoSansArabic',
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          targetText,
                          style: TextStyle(
                            fontSize: 13,
                            color: textMain,
                            fontFamily: 'NotoSansArabic',
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
