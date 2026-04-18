import 'package:flutter/material.dart';
import '../core/localization/app_strings.dart';
import '../widgets/language_toggle_button.dart';

import '../app/main_shell_screen.dart';
import 'emergency_report_screen.dart';
import 'login_screen.dart';
import 'sign_up_screen.dart';

/// Primary brand red — urgent / emergency actions.
const Color _kBrandRed = Color(0xFFE44646);

/// Light surface for the secondary card (off-white).
const Color _kCardGrey = Color(0xFFF5F5F5);

/// Body text on light backgrounds.
const Color _kTextDark = Color(0xFF424242);

class LandingScreen extends StatelessWidget {
  const LandingScreen({
    super.key,
    this.onEmergencyReport,
    this.onCreateAccount,
    this.onLogin,
  });

  final VoidCallback? onEmergencyReport;
  final VoidCallback? onCreateAccount;
  final VoidCallback? onLogin;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [LanguageToggleButton(iconColor: Colors.black54)],
                ),
                _HeaderLogo(),
                const SizedBox(height: 8),
                Text(
                  context.loc.landingAppName,
                  style: const TextStyle(
                    fontFamily: 'NotoSansArabic',
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: _kBrandRed,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.loc.landingAppDesc,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'NotoSansArabic',
                    fontSize: 15,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const MainShellScreen(),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.dashboard_rounded,
                    color: _kBrandRed,
                    size: 22,
                  ),
                  label: Text(
                    'demo',
                    style: TextStyle(
                      fontFamily: 'NotoSansArabic',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _kBrandRed,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _kBrandRed.withValues(alpha: 0.55)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _EmergencyCard(
                  onTap: onEmergencyReport ??
                      () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => const EmergencyReportScreen(),
                          ),
                        );
                      },
                ),
                const SizedBox(height: 16),
                _CreateAccountCard(
                  onTap: onCreateAccount ??
                      () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => const SignUpScreen(),
                          ),
                        );
                      },
                ),
                const SizedBox(height: 32),
                _LoginPrompt(
                  onLogin: onLogin ??
                      () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
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
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _kBrandRed, width: 3),
        color: Colors.white,
      ),
      child: Center(
        child: Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: _kBrandRed,
          ),
          child: Icon(
            Icons.priority_high_rounded,
            color: Colors.white,
            size: 38,
          ),
        ),
      ),
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  const _EmergencyCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kBrandRed,
      elevation: 4,
      shadowColor: Colors.black26,
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
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Icon(
                    Icons.priority_high_rounded,
                    color: _kBrandRed,
                    size: 36,
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
                    color: Colors.white.withValues(alpha: 0.95),
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

class _CreateAccountCard extends StatelessWidget {
  const _CreateAccountCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCardGrey,
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
                  color: _kBrandRed,
                  size: 52,
                ),
                const SizedBox(height: 14),
                Text(
                  context.loc.landingCreateAccount,
                  style: const TextStyle(
                    fontFamily: 'NotoSansArabic',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _kTextDark,
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
                    color: Colors.grey.shade700,
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
  const _LoginPrompt({required this.onLogin});

  final VoidCallback onLogin;

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
                style: const TextStyle(
                  fontFamily: 'NotoSansArabic',
                  fontSize: 15,
                  color: _kTextDark,
                ),
              ),
              Text(
                context.loc.landingLoginBtn,
                style: const TextStyle(
                  fontFamily: 'NotoSansArabic',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _kBrandRed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
