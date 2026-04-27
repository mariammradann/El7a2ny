import 'package:flutter/material.dart';
import '../core/localization/app_strings.dart';
import '../app/main_shell_screen.dart';

class VolunteerRatingScreen extends StatefulWidget {
  const VolunteerRatingScreen({super.key});

  @override
  State<VolunteerRatingScreen> createState() => _VolunteerRatingScreenState();
}

class _VolunteerRatingScreenState extends State<VolunteerRatingScreen> {
  bool? _isRealReport;

  void _submitReport() {
    // Show success snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.loc.ratingSuccess),
        backgroundColor: Colors.green,
      ),
    );

    // Return to main app shell
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MainShellScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: loc.isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: Column(
          children: [
            _buildHeader(context, loc),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      loc.volunteerRatingDesc,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.grey),
                    ),
                    const SizedBox(height: 48),
                    _buildOptionCard(
                      title: loc.realEmergency,
                      subtitle: loc.isAr ? 'البلاغ كان حقيقياً واستدعى التدخل.' : 'The report was authentic and required intervention.',
                      icon: Icons.check_circle_rounded,
                      isSelected: _isRealReport == true,
                      activeColor: Colors.green,
                      onTap: () => setState(() => _isRealReport = true),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 20),
                    _buildOptionCard(
                      title: loc.fakeReport,
                      subtitle: loc.isAr ? 'البلاغ كان كاذباً أو غير صحيح.' : 'The report was deceptive or incorrect.',
                      icon: Icons.error_rounded,
                      isSelected: _isRealReport == false,
                      activeColor: Colors.red,
                      onTap: () => setState(() => _isRealReport = false),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 64),
                    ElevatedButton(
                      onPressed: _isRealReport != null ? _submitReport : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                      child: Text(
                        loc.submitRating,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppStrings loc) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF334155)],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        bottom: 30,
        right: 20,
        left: 20,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.shield_rounded, color: Colors.amber, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              loc.volunteerRatingTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.08) : (isDark ? Colors.grey[900] : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : (isDark ? Colors.grey[800]! : Colors.grey[200]!),
            width: 2,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: activeColor.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected ? activeColor : (isDark ? Colors.grey[800] : Colors.grey[100]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[600]),
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? activeColor : (isDark ? Colors.white : Colors.black),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: activeColor, size: 24),
          ],
        ),
      ),
    );
  }
}
