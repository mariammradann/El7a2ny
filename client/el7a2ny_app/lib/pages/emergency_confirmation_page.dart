import 'package:flutter/material.dart';
import '../core/localization/app_strings.dart';

class EmergencyConfirmationPage extends StatefulWidget {
  const EmergencyConfirmationPage({super.key});

  @override
  State<EmergencyConfirmationPage> createState() => _EmergencyConfirmationPageState();
}

class _EmergencyConfirmationPageState extends State<EmergencyConfirmationPage> with SingleTickerProviderStateMixin {
  late AnimationController _checkCtrl;
  late Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _checkCtrl = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    _checkScale = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut));
    _checkCtrl.forward();
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;

    return Scaffold(
      backgroundColor: const Color(0xFFDC2626), // Emergency red
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            
            // Success Indicator
            ScaleTransition(
              scale: _checkScale,
              child: Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981), // Success green
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 80),
              ),
            ),

            const SizedBox(height: 32),

            Text(
              loc.isAr ? 'المساعدة في الطريق' : 'Help is on the Way',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                fontFamily: 'NotoSansArabic',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loc.isAr ? 'خدمات الطوارىء في طريقها لموقعك' : 'Emergency services are en route to your location',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'NotoSansArabic',
              ),
            ),

            const Spacer(),

            // Help Details Card
            Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   _buildInfoRow(
                    label: loc.isAr ? 'تفاصيل الاستجابة :' : 'Response Details:',
                    value: loc.isAr ? 'سيارة إسعاف' : 'Ambulance',
                    isTitle: true,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    label: loc.isAr ? 'بيوصل في :' : 'Estimated Arrival:',
                    value: loc.isAr ? '8 دقائق' : '8 minutes',
                    valueColor: const Color(0xFFFFD700),
                  ),
                  _buildInfoRow(
                    label: loc.isAr ? 'أقرب مستشفى :' : 'Nearest Hospital:',
                    value: loc.isAr ? 'مركز القاهرة الطبي' : 'Cairo Medical Center',
                  ),
                   _buildInfoRow(
                    label: loc.isAr ? 'رقم البلاغ :' : 'Incident ID:',
                    value: 'EMS-23492',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(
                    loc.isAr ? 'العودة للرئيسية' : 'Back to Home',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontFamily: 'NotoSansArabic'),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({required String label, required String value, Color valueColor = Colors.white, bool isTitle = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isTitle) ...[
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'NotoSansArabic')),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'NotoSansArabic')),
          ] else ...[
             Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'NotoSansArabic')),
                Text(value, style: TextStyle(color: valueColor, fontSize: 15, fontWeight: FontWeight.w900, fontFamily: 'NotoSansArabic')),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
