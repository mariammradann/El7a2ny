import 'package:flutter/material.dart';

import '../../widgets/emergency_dashboard_widgets.dart';
import '../emergency_report_screen.dart';

/// تبويب الاستغاثة — نقطة دخول سريعة لبلاغ الطوارئ.
class IstighathaTabPage extends StatelessWidget {
  const IstighathaTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: emergencyPageBg,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emergency_share_rounded, size: 64, color: emergencyTitleRed),
                const SizedBox(height: 16),
                Text(
                  'استغاثة',
                  style: TextStyle(
                    fontFamily: 'Unixel',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: emergencyTextDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'أرسل بلاغ طوارئ بسرعة',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Unixel',
                    fontSize: 15,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => const EmergencyReportScreen(),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: emergencyTitleRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'بلاغ طوارئ',
                      style: TextStyle(
                        fontFamily: 'Unixel',
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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
