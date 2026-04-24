import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'payment_types.dart';
import 'payment_processing_page.dart';


const _kOrange = Color(0xFFFF6B00);

class PaymentDetailsPage extends StatefulWidget {
  final PaymentMethodType method;
  final double amount;
  final bool isYearly;

  const PaymentDetailsPage({
    super.key,
    required this.method,
    this.amount = 299,
    this.isYearly = false,
  });

  @override
  State<PaymentDetailsPage> createState() => _PaymentDetailsPageState();
}

class _PaymentDetailsPageState extends State<PaymentDetailsPage> {
  final _formKey = GlobalKey<FormState>();

  // Card fields
  final _cardNumberCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvcCtrl = TextEditingController();
  final _cardNameCtrl = TextEditingController();

  // Vodafone Cash / InstaPay field
  final _phoneCtrl = TextEditingController();

  // Fawry reference (read-only, generated)
  final String _fawryRef = '892${DateTime.now().millisecondsSinceEpoch % 100000}';

  // Bank transfer details
  static const String _bankAccount = '0025 0011 0058 7930';
  static const String _bankIban = 'EG800025001100587930';
  static const String _bankName = 'بنك مصر';

  bool _saveCard = false;

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _expiryCtrl.dispose();
    _cvcCtrl.dispose();
    _cardNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  String get _methodTitle {
    switch (widget.method) {
      case PaymentMethodType.card:       return 'بطاقة ائتمان/خصم';
      case PaymentMethodType.fawry:      return 'فوري';
      case PaymentMethodType.vodafoneCash: return 'فودافون كاش';
      case PaymentMethodType.instaPay:   return 'إنستاباي';
      case PaymentMethodType.bankTransfer: return 'تحويل بنكي';
    }
  }

  Color get _methodColor {
    switch (widget.method) {
      case PaymentMethodType.card:       return const Color(0xFF4F8EF7);
      case PaymentMethodType.fawry:      return _kOrange;
      case PaymentMethodType.vodafoneCash: return const Color(0xFFE3001B);
      case PaymentMethodType.instaPay:   return const Color(0xFF7C3AED);
      case PaymentMethodType.bankTransfer: return const Color(0xFF374151);
    }
  }

  IconData get _methodIcon {
    switch (widget.method) {
      case PaymentMethodType.card:       return Icons.credit_card_rounded;
      case PaymentMethodType.fawry:      return Icons.grid_view_rounded;
      case PaymentMethodType.vodafoneCash: return Icons.smartphone_rounded;
      case PaymentMethodType.instaPay:   return Icons.phone_android_rounded;
      case PaymentMethodType.bankTransfer: return Icons.account_balance_rounded;
    }
  }

