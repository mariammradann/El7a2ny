import 'package:flutter/material.dart';
import '../core/localization/app_strings.dart';
import '../widgets/star_rating_bar.dart';
import '../app/main_shell_screen.dart';

class UserRatingScreen extends StatefulWidget {
  const UserRatingScreen({super.key});

  @override
  State<UserRatingScreen> createState() => _UserRatingScreenState();
}

class _UserRatingScreenState extends State<UserRatingScreen> {
  double _appRating = 0;
  double _policeRating = 0;
  double _ambulanceRating = 0;
  double _fireDeptRating = 0;
  double _el7a2nyPlusRating = 0;
  bool? _volunteersHelpful;

  void _submitRating() {
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
                      loc.userRatingDesc,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    _buildRatingSection(loc.rateApp, (v) => setState(() => _appRating = v), isDark),
                    const Divider(height: 40),
                    
                    Text(
                      loc.authoritiesRating,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    _buildRatingSection(loc.policeRating, (v) => setState(() => _policeRating = v), isDark),
                    const SizedBox(height: 16),
                    _buildRatingSection(loc.ambulanceRating, (v) => setState(() => _ambulanceRating = v), isDark),
                    const SizedBox(height: 16),
                    _buildRatingSection(loc.fireDeptRating, (v) => setState(() => _fireDeptRating = v), isDark),
                    const Divider(height: 40),
                    
                    _buildRatingSection(loc.el7a2nyPlusRating, (v) => setState(() => _el7a2nyPlusRating = v), isDark),
                    const Divider(height: 40),
                    
                    Text(
                      loc.volunteerHelpful,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildHelpfulButton(
                            title: loc.isAr ? 'نعم' : 'Yes',
                            icon: Icons.check_circle_rounded,
                            isSelected: _volunteersHelpful == true,
                            activeColor: Colors.green,
                            onTap: () => setState(() => _volunteersHelpful = true),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildHelpfulButton(
                            title: loc.isAr ? 'لا' : 'No',
                            icon: Icons.cancel_rounded,
                            isSelected: _volunteersHelpful == false,
                            activeColor: Colors.red,
                            onTap: () => setState(() => _volunteersHelpful = false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    
                    ElevatedButton(
                      onPressed: _submitRating,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        loc.submitRating,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 20),
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
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF3730A3)],
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
            child: const Icon(Icons.star_rounded, color: Colors.amber, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              loc.userRatingTitle,
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

  Widget _buildRatingSection(String title, Function(double) onRatingChanged, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        StarRatingBar(
          itemSize: 28,
          onRatingChanged: onRatingChanged,
          inactiveColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
        ),
      ],
    );
  }

  Widget _buildHelpfulButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color activeColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isSelected ? activeColor.withValues(alpha: 0.1) : (isDark ? Colors.grey[900] : Colors.grey[100]);
    final borderColor = isSelected ? activeColor : (isDark ? Colors.grey[800]! : Colors.grey[300]!);
    final textColor = isSelected ? activeColor : (isDark ? Colors.white : Colors.black);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: textColor, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
