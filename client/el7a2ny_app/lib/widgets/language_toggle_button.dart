import 'package:flutter/material.dart';
import '../core/localization/locale_provider.dart';

class LanguageToggleButton extends StatelessWidget {
  final Color? iconColor;
  const LanguageToggleButton({super.key, this.iconColor});

  @override
  Widget build(BuildContext context) {
    final isArabic = LocaleProvider.of(context).isArabic;

    return IconButton(
      tooltip: isArabic ? 'English' : 'العربية',
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.language_rounded, size: 20, color: iconColor),
          const SizedBox(width: 4),
          Text(
            isArabic ? 'EN' : 'ع',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
        ],
      ),
      onPressed: () {
        AppConfigProvider.of(context).toggleLanguage();
      },
    );
  }
}
