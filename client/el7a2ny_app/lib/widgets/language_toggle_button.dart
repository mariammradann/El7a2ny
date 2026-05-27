import 'package:flutter/material.dart';
import '../core/localization/locale_provider.dart';

class LanguageToggleButton extends StatelessWidget {
  final Color? iconColor;
  const LanguageToggleButton({super.key, this.iconColor});

  @override
  Widget build(BuildContext context) {
    final isArabic = LocaleProvider.of(context).isArabic;

    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 36),
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.language_rounded, size: 18, color: iconColor),
          const SizedBox(width: 2),
          Text(
            isArabic ? 'EN' : 'ع',
            style: TextStyle(
              fontSize: 12,
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
