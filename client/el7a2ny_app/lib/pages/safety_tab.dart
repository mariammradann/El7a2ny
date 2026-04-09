import 'package:flutter/material.dart';

class SafetyTab extends StatelessWidget {
  const SafetyTab({super.key});

  @override
  Widget build(BuildContext context) {
    final tips = [
      {
        'title': 'الاستعداد للطوارئ',
        'description': 'احفظ أرقام الطوارئ في مكان سهل الوصول',
        'icon': Icons.notifications_active_rounded,
        'gradientColors': [const Color(0xFF3B82F6), const Color(0xFF06B6D4)],
      },
      {
        'title': 'اعرف موقعك',
        'description': 'كن دايماً عارف مكانك بالظبط عشان استجابة أسرع',
        'icon': Icons.location_on_rounded,
        'gradientColors': [const Color(0xFF8B5CF6), const Color(0xFFA855F7)],
      },
      {
        'title': 'اهدى',
        'description': 'اتكلم بوضوح وقول معلومات صحيحة وقت الطوارئ',
        'icon': Icons.show_chart_rounded,
        'gradientColors': [const Color(0xFF10B981), const Color(0xFF14B8A6)],
      },
    ];

    final importantNumbers = [
      {
        'name': 'الشرطة',
        'number': '122',
        'gradientColors': [const Color(0xFF3B82F6), const Color(0xFF6366F1)]
      },
      {
        'name': 'الإسعاف',
        'number': '123',
        'gradientColors': [const Color(0xFFEF4444), const Color(0xFFF97316)]
      },
      {
        'name': 'المطافي',
        'number': '180',
        'gradientColors': [const Color(0xFFF97316), const Color(0xFFF59E0B)]
      },
      {
        'name': 'النجدة',
        'number': '112',
        'gradientColors': [const Color(0xFF8B5CF6), const Color(0xFFEC4899)]
      },
      {
        'name': 'مكافحة المخدرات',
        'number': '122',
        'gradientColors': [const Color(0xFF64748B), const Color(0xFF475569)]
      },
      {
        'name': 'الحماية المدنية',
        'number': '180',
        'gradientColors': [const Color(0xFF10B981), const Color(0xFF14B8A6)]
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header card ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF0FDF4), Color(0xFFF0FDFA)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFA7F3D0)),
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
                        color: const Color(0xFF10B981).withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.shield_rounded,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إرشادات السلامة',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'معلومات أساسية للاستعداد للطوارئ',
                      style:
                          TextStyle(fontSize: 13, color: Color(0xFF64748B)),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'أرقام مهمة',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.2,
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
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFFE2E8F0)),
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
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F172A),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                  color: gradientColors[0].withOpacity(0.35),
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
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A))),
                const SizedBox(height: 4),
                Text(description,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
