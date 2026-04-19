import 'package:flutter/material.dart';

/// Semantic colors for the emergency dashboard
Color getEmergencyTextDark(BuildContext context) => Theme.of(context).colorScheme.onSurface;
Color getEmergencyTitleRed(BuildContext context) => Theme.of(context).primaryColor;
Color getEmergencyPageBg(BuildContext context) => Theme.of(context).scaffoldBackgroundColor;

class EmergencyDashboardCard extends StatelessWidget {
  const EmergencyDashboardCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.brightness == Brightness.light ? 0.06 : 0.2),
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
              color: getEmergencyTextDark(context),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (connected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? Colors.green.withOpacity(0.1) : Colors.green.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.green.shade400.withOpacity(0.4) : Colors.green.shade600.withOpacity(0.3)),
        ),
        child: Text(
          'متصل',
          style: TextStyle(
            fontFamily: 'NotoSansArabic',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.green.shade300 : Colors.green.shade700,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.red.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.red.shade400.withOpacity(0.4) : Colors.red.shade600.withOpacity(0.3)),
      ),
      child: Text(
        'غير متصل',
        style: TextStyle(
          fontFamily: 'NotoSansArabic',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.red.shade300 : Colors.red.shade700,
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
