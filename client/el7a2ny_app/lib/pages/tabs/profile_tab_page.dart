import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../settings_screen.dart';
import '../../services/api_service.dart';
import '../../models/user_model.dart';

class ProfileTabPage extends StatefulWidget {
  const ProfileTabPage({super.key});

  @override
  State<ProfileTabPage> createState() => _ProfileTabPageState();
}

class _ProfileTabPageState extends State<ProfileTabPage> {
  UserModel? _user;
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
      final data = await ApiService.fetchUserProfile();
      if (mounted) setState(() { _user = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAr = context.loc.isAr;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _load,
        color: theme.primaryColor,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            _buildSliverHeader(context, theme, isAr),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_loading)
                      const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: CircularProgressIndicator()))
                    else if (_error != null)
                      _ErrorState(onRetry: _load)
                    else ...[
                      _SectionTitle(title: context.loc.personalInfo),
                      const SizedBox(height: 12),
                      _ProfileMenuTile(
                        icon: Icons.person_outline_rounded,
                        title: isAr ? 'تعديل الملف الشخصي' : 'Edit Profile',
                        onTap: () {},
                      ),
                      _ProfileMenuTile(
                        icon: Icons.email_outlined,
                        title: context.loc.emailLabel,
                        subtitle: _user?.email ?? '...',
                        isDetail: true,
                      ),
                      _ProfileMenuTile(
                        icon: Icons.phone_android_rounded,
                        title: isAr ? 'رقم الهاتف' : 'Phone Number',
                        subtitle: _user?.phone ?? '...',
                        isDetail: true,
                      ),
                      const SizedBox(height: 24),
                      _SectionTitle(title: context.loc.securitySettings),
                      const SizedBox(height: 12),
                      _ProfileMenuTile(
                        icon: Icons.lock_outline_rounded,
                        title: context.loc.changePassword,
                        onTap: () {},
                      ),
                      _ProfileMenuTile(
                        icon: Icons.fingerprint_rounded,
                        title: isAr ? 'بصمة الإصبع' : 'Biometrics',
                        trailing: CupertinoSwitch(
                            value: true,
                            activeColor: theme.primaryColor,
                            onChanged: (v) {}
                        ),
                      ),
                      const SizedBox(height: 24),
                      _SectionTitle(title: context.loc.appPreferences),
                      const SizedBox(height: 12),
                      _ProfileMenuTile(
                        icon: Icons.settings_outlined,
                        title: context.loc.settings,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          );
                        },
                      ),
                      _ProfileMenuTile(
                        icon: Icons.language_rounded,
                        title: context.loc.language,
                        subtitle: context.loc.arabicOrEnglish,
                      ),
                      const SizedBox(height: 32),
                      _ProfileMenuTile(
                        icon: Icons.logout_rounded,
                        title: context.loc.logout,
                        color: Colors.redAccent,
                        onTap: () {},
                      ),
                    ],
                    const SizedBox(height: 40),
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
                  colors: [theme.primaryColor, theme.primaryColor.withValues(alpha: 0.7)],
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
                      border: Border.all(color: theme.scaffoldBackgroundColor, width: 4),
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
                      backgroundImage: _user?.profileImageUrl != null ? NetworkImage(_user!.profileImageUrl!) : null,
                      child: _user?.profileImageUrl == null ? Icon(Icons.person, color: theme.primaryColor, size: 56) : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _user?.name ?? '...',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    _user?.role.toUpperCase() ?? '...',
                    style: TextStyle(
                      fontSize: 14,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
          const Text('Unable to load profile', style: TextStyle(fontWeight: FontWeight.bold)),
          TextButton(onPressed: onRetry, child: Text(context.loc.retry)),
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
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: Theme.of(context).primaryColor,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? color;
  final bool isDetail;

  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.color,
    this.isDetail = false,
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
        border: Border.all(color: theme.dividerColor.withValues(alpha: isDark ? 0.05 : 0.08)),
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
          ),
        ),
        subtitle: subtitle != null ? Text(
          subtitle!,
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ) : null,
        trailing: trailing ?? (onTap != null && !isDetail ? Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)) : null),
      ),
    );
  }
}

class CupertinoSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  const CupertinoSwitch({
    super.key, 
    required this.value, 
    required this.onChanged, 
    required this.activeColor
  });

  @override
  Widget build(BuildContext context) {
    return Switch.adaptive(
      value: value,
      onChanged: onChanged,
      activeTrackColor: activeColor,
    );
  }
}
