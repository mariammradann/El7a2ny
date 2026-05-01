import 'package:flutter/material.dart';
import '../core/localization/app_strings.dart';
import '../core/localization/locale_provider.dart';
import '../app/main_shell_screen.dart';

class PasswordChangeSuccessScreen extends StatelessWidget {
  const PasswordChangeSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryRed = theme.primaryColor;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withValues(alpha: 0.1),
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 64,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                context.loc.passwordChangedSuccess,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'NotoSansArabic',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppConfigProvider.of(context).isArabic ? "تم تغيير كلمة المرور بنجاح. يمكنك الآن العودة إلى الصفحة الرئيسية." : "Password changed successfully. You can now return to the home page.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'NotoSansArabic',
                  fontSize: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute<void>(
                        builder: (context) => MainShellScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    AppConfigProvider.of(context).isArabic ? "العودة للرئيسية" : "Return to Home",
                    style: const TextStyle(
                      fontFamily: 'NotoSansArabic',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
