import 'package:flutter/material.dart';
import 'package:el7a2ny_app/core/localization/app_strings.dart';
import 'package:el7a2ny_app/widgets/language_toggle_button.dart';
import 'package:el7a2ny_app/app/main_shell_screen.dart';
import 'package:el7a2ny_app/pages/login_screen.dart';
import 'package:el7a2ny_app/pages/sign_up_screen.dart';
import 'package:el7a2ny_app/services/session_service.dart';
import 'package:el7a2ny_app/pages/emergency_report_screen.dart';
import 'package:el7a2ny_app/widgets/global_fab_overlay.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GlobalFabController.hide();
    });

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
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: 90,
                    child: Image.asset(
                      'assets/images/rr.png',
                      fit: BoxFit.contain,
                    ),
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
                _EmergencyReportCard(
                  brandRed: _kBrandRed(context),
                  onTap: () {
                    Navigator.of(context).pushNamed('/emergency-report');
                  },
                ),
                const SizedBox(height: 24),
                _CreateAccountCard(
                  cardColor: _kCardColor(context),
                  brandRed: _kBrandRed(context),
                  textColor: _kTextDark(context),
                  onTap: onCreateAccount ??
                      () {
                        Navigator.of(context).pushNamed('/signup');
                      },
                ),
                const SizedBox(height: 32),
                _LoginPrompt(
                  brandRed: _kBrandRed(context),
                  textColor: _kTextDark(context),
                  onLogin: onLogin ??
                      () {
                        Navigator.of(context).pushNamed('/login');
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
