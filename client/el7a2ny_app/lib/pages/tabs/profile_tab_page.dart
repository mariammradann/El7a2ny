import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../settings_screen.dart';
import '../edit_profile_screen.dart';
import '../change_password_screen.dart';

import '../../services/api_service.dart';
import '../../models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../verify_password_screen.dart';
import '../login_screen.dart';
import '../user_history_page.dart';
import '../../models/activity_history_model.dart';
import '../history_list_page.dart';
import 'package:intl/intl.dart';
import '../../services/session_service.dart';
import '../subscription_details_page.dart';
import '../premium_subscription_page.dart';
import '../../app/main_shell_screen.dart';


class ProfileTabPage extends StatefulWidget {
  const ProfileTabPage({super.key});

  @override
  State<ProfileTabPage> createState() => _ProfileTabPageState();
}

class _ProfileTabPageState extends State<ProfileTabPage> {
  UserModel? _user;
  List<ActivityHistoryModel> _history = [];
  bool _loading = true;
  String? _error;
  bool? _lastIsAr;


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
      final isAr = context.loc.isAr;
      final data = await ApiService.fetchUserProfile();
      final historyData = await ApiService.fetchActivityHistory(isArabic: isAr);

      if (mounted) {
        SessionService().initFromUser(data);
        setState(() { 
          _user = data; 
          _history = historyData;
          _loading = false; 
          _lastIsAr = isAr;
        });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = context.loc;
    final isAr = loc.isAr;

    // Refresh if language changed
    if (_lastIsAr != null && _lastIsAr != isAr && !_loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }

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
            _buildSliverHeader(context, theme, isAr),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_error != null)
                      _ErrorState(onRetry: _load)
                    else ...[
                      // 0. Subscription Plan Section
                      ListenableBuilder(
                        listenable: SessionService(),
                        builder: (context, _) {
                          final isPlus = SessionService().isPlus;
                          final isYearly = SessionService().isYearlyPlan;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _SectionHeader(
                                title: loc.subscriptionPlan, 
                                icon: Icons.stars_rounded
                              ),
                              InkWell(
                                onTap: () {
                                  if (isPlus) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const SubscriptionDetailsPage()),
                                    );
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const PremiumSubscriptionPage()),
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isPlus 
                                        ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                                        : [Colors.white, const Color(0xFFF8FAFC)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isPlus 
                                        ? const Color(0xFFFFD700).withOpacity(0.3)
                                        : Colors.grey.withOpacity(0.2)
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isPlus 
                                            ? const Color(0xFFFFD700).withOpacity(0.1)
                                            : Colors.grey.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isPlus ? Icons.workspace_premium_rounded : Icons.person_outline_rounded, 
                                          color: isPlus ? const Color(0xFFFFD700) : Colors.grey, 
                                          size: 28
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              isPlus ? (loc.isAr ? 'إلحقني بلس' : 'El7a2ny Plus') : loc.freePlan,
                                              style: TextStyle(
                                                fontFamily: 'NotoSansArabic',
                                                fontSize: 18,
                                                fontWeight: FontWeight.w900,
                                                color: isPlus ? const Color(0xFFFFD700) : const Color(0xFF0F172A),
                                              ),
                                            ),
                                            Text(
                                              isPlus 
                                                ? (isYearly 
                                                  ? '${loc.plusYearly} - ${loc.activePlanStatus}'
                                                  : '${loc.plusMonthly} - ${loc.activePlanStatus}')
                                                : loc.basicFeatures,
                                              style: TextStyle(
                                                fontFamily: 'NotoSansArabic',
                                                fontSize: 13,
                                                color: isPlus ? Colors.white.withOpacity(0.7) : Colors.grey,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios_rounded, 
                                        color: isPlus ? const Color(0xFFFFD700) : Colors.grey, 
                                        size: 16
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          );
                        },
                      ),

                      // 1. Personal Information Section
                      _SectionHeader(
                        title: loc.personalInfo,
                        icon: Icons.person_rounded,
                      ),
                      _InfoCard(
                        children: [
                          _InfoRow(
                            label: loc.firstNameLabel,
                            value: _user?.firstName ?? '...',
                            icon: Icons.badge_outlined,
                          ),
                          _InfoRow(
                            label: loc.lastNameLabel,
                            value: _user?.lastName ?? '...',
                            icon: Icons.person_outline,
                          ),
                          _InfoRow(
                            label: loc.emailLabel,
                            value: _user?.email ?? '...',
                            icon: Icons.email_outlined,
                          ),
                          _InfoRow(
                            label: loc.mobileNum,
                            value: _user?.phone ?? '...',
                            icon: Icons.phone_android_rounded,
                          ),
                          _InfoRow(
                            label: loc.nationalIdLabel,
                            value: _user?.nationalId ?? '...',
                            icon: Icons.credit_card_rounded,
                          ),
                          _InfoRow(
                            label: loc.birthDateLabel,
                            value: _user?.birthDate ?? '...',
                            icon: Icons.cake_outlined,
                          ),
                          _InfoRow(
                            label: loc.genderLabel,
                            value: _user?.gender == 'male'
                                ? loc.maleOption
                                : loc.femaleOption,
                            icon: Icons.face_outlined,
                          ),
                          _InfoRow(
                            label: loc.bloodTypeLabel,
                            value: _user?.bloodType ?? '...',
                            icon: Icons.water_drop_outlined,
                            isLast: true,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // 2. Emergency Contacts Section
                      if (_user?.emergencyContacts.isNotEmpty ?? false) ...[
                        _SectionHeader(
                          title: loc.emergencyContacts,
                          icon: Icons.contact_phone_rounded,
                        ),
                        ..._user!.emergencyContacts.map(
                          (c) => _ContactCard(
                            name: c.name,
                            relation: c.relationship,
                            phone: c.phone,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // 3. Hardware & Assets Section
                      _SectionHeader(
                        title: isAr ? 'الأجهزة والوسائل' : 'Hardwares & Assets',
                        icon: Icons.devices_other_rounded,
                      ),
                      _InfoCard(
                        children: [
                          _InfoRow(
                            label: loc.hasVehicleLabel,
                            value: _user?.hasVehicle ?? false
                                ? loc.yes
                                : loc.no,
                            icon: Icons.directions_car_outlined,
                          ),
                          _InfoRow(
                            label: loc.smartWatchLabel,
                            value:
                                _user?.smartWatchModel ??
                                (isAr ? 'غير محدد' : 'Not Set'),
                            icon: Icons.watch_outlined,
                          ),
                          _InfoRow(
                            label: loc.sensorLabel,
                            value:
                                _user?.sensorModel ??
                                (isAr ? 'غير محدد' : 'Not Set'),
                            icon: Icons.sensors_outlined,
                            isLast: true,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // 4. Volunteer Section
                      if (_user?.volunteerEnabled ?? false) ...[
                        _SectionHeader(
                          title: loc.volunteerLabel,
                          icon: Icons.volunteer_activism_rounded,
                        ),
                        _InfoCard(
                          children: [
                            _InfoRow(
                              label: isAr ? 'المهارات' : 'Skills',
                              value: _user?.skills ?? '...',
                              icon: Icons.psychology_outlined,
                              isLast: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                      


                      // 6. Account & Preferences

                      _SectionHeader(
                        title: loc.appPreferences,
                        icon: Icons.settings_rounded,
                      ),

                      _ProfileMenuTile(
                        icon: Icons.lock_outline_rounded,
                        title: loc.changePassword,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const VerifyCurrentPasswordScreen(),
                            ),

                          );
                        },
                      ),

                      _ProfileMenuTile(
                        icon: Icons.settings_outlined,
                        title: loc.settings,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          );
                        },
                      ),
                      _ProfileMenuTile(
                        icon: Icons.history_rounded,
                        title: loc.isAr ? 'سجل النشاطات' : 'Activity History',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UserHistoryPage(),
                            ),
                          );
                        },
                      ),
                      _ProfileMenuTile(
                        icon: Icons.logout_rounded,
                        title: loc.logout,
                        color: Colors.redAccent,
                        onTap: () async {
                          // إظهار Dialog تأكيد لو حابب
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(loc.logout, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'NotoSansArabic')),
                              content: Text(loc.isAr ? 'هل أنت متأكد أنك تريد تسجيل الخروج؟' : 'Are you sure you want to log out?', style: const TextStyle(fontFamily: 'NotoSansArabic')),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text(loc.isAr ? 'إلغاء' : 'Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                  child: Text(loc.logout),
                                ),
                              ],
                            ),
                          );
                          
                          if (confirm == true && mounted) {
                            await AuthRepository().logout();
                            if (mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                                (route) => false,
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverHeader(BuildContext context, ThemeData theme, bool isAr) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.primaryColor,
                    theme.primaryColor.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.scaffoldBackgroundColor,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 56,
                      backgroundColor: theme.colorScheme.surface,
                      backgroundImage: _user?.profileImageUrl != null
                          ? NetworkImage(_user!.profileImageUrl!)
                          : null,
                      child: _user?.profileImageUrl == null
                          ? Icon(
                              Icons.person,
                              color: theme.primaryColor,
                              size: 56,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 40), // Spacing for balance
                      Text(
                        _user?.name ?? '...',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          if (_user != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EditProfileScreen(user: _user!),
                              ),
                            ).then((value) => _load());
                          }
                        },
                        icon: Icon(
                          Icons.edit_rounded,
                          size: 20,
                          color: theme.primaryColor,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  if (_user?.role == 'admin')
                    Text(
                      _user?.role.toUpperCase() ?? '...',
                      style: TextStyle(
                        fontSize: 14,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final ActivityHistoryModel history;
  const _HistoryTile({required this.history});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    
    IconData icon;
    Color color;
    switch (history.type) {
      case 'emergency':
        icon = Icons.emergency_rounded;
        color = Colors.redAccent;
        break;
      case 'volunteer':
        icon = Icons.volunteer_activism_rounded;
        color = Colors.green;
        break;
      default:
        icon = Icons.info_outline_rounded;
        color = theme.primaryColor;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          history.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          history.description,
          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
        trailing: Text(
          DateFormat(isAr ? 'yyyy/MM/dd' : 'dd MMM').format(history.date),
          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {

  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: theme.primaryColor,
              letterSpacing: 0.5,
              fontFamily: 'NotoSansArabic',
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isLast;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.05),
                ),
              ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontFamily: 'NotoSansArabic',
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                    fontFamily: 'NotoSansArabic',
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

class _ContactCard extends StatelessWidget {
  final String name;
  final String relation;
  final String phone;

  const _ContactCard({
    required this.name,
    required this.relation,
    required this.phone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.emergency_rounded,
              size: 20,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    fontFamily: 'NotoSansArabic',
                  ),
                ),
                Text(
                  relation,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontFamily: 'NotoSansArabic',
                  ),
                ),
              ],
            ),
          ),
          Text(
            phone,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: theme.primaryColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, color: Colors.orange, size: 48),
          const SizedBox(height: 12),
          const Text(
            'Unable to load profile',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          TextButton(onPressed: onRetry, child: Text(context.loc.retry)),
        ],
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Color? color;

  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: isDark ? 0.05 : 0.08),
        ),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (color ?? theme.primaryColor).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color ?? theme.primaryColor, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color ?? theme.colorScheme.onSurface,
            fontFamily: 'NotoSansArabic',
          ),
        ),
        trailing: onTap != null
            ? Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              )
            : null,
      ),
    );
  }
}