  void _proceed() {
    if (widget.method == PaymentMethodType.card ||
        widget.method == PaymentMethodType.vodafoneCash ||
        widget.method == PaymentMethodType.instaPay) {
      if (!_formKey.currentState!.validate()) return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentProcessingPage(
          method: widget.method,
          amount: widget.amount,
          methodTitle: _methodTitle,
          isYearly: widget.isYearly,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildMethodBadge(),
                    const SizedBox(height: 20),
                    _buildContent(),
                    const SizedBox(height: 24),
                    _buildSummaryCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            _buildPayButton(context),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF8C00), Color(0xFFE63B00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 20),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'تفاصيل الدفع',
                    style: TextStyle(
                      fontFamily: 'NotoSansArabic',
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _methodTitle,
                    style: const TextStyle(
                      fontFamily: 'NotoSansArabic',
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Method badge ─────────────────────────────────────────────────────────
  Widget _buildMethodBadge() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _methodColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_methodIcon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Text(
          _methodTitle,
          style: const TextStyle(
            fontFamily: 'NotoSansArabic',
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  // ── Dynamic content per method ───────────────────────────────────────────
  Widget _buildContent() {
    switch (widget.method) {
      case PaymentMethodType.card:
        return _buildCardForm();
      case PaymentMethodType.fawry:
        return _buildFawryInfo();
      case PaymentMethodType.vodafoneCash:
        return _buildPhoneForm('رقم محفظة فودافون كاش', '01x xxxx xxxx');
      case PaymentMethodType.instaPay:
        return _buildPhoneForm('رقم المحفظة / الموبايل', '01x xxxx xxxx');
      case PaymentMethodType.bankTransfer:
        return _buildBankInfo();
    }
  }

  // Card form
  Widget _buildCardForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _inputField(
          label: 'اسم حامل البطاقة',
          hint: 'الاسم كما هو مكتوب على البطاقة',
          controller: _cardNameCtrl,
          validator: (v) => (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null,
        ),
        const SizedBox(height: 14),
        _inputField(
          label: 'رقم البطاقة',
          hint: '1234 5678 9012 3456',
          controller: _cardNumberCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _CardNumberFormatter(),
          ],
          maxLength: 19,
          suffixWidget: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _miniLogo('VISA', const Color(0xFF1A1F71)),
              const SizedBox(width: 4),
              _miniLogo('MC', const Color(0xFFEB001B)),
            ],
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'هذا الحقل مطلوب';
            final digits = v.replaceAll(' ', '');
            if (digits.length < 16) return 'رقم البطاقة غير مكتمل';
            return null;
          },
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _inputField(
                label: 'تاريخ الانتهاء',
                hint: 'MM / YY',
                controller: _expiryCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _ExpiryFormatter(),
                ],
                maxLength: 5,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'مطلوب';
                  if (v.length < 5) return 'غير صحيح';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _inputField(
                label: 'CVV / CVC',
                hint: '• • •',
                controller: _cvcCtrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 3,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'مطلوب';
                  if (v.length < 3) return 'غير صحيح';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Save card toggle
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: SwitchListTile(
            value: _saveCard,
            onChanged: (v) => setState(() => _saveCard = v),
            activeColor: _kOrange,
            title: const Text(
              'حفظ البطاقة للمرات القادمة',
              style: TextStyle(
                fontFamily: 'NotoSansArabic',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            secondary: const Icon(Icons.lock_outline_rounded,
                color: Color(0xFF6B7280), size: 20),
          ),
        ),
      ],
    );
  }

  // Fawry info
  Widget _buildFawryInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(Icons.receipt_long_rounded,
                    color: _kOrange, size: 36),
              ),
              const SizedBox(height: 16),
              const Text(
                'كود الدفع الخاص بك',
                style: TextStyle(
                  fontFamily: 'NotoSansArabic',
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _fawryRef,
                    style: const TextStyle(
                      fontFamily: 'NotoSansArabic',
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: _fawryRef));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('تم نسخ الكود',
                              style: TextStyle(fontFamily: 'NotoSansArabic')),
                          backgroundColor: _kOrange,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                    child: const Icon(Icons.copy_rounded,
                        color: _kOrange, size: 22),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _infoStep('1', 'روح لأقرب فرع فوري'),
        const SizedBox(height: 10),
        _infoStep('2', 'قول للموظف "دفع خدمة إلحقني"'),
        const SizedBox(height: 10),
        _infoStep('3', 'اديه الكود: $_fawryRef'),
        const SizedBox(height: 10),
        _infoStep('4', 'ادفع المبلغ واحتفظ بالإيصال'),
      ],
    );
  }

  // Phone form (Vodafone Cash / InstaPay)
  Widget _buildPhoneForm(String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _inputField(
          label: label,
          hint: hint,
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 11,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'هذا الحقل مطلوب';
            if (v.length < 11) return 'رقم الهاتف غير مكتمل';
            return null;
          },
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFFD699)),
          ),
          child: Row(
            children: const [
              Icon(Icons.info_outline_rounded, color: _kOrange, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'هيتبعتلك رسالة تأكيد على رقم التليفون',
                  style: TextStyle(
                    fontFamily: 'NotoSansArabic',
                    fontSize: 13,
                    color: Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Bank transfer info
  Widget _buildBankInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'بيانات الحساب البنكي',
                style: TextStyle(
                  fontFamily: 'NotoSansArabic',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const Divider(height: 24),
              _bankRow('البنك', _bankName),
              const SizedBox(height: 12),
              _bankRow('رقم الحساب', _bankAccount, copyable: true),
              const SizedBox(height: 12),
              _bankRow('IBAN', _bankIban, copyable: true),
              const SizedBox(height: 12),
              _bankRow('المبلغ', '${widget.amount.toInt()} جنيه مصري'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _infoStep('1', 'افتح تطبيق البنك أو روح الفرع'),
        const SizedBox(height: 10),
        _infoStep('2', 'حوّل المبلغ للحساب أعلاه'),
        const SizedBox(height: 10),
        _infoStep('3', 'اكتب "إلحقني-اشتراك" في خانة البيان'),
        const SizedBox(height: 10),
        _infoStep('4', 'اضغط "تأكيد الدفع" وهنراجع التحويل'),
      ],
    );
  }

  // ── Summary card ─────────────────────────────────────────────────────────
  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _summaryRow('الخطة', widget.isYearly ? 'إلحقني بلس - سنوي' : 'إلحقني بلس - شهري'),
          const Divider(height: 20),
          _summaryRow('طريقة الدفع', _methodTitle),
          const Divider(height: 20),
          _summaryRow(
            'الإجمالي',
            '${widget.amount.toInt()} جنيه',
            valueStyle: const TextStyle(
              fontFamily: 'NotoSansArabic',
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: _kOrange,
            ),
          ),
        ],
      ),
    );
  }

  // ── Pay button ────────────────────────────────────────────────────────────
  Widget _buildPayButton(BuildContext context) {
    final label = widget.method == PaymentMethodType.fawry ||
            widget.method == PaymentMethodType.bankTransfer
        ? 'تأكيد الدفع'
        : 'ادفع الآن';

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      child: SizedBox(
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
          onPressed: _proceed,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'NotoSansArabic',
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _inputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool obscureText = false,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    Widget? suffixWidget,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'NotoSansArabic',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          validator: validator,
          style: const TextStyle(
            fontFamily: 'NotoSansArabic',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            hintStyle: const TextStyle(
                color: Color(0xFFBEC3CB), fontWeight: FontWeight.w400),
            filled: true,
            fillColor: Colors.white,
            suffix: suffixWidget,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _kOrange, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _miniLogo(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(4)),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w900)),
    );
  }

  Widget _infoStep(String step, String text) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
              color: _kOrange, shape: BoxShape.circle),
          child: Center(
            child: Text(step,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'NotoSansArabic',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value, {TextStyle? valueStyle}) {
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
        Text(
          value,
          style: valueStyle ??
              const TextStyle(
                fontFamily: 'NotoSansArabic',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
        ),
      ],
    );
  }

  Widget _bankRow(String label, String value, {bool copyable = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontFamily: 'NotoSansArabic',
                fontSize: 13,
                color: Color(0xFF6B7280))),
        Row(
          children: [
            Text(value,
                style: const TextStyle(
                    fontFamily: 'NotoSansArabic',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827))),
            if (copyable) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('تم النسخ',
                          style: TextStyle(fontFamily: 'NotoSansArabic')),
                      backgroundColor: _kOrange,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                child: const Icon(Icons.copy_rounded,
                    color: _kOrange, size: 16),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ── Formatters ─────────────────────────────────────────────────────────────────
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue value) {
    final digits = value.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 16; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final str = buffer.toString();
    return value.copyWith(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue value) {
    final digits = value.text.replaceAll('/', '').replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 4; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(digits[i]);
    }
    final str = buffer.toString();
    return value.copyWith(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}
