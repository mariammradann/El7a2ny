import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'payment_types.dart';
import 'home_screen.dart';
import '../services/session_service.dart';


const _kOrange = Color(0xFFFF6B00);
const _kGreen = Color(0xFF16A34A);

class PaymentReceiptPage extends StatefulWidget {
  final PaymentMethodType method;
  final double amount;
  final String methodTitle;
  final bool isYearly;

  const PaymentReceiptPage({
    super.key,
    required this.method,
    required this.amount,
    required this.methodTitle,
    this.isYearly = false,
  });

  @override
  State<PaymentReceiptPage> createState() => _PaymentReceiptPageState();
}

class _PaymentReceiptPageState extends State<PaymentReceiptPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  final String _transactionId =
      'EL${DateTime.now().millisecondsSinceEpoch % 1000000}';
  final DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    
    // Activate Premium Status with plan type
    SessionService().setPlus(true, isYearly: widget.isYearly);

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _formattedDate {
    final d = _date;
    return '${d.day}/${d.month}/${d.year}  ${_padZero(d.hour)}:${_padZero(d.minute)}';
  }

  String _padZero(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: SafeArea(
          child: Column(
            children: [
              // Back arrow row
              Padding(
                padding: const EdgeInsets.only(right: 8, top: 4),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded,
                        color: Color(0xFF374151), size: 20),
                    onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => false,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      // Success icon
                      ScaleTransition(
                        scale: _scaleAnim,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: _kGreen,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _kGreen.withOpacity(0.3),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 54,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: Column(
                          children: [
                            const Text(
                              'تم الدفع بنجاح! 🎉',
                              style: TextStyle(
                                fontFamily: 'NotoSansArabic',
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'اشتراكك في إلحقني بلس فعّال دلوقتي',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'NotoSansArabic',
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Receipt card
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: _buildReceiptCard(),
                      ),
                      const SizedBox(height: 20),
                      // Premium badge
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: _buildPremiumBadge(),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  // ── Receipt card ──────────────────────────────────────────────────────────
  Widget _buildReceiptCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF8C00), Color(0xFFE63B00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'فاتورة الاشتراك',
                      style: TextStyle(
                        fontFamily: 'NotoSansArabic',
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'إلحقني بلس',
                      style: TextStyle(
                        fontFamily: 'NotoSansArabic',
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'مدفوع ✓',
                    style: TextStyle(
                      fontFamily: 'NotoSansArabic',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Dashed separator
          _buildDashedDivider(),
          // Details
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _receiptRow('رقم المعاملة', _transactionId, copyable: true),
                _divider(),
                _receiptRow('التاريخ والوقت', _formattedDate),
                _divider(),
                _receiptRow('الخطة', widget.isYearly ? 'إلحقني بلس - سنوي' : 'إلحقني بلس - شهري'),
                _divider(),
                _receiptRow('طريقة الدفع', widget.methodTitle),
                _divider(),
                _receiptRow('الحالة', 'ناجح ✓',
                    valueColor: _kGreen),
                _divider(),
                // Total
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'الإجمالي المدفوع',
                        style: TextStyle(
                          fontFamily: 'NotoSansArabic',
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      Text(
                        '${widget.amount.toInt()} جنيه',
                        style: const TextStyle(
                          fontFamily: 'NotoSansArabic',
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: _kOrange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Premium badge ─────────────────────────────────────────────────────────
  Widget _buildPremiumBadge() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF8E7), Color(0xFFFFF3CC)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFFFD700),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مبروك! أنت دلوقتي عضو بلس 🎊',
                  style: TextStyle(
                    fontFamily: 'NotoSansArabic',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF92400E),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'استمتع بجميع مميزات إلحقني بلس الحصرية',
                  style: TextStyle(
                    fontFamily: 'NotoSansArabic',
                    fontSize: 12,
                    color: Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  Widget _buildActions(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Go home button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: _kOrange.withOpacity(0.4),
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const HomeScreen(initialTabIndex: 0),
                    ),
                    (route) => false,
                );
              },
              child: const Text(
                'الرجوع للرئيسية',
                style: TextStyle(
                  fontFamily: 'NotoSansArabic',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _buildDashedDivider() {
    return CustomPaint(
      painter: _DashedLinePainter(),
      child: const SizedBox(height: 1, width: double.infinity),
    );
  }

  Widget _divider() => const Divider(height: 20, color: Color(0xFFF3F4F6));

  Widget _receiptRow(String label, String value,
      {bool copyable = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'NotoSansArabic',
            fontSize: 13,
            color: Color(0xFF6B7280),
          ),
        ),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'NotoSansArabic',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: valueColor ?? const Color(0xFF111827),
              ),
            ),
            if (copyable) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('تم نسخ رقم المعاملة',
                          style: TextStyle(fontFamily: 'NotoSansArabic')),
                      backgroundColor: _kOrange,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                child:
                    const Icon(Icons.copy_rounded, color: _kOrange, size: 14),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    final paint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
