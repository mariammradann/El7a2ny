import 'dart:async';
import 'package:flutter/material.dart';
import '../data/repositories/auth_repository.dart';
import '../core/localization/app_strings.dart';
import '../widgets/global_fab_overlay.dart';

class BannedScreen extends StatefulWidget {
  final DateTime bannedUntil;

  const BannedScreen({
    super.key,
    required this.bannedUntil,
  });

  @override
  State<BannedScreen> createState() => _BannedScreenState();
}

class _BannedScreenState extends State<BannedScreen> with SingleTickerProviderStateMixin {
  late Timer _timer;
  late Duration _remaining;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _calculateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateRemaining();
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  void _calculateRemaining() {
    final now = DateTime.now();
    if (widget.bannedUntil.isBefore(now)) {
      _remaining = Duration.zero;
      _timer.cancel();
      // Auto-navigate to landing or home since ban expired
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleLogout();
      });
    } else {
      setState(() {
        _remaining = widget.bannedUntil.difference(now);
      });
    }
  }

  Future<void> _handleLogout() async {
    _timer.cancel();
    await AuthRepository().logout();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/landing',
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    final isAr = context.loc.isAr;
    if (isAr) {
      return '$days يوم و $hours ساعة و $minutes دقيقة و $seconds ثانية';
    } else {
      return '$days d $hours h $minutes m $seconds s';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Force hide floating action button on banned screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GlobalFabController.hide();
    });

    final theme = Theme.of(context);
    final isAr = context.loc.isAr;

    return PopScope(
      canPop: false, // Prevent physical back navigation
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A), // Premium dark mode background
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Glowing/pulsing warning icon
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFE61717).withOpacity(0.1 + (_pulseController.value * 0.1)),
                            border: Border.all(
                              color: const Color(0xFFE61717).withOpacity(0.3 + (_pulseController.value * 0.3)),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE61717).withOpacity(0.2 * _pulseController.value),
                                blurRadius: 20,
                                spreadRadius: 5,
                              )
                            ],
                          ),
                          child: const Icon(
                            Icons.gavel_rounded,
                            size: 80,
                            color: Color(0xFFE61717),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 40),

                    // Main title
                    Text(
                      isAr ? 'تم حظر الحساب مؤقتاً' : 'Account Temporarily Banned',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'NotoSansArabic',
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Descriptive message
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            isAr
                                ? 'تم إلغاء بلاغك الأخير من قِبل المتطوعين لكونه كاذباً. مخالفتك أدت إلى حظر حسابك لمدة ٣ أيام.'
                                : 'Your recent emergency report was flagged and cancelled as fake. This violation has resulted in a 3-day account ban.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'NotoSansArabic',
                              fontSize: 15,
                              height: 1.5,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Divider(color: Colors.white.withOpacity(0.1)),
                          const SizedBox(height: 16),
                          Text(
                            isAr ? 'متبقي على إزالة الحظر:' : 'Time remaining until unban:',
                            style: TextStyle(
                              fontFamily: 'NotoSansArabic',
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatDuration(_remaining),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'NotoSansArabic',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF18F34), // Premium orange/yellow
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Logout / exit action
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: _handleLogout,
                        icon: const Icon(Icons.logout_rounded, color: Color(0xFFE61717)),
                        label: Text(
                          isAr ? 'تسجيل الخروج' : 'Logout / Switch Account',
                          style: const TextStyle(
                            fontFamily: 'NotoSansArabic',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE61717),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE61717), width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
