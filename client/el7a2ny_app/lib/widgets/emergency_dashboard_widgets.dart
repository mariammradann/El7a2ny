import 'package:flutter/material.dart';

/// خلفية الصفحة — كريمي فاتح.
const Color emergencyPageBg = Color(0xFFF5F3EF);

const Color emergencyTitleRed = Color(0xFFE44646);

const Color emergencySubtitleTeal = Color(0xFF1A5F6B);

const Color emergencyTextDark = Color(0xFF2C2C2C);

class EmergencyDashboardCard extends StatelessWidget {
  const EmergencyDashboardCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class EmergencyDeviceStatusRow extends StatelessWidget {
  const EmergencyDeviceStatusRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.connected,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final bool connected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'NotoSansArabic',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: emergencyTextDark,
            ),
          ),
        ),
        EmergencyStatusChip(connected: connected),
      ],
    );
  }
}

class EmergencyStatusChip extends StatelessWidget {
  const EmergencyStatusChip({super.key, required this.connected});

  final bool connected;

  @override
  Widget build(BuildContext context) {
    if (connected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFC8E6C9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'متصل',
          style: TextStyle(
            fontFamily: 'NotoSansArabic',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.green.shade900,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFCDD2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'غير متصل',
        style: TextStyle(
          fontFamily: 'NotoSansArabic',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.red.shade900,
        ),
      ),
    );
  }
}

class EmergencySolidButton extends StatelessWidget {
  const EmergencySolidButton({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.onPressed,
    this.foregroundColor = Colors.white,
    this.height = 48,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'NotoSansArabic',
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class EmergencyGradientButton extends StatelessWidget {
  const EmergencyGradientButton({
    super.key,
    required this.label,
    required this.gradient,
    required this.onPressed,
    this.height = 48,
  });

  final String label;
  final Gradient gradient;
  final VoidCallback onPressed;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(14),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'NotoSansArabic',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
