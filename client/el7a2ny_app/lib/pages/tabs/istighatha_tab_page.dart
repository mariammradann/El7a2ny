import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vibration/vibration.dart';
import '../../core/localization/app_strings.dart';
import '../../app/main_shell_screen.dart';
import '../../core/auth/auth_token_store.dart';
import '../report_incident_page.dart'; // تأكد أن المسار صحيح

class IstighathaTabPage extends StatefulWidget {
  final VoidCallback? onProfileTap;
  const IstighathaTabPage({super.key, this.onProfileTap});

  @override
  State<IstighathaTabPage> createState() => _IstighathaTabPageState();
}

class _IstighathaTabPageState extends State<IstighathaTabPage> with SingleTickerProviderStateMixin {
  bool _isVibrationEnabled = true;
  bool _isLocating = false; // لتوضيح حالة جلب الموقع
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleSOS() async {
    if (_isLocating) return;

    if (_isVibrationEnabled) {
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(duration: 500);
      }
    }

    setState(() => _isLocating = true);

    try {
      // 1. جلب الموقع الحالي بدقة عالية
      Position position = await _determinePosition();

      if (mounted) {
        // 2. الانتقال لصفحة التقارير وتمرير البيانات المطلوبة
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReportIncidentPage(
              userId: AuthTokenStore.userId ?? '',
              latitude: position.latitude,
              longitude: position.longitude,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services are disabled.');
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return Future.error('Location permissions are denied');
    }
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
                    _buildHeader(isDark, theme),
                    const SizedBox(height: 20),
                    _buildMotivationalText(),
                    const SizedBox(height: 100),
                    _buildSOSButton(),
                    const SizedBox(height: 100),
                    _buildVibrationToggle(isDark, theme),
            ],
          ),
        ),
      ),
    );
  }

  // الدوال المساعدة (UI) تبقى كما هي في كودك الأصلي
  Widget _buildHeader(bool isDark, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 40),
          Text(context.loc.tabIstighatha, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          GestureDetector(
            onTap: widget.onProfileTap,
            child: const CircleAvatar(radius: 20, child: Icon(Icons.person)),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationalText() {
    return Column(
      children: [
        Text(context.loc.weGotYourBack, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        Text(context.loc.pressSOSDesc, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
      ],
    );
  }

  Widget _buildSOSButton() {
    return GestureDetector(
      onTap: _handleSOS,
      child: ScaleTransition(
        scale: _pulseAnimation,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _buildGlowCircle(280, 0.1),
            _buildGlowCircle(240, 0.2),
            Container(
              width: 200, height: 200,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFB91C1C)])),
              child: Center(
                child: _isLocating 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(context.loc.sosButton, style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlowCircle(double size, double opacity) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFEF4444).withOpacity(opacity)));

  Widget _buildVibrationToggle(bool isDark, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: theme.colorScheme.surfaceVariant, borderRadius: BorderRadius.circular(24)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(context.loc.constantVibration, style: const TextStyle(fontWeight: FontWeight.w700)),
          CupertinoSwitch(value: _isVibrationEnabled, activeTrackColor: const Color(0xFFEF4444), onChanged: (v) => setState(() => _isVibrationEnabled = v)),
        ],
      ),
    );
  }
}