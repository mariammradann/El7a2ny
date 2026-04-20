import 'package:flutter/material.dart';
import '../core/localization/app_strings.dart';

class SafetyTab extends StatelessWidget {
  const SafetyTab({super.key});

  @override
  Widget build(BuildContext context) {
    final tips = [
      {
        'title': context.loc.tip1Title,
        'description': context.loc.tip1Desc,
        'icon': Icons.notifications_active_rounded,
        'gradientColors': [const Color(0xFF3B82F6), const Color(0xFF06B6D4)],
      },
      {
        'title': context.loc.tip2Title,
        'description': context.loc.tip2Desc,
        'icon': Icons.location_on_rounded,
        'gradientColors': [const Color(0xFF8B5CF6), const Color(0xFFA855F7)],
      },
      {
        'title': context.loc.tip3Title,
        'description': context.loc.tip3Desc,
        'icon': Icons.show_chart_rounded,
        'gradientColors': [const Color(0xFF10B981), const Color(0xFF14B8A6)],
      },
    ];

    final importantNumbers = [
      {
        'name': context.loc.police,
        'number': '122',
        'gradientColors': [const Color(0xFF3B82F6), const Color(0xFF6366F1)]
      },
      {
        'name': context.loc.ambulance,
        'number': '123',
        'gradientColors': [const Color(0xFFEF4444), const Color(0xFFF97316)]
      },
      {
        'name': context.loc.fireDept,
        'number': '180',
        'gradientColors': [const Color(0xFFF97316), const Color(0xFFF59E0B)]
      },
      {
        'name': context.loc.rescue,
        'number': '112',
        'gradientColors': [const Color(0xFF8B5CF6), const Color(0xFFEC4899)]
      },
      {
        'name': context.loc.antiDrugs,
        'number': '122',
        'gradientColors': [const Color(0xFF64748B), const Color(0xFF475569)]
      },
      {
        'name': context.loc.civilDefense,
        'number': '180',
        'gradientColors': [const Color(0xFF10B981), const Color(0xFF14B8A6)]
      },
    ];

    return Directionality(
      textDirection: context.loc.isAr ? TextDirection.rtl : TextDirection.ltr,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header card ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white10
                      : Theme.of(context).primaryColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.shield_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.loc.safetyTips,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        context.loc.safetyTipsDesc,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
  
            // ── Safety Tips ───────────────────────────────────────────
            Column(
              children: tips
                  .map((tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _TipCard(
                          title: tip['title'] as String,
                          description: tip['description'] as String,
                          icon: tip['icon'] as IconData,
                          gradientColors:
                              tip['gradientColors'] as List<Color>,
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
  
            // ── Important Numbers ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black26
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.loc.importantNumbers,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.6,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: importantNumbers.length,
                    itemBuilder: (context, i) {
                      final item = importantNumbers[i];
                      final colors =
                          item['gradientColors'] as List<Color>;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Theme.of(context).colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white10
                                  : const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    item['name'] as String,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  ShaderMask(
                                    shaderCallback: (bounds) =>
                                        LinearGradient(colors: colors)
                                            .createShader(bounds),
                                    child: Text(
                                      item['number'] as String,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                gradient:
                                    LinearGradient(colors: colors),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.phone,
                                  color: Colors.white, size: 16),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradientColors;

  const _TipCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black26
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: gradientColors[0].withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 4),
                Text(description,
                    style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
