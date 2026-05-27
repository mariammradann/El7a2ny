import 'package:flutter/material.dart';
import 'payment_types.dart';
import 'payment_receipt_page.dart';
import '../core/localization/app_strings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';


const _kOrange = Color(0xFFF18F34);

class PaymentProcessingPage extends StatefulWidget {
  final PaymentMethodType method;
  final double amount;
  final String methodTitle;
  final bool isYearly;
  final String? courseId;
  final String? courseTitle;

  const PaymentProcessingPage({
    super.key,
    required this.method,
    required this.amount,
    required this.methodTitle,
    this.isYearly = false,
    this.courseId,
    this.courseTitle,
  });

  @override
  State<PaymentProcessingPage> createState() => _PaymentProcessingPageState();
}

class _PaymentProcessingPageState extends State<PaymentProcessingPage>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _dotsCtrl;
  late final Animation<double> _pulse;

  int _step = 0;
  List<String> get _steps {
    final loc = context.loc;
    final isAr = loc.isAr;
    return [
      loc.processingVerifying,
      loc.processingPayment,
      widget.courseId != null
          ? (isAr ? 'تسجيل في الدورة التدريبية...' : 'Enrolling in training course...')
          : loc.processingSubscription,
      loc.processingSuccess,
    ];
  }

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _pulse = Tween<double>(begin: 0.85, end: 1.1).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // ✅ Defer until after first frame so context.loc is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _runSteps();
    });
  }

  Future<void> _runSteps() async {
  final steps = _steps;

  // Step 0 - Verifying
  await Future.delayed(const Duration(milliseconds: 800));
  if (!mounted) return;
  setState(() => _step = 0);

  // Step 1 - Processing payment
  await Future.delayed(const Duration(milliseconds: 900));
  if (!mounted) return;
  setState(() => _step = 1);

  // Step 2 - Activating subscription/enrollment  ← actual API call happens here
  await Future.delayed(const Duration(milliseconds: 900));
  if (!mounted) return;
  setState(() => _step = 2);

  try {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId != null) {
      if (widget.courseId != null) {
        await ApiService.enrollInCourse(widget.courseId!, userId);
      } else {
        final planType = widget.isYearly ? 'yearly' : 'monthly';
        await ApiService.subscribeUser(userId, planType);
      }
    }
  } catch (e) {
    print('Payment save error: $e');
    // Still proceed to receipt — don't block the user
  }

  // Step 3 - Success
  await Future.delayed(const Duration(milliseconds: 900));
  if (!mounted) return;
  setState(() => _step = 3);

  await Future.delayed(const Duration(milliseconds: 700));
  if (!mounted) return;
  _pulseCtrl.stop();

  Navigator.of(context).pushReplacement(
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => PaymentReceiptPage(
        method: widget.method,
        amount: widget.amount,
        methodTitle: widget.methodTitle,
        isYearly: widget.isYearly,
        courseId: widget.courseId,
        courseTitle: widget.courseTitle,
      ),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 500),
    ),
  );
}

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _dotsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.loc.isAr;
    final steps = _steps;
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _pulse,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF18F34), Color(0xFFE95F32)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _kOrange.withOpacity(0.35),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    context.loc.processingPayment,
                    style: const TextStyle(
                      fontFamily: 'NotoSansArabic',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.loc.pleaseWait,
                    style: const TextStyle(
                      fontFamily: 'NotoSansArabic',
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Steps
                  ...List.generate(steps.length, (i) {
                    final done = i < _step;
                    final active = i == _step;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: done
                                  ? const Color(0xFF16A34A)
                                  : active
                                      ? _kOrange
                                      : const Color(0xFFE5E7EB),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: done
                                  ? const Icon(Icons.check_rounded,
                                      color: Colors.white, size: 16)
                                  : active
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          '${i + 1}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF9CA3AF),
                                          ),
                                        ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 300),
                              style: TextStyle(
                                fontFamily: 'NotoSansArabic',
                                fontSize: 14,
                                fontWeight: active || done
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: done
                                    ? const Color(0xFF16A34A)
                                    : active
                                        ? const Color(0xFF111827)
                                        : const Color(0xFF9CA3AF),
                              ),
                              child: Text(steps[i]),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}