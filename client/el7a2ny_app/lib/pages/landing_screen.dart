import 'package:flutter/material.dart';
import 'package:el7a2ny_app/core/localization/app_strings.dart';
import 'package:el7a2ny_app/widgets/language_toggle_button.dart';
import 'package:el7a2ny_app/app/main_shell_screen.dart';
import 'package:el7a2ny_app/pages/login_screen.dart';
import 'package:el7a2ny_app/pages/sign_up_screen.dart';
import 'package:el7a2ny_app/services/session_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../core/auth/auth_token_store.dart'; // تأكد من صحة المسار حسب مشروعك

class LandingScreen extends StatelessWidget {
  const LandingScreen({
    super.key,
    this.onCreateAccount,
    this.onLogin,
  });

  final VoidCallback? onCreateAccount;
  final VoidCallback? onLogin;

  Color _kBrandRed(BuildContext context) => Theme.of(context).primaryColor;
  Color _kCardColor(BuildContext context) => Theme.of(context).colorScheme.surfaceContainerHighest;
  Color _kTextDark(BuildContext context) => Theme.of(context).colorScheme.onSurface;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [LanguageToggleButton(iconColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))],
                ),
                _HeaderLogo(brandRed: _kBrandRed(context)),
                const SizedBox(height: 8),
                Text(
                  context.loc.landingAppName,
                  style: TextStyle(
                    fontFamily: 'NotoSansArabic',
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: _kBrandRed(context),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.loc.landingAppDesc,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'NotoSansArabic',
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        SessionService().setRole(UserRole.citizen);
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => const MainShellScreen(),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.dashboard_rounded,
                        color: _kBrandRed(context),
                        size: 20,
                      ),
                      label: const Text(
                        'demo',
                        style: TextStyle(
                          fontFamily: 'NotoSansArabic',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kBrandRed(context),
                        side: BorderSide(color: _kBrandRed(context).withValues(alpha: 0.4)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        SessionService().setRole(UserRole.admin);
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => const MainShellScreen(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.admin_panel_settings_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: Text(
                        context.loc.adminAuthTitle,
                        style: const TextStyle(
                          fontFamily: 'NotoSansArabic',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kBrandRed(context),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _EmergencyReportCard(
                  brandRed: _kBrandRed(context),
                  onTap: () async {
                    // 1. Show feedback
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.loc.isAr ? 'بدء إجراءات الاستغاثة الفورية...' : 'Initiating instant SOS...'),
                        backgroundColor: Colors.red,
                      ),
                    );

                    // 2. Send location
                    try {
                      final pos = await Geolocator.getCurrentPosition();
                      await ApiService.sendEmergencyAlert(
                        userId: AuthTokenStore.userId ?? 'guest',
                        type: 'instant_sos_landing',
                        lat: pos.latitude,
                        lng: pos.longitude,
                        description: 'Instant SOS triggered from landing screen',
                      );
                    } catch (_) {}

                    // 3. Fetch contacts
                    UserModel? user;
                    try {
                      user = await ApiService.fetchUserProfile();
                    } catch (_) {}

                    // 4. Official calls
                    final officials = ['122', '123', '180'];
                    for (var num in officials) {
                      bool? res = await FlutterPhoneDirectCaller.callNumber(num);
                      if (res == true) await Future.delayed(const Duration(seconds: 10));
                    }

                    // 5. Emergency contacts
                    if (user != null && user.emergencyContacts.isNotEmpty) {
                      for (var contact in user.emergencyContacts) {
                        bool? res = await FlutterPhoneDirectCaller.callNumber(contact.phone);
                        if (res == true) await Future.delayed(const Duration(seconds: 10));
                      }
                    }
                  },
                ),
                const SizedBox(height: 24),
                _CreateAccountCard(
                  cardColor: _kCardColor(context),
                  brandRed: _kBrandRed(context),
                  textColor: _kTextDark(context),
                  onTap: onCreateAccount ??
                      () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            settings: const RouteSettings(name: '/signup'),
                            builder: (context) => SignUpScreen(),
                          ),
                        );
                      },
                ),
                const SizedBox(height: 32),
                _LoginPrompt(
                  brandRed: _kBrandRed(context),
                  textColor: _kTextDark(context),
                  onLogin: onLogin ??
                      () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            settings: const RouteSettings(name: '/login'),
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderLogo extends StatelessWidget {
  final Color brandRed;
  const _HeaderLogo({required this.brandRed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: brandRed, width: 3),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Center(
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: brandRed,
          ),
          child: const Icon(
            Icons.priority_high_rounded,
            color: Colors.white,
            size: 38,
          ),
        ),
      ),
    );
  }
}


class _CreateAccountCard extends StatelessWidget {
  const _CreateAccountCard({
    required this.onTap,
    required this.cardColor,
    required this.brandRed,
    required this.textColor,
  });

  final VoidCallback onTap;
  final Color cardColor;
  final Color brandRed;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cardColor,
      elevation: 3,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person_add_alt_1_outlined,
                  color: brandRed,
                  size: 52,
                ),
                const SizedBox(height: 14),
                Text(
                  context.loc.landingCreateAccount,
                  style: TextStyle(
                    fontFamily: 'NotoSansArabic',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.loc.landingCreateAccountDesc,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'NotoSansArabic',
                    fontSize: 14,
                    height: 1.35,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt({required this.onLogin, required this.brandRed, required this.textColor});

  final VoidCallback onLogin;
  final Color brandRed;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onLogin,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.loc.landingHaveAccount,
                style: TextStyle(
                  fontFamily: 'NotoSansArabic',
                  fontSize: 15,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                context.loc.landingLoginBtn,
                style: TextStyle(
                  fontFamily: 'NotoSansArabic',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: brandRed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergencyReportCard extends StatelessWidget {
  const _EmergencyReportCard({required this.onTap, required this.brandRed});
  final VoidCallback onTap;
  final Color brandRed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: brandRed,
      elevation: 4,
      shadowColor: brandRed.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emergency_share_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  context.loc.landingEmergency,
                  style: const TextStyle(
                    fontFamily: 'NotoSansArabic',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.loc.landingEmergencyDesc,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'NotoSansArabic',
                    fontSize: 14,
                    height: 1.35,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
