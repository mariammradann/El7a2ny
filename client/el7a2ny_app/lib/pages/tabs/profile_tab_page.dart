import 'package:flutter/material.dart';

import '../../widgets/emergency_dashboard_widgets.dart';
import '../../core/localization/app_strings.dart';

class ProfileTabPage extends StatelessWidget {
  const ProfileTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: emergencyPageBg,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: Text(
            context.loc.tabProfile,
            style: const TextStyle(
              fontFamily: 'NotoSansArabic',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: emergencyTextDark,
            ),
          ),
        ),
      ),
    );
  }
}
