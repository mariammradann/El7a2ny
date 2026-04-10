import 'package:flutter/material.dart';

import '../../widgets/emergency_dashboard_widgets.dart';

class CommunityTabPage extends StatelessWidget {
  const CommunityTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: emergencyPageBg,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: Text(
            'Community',
            style: TextStyle(
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
