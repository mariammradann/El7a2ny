import 'package:flutter/material.dart';

enum PaymentMethod { card, eps, giropay, other }

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  PaymentMethod _selectedMethod = PaymentMethod.card;
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvcController = TextEditingController();
  final _countryController = TextEditingController(text: 'مصر');
  final _postalCodeController = TextEditingController();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    _countryController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF111827)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'دفع الاشتراك',
            style: TextStyle(
              fontFamily: 'NotoSansArabic',
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            children: [
              _PaymentMethodTabs(
                selectedMethod: _selectedMethod,
                onChange: (method) => setState(() => _selectedMethod = method),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: ListView(
                  children: [
                    if (_selectedMethod == PaymentMethod.card) ...[
                      _PaymentField(
                        label: 'رقم البطاقة',
                        hintText: '1234 1234 1234 1234',
                        controller: _cardNumberController,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _PaymentField(
                              label: 'تاريخ الانتهاء',
                              hintText: 'MM / YY',
                              controller: _expiryController,
                              keyboardType: TextInputType.datetime,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _PaymentField(
                              label: 'CVC',
                              hintText: 'CVC',
                              controller: _cvcController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    _PaymentField(
                      label: 'البلد',
                      hintText: 'مصر',
                      controller: _countryController,
                      readOnly: true,
                      suffixIcon: Icons.arrow_drop_down,
                    ),
                    const SizedBox(height: 14),
                    _PaymentField(
                      label: 'الرمز البريدي',
                      hintText: '11511',
                      controller: _postalCodeController,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          const BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.04),
                            blurRadius: 14,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: const [
                          Text(
                            'المجموع',
                            style: TextStyle(
                              fontFamily: 'NotoSansArabic',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            '299 جنيه / شهرياً',
                            style: TextStyle(
                              fontFamily: 'NotoSansArabic',
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF111827),
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'أو 2,990 جنيه سنوياً (وفر 17%)',
                            style: TextStyle(
                              fontFamily: 'NotoSansArabic',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9500),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'دفع الآن',
                        style: TextStyle(
                          fontFamily: 'NotoSansArabic',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodTabs extends StatelessWidget {
  const _PaymentMethodTabs({
    required this.selectedMethod,
    required this.onChange,
  });

  final PaymentMethod selectedMethod;
  final ValueChanged<PaymentMethod> onChange;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PaymentMethodTab(
            label: 'بطاقة',
            icon: Icons.credit_card,
            active: selectedMethod == PaymentMethod.card,
            onTap: () => onChange(PaymentMethod.card),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PaymentMethodTab(
            label: 'فوري',
            icon: Icons.payment,
            active: selectedMethod == PaymentMethod.eps,
            onTap: () => onChange(PaymentMethod.eps),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PaymentMethodTab(
            label: 'محفظة',
            icon: Icons.account_balance_wallet,
            active: selectedMethod == PaymentMethod.giropay,
            onTap: () => onChange(PaymentMethod.giropay),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PaymentMethodTab(
            label: 'أخرى',
            icon: Icons.more_horiz,
            active: selectedMethod == PaymentMethod.other,
            onTap: () => onChange(PaymentMethod.other),
          ),
        ),
      ],
    );
  }
}

class _PaymentMethodTab extends StatelessWidget {
  const _PaymentMethodTab({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? const Color(0xFF3B82F6) : const Color(0xFFE5E7EB),
            width: 1.4,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: active ? const Color(0xFF2563EB) : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'NotoSansArabic',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: active
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentField extends StatelessWidget {
  const _PaymentField({
    required this.label,
    required this.hintText,
    required this.controller,
    this.keyboardType,
    this.readOnly = false,
    this.suffixIcon,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool readOnly;
  final IconData? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'NotoSansArabic',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: hintText,
            suffixIcon: suffixIcon != null
                ? Icon(suffixIcon, color: const Color(0xFF6B7280))
                : null,
            filled: true,
            fillColor: Colors.white,
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
              borderSide: const BorderSide(color: Color(0xFF3B82F6)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}
