import 'package:flutter/material.dart';
import '../core/localization/app_strings.dart';

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
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.close, color: onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          context.loc.paymentTitle,
          style: TextStyle(
            fontFamily: 'NotoSansArabic',
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            _PaymentMethodTabs(
              selectedMethod: _selectedMethod,
              onChange: (method) => setState(() => _selectedMethod = method),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  if (_selectedMethod == PaymentMethod.card) ...[
                    _PaymentField(
                      label: context.loc.cardNumber,
                      hintText: '1234 1234 1234 1234',
                      controller: _cardNumberController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _PaymentField(
                            label: context.loc.cardExpiry,
                            hintText: 'MM / YY',
                            controller: _expiryController,
                            keyboardType: TextInputType.datetime,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _PaymentField(
                            label: context.loc.cardCvc,
                            hintText: '123',
                            controller: _cvcController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  _PaymentField(
                    label: context.loc.paymentCountry,
                    hintText: context.loc.paymentEgypt,
                    controller: _countryController,
                    readOnly: true,
                    suffixIcon: Icons.keyboard_arrow_down_rounded,
                  ),
                  const SizedBox(height: 16),
                  _PaymentField(
                    label: context.loc.paymentPostalCode,
                    hintText: '11511',
                    controller: _postalCodeController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 32),

                  // Order Summary Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.2 : 0.03),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.loc.paymentTotal,
                          style: TextStyle(
                            fontFamily: 'NotoSansArabic',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.loc.paymentMonthlyPrice,
                          style: TextStyle(
                            fontFamily: 'NotoSansArabic',
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.loc.paymentYearlySavings,
                          style: TextStyle(
                            fontFamily: 'NotoSansArabic',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: theme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Pay Button
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: theme.primaryColor.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        // In a real app, integrate with Stripe/Paymob here
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        context.loc.payNow,
                        style: const TextStyle(
                          fontFamily: 'NotoSansArabic',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _PaymentMethodTab(
            label: context.loc.paymentCard,
            icon: Icons.credit_card_rounded,
            active: selectedMethod == PaymentMethod.card,
            onTap: () => onChange(PaymentMethod.card),
          ),
          const SizedBox(width: 12),
          _PaymentMethodTab(
            label: context.loc.paymentFawry,
            icon: Icons.account_balance_rounded,
            active: selectedMethod == PaymentMethod.eps,
            onTap: () => onChange(PaymentMethod.eps),
          ),
          const SizedBox(width: 12),
          _PaymentMethodTab(
            label: context.loc.paymentWallet,
            icon: Icons.account_balance_wallet_rounded,
            active: selectedMethod == PaymentMethod.giropay,
            onTap: () => onChange(PaymentMethod.giropay),
          ),
          const SizedBox(width: 12),
          _PaymentMethodTab(
            label: context.loc.paymentOther,
            icon: Icons.more_horiz_rounded,
            active: selectedMethod == PaymentMethod.other,
            onTap: () => onChange(PaymentMethod.other),
          ),
        ],
      ),
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
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: active ? primaryColor.withValues(alpha: 0.12) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? primaryColor : theme.dividerColor.withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: active ? primaryColor : theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'NotoSansArabic',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: active ? primaryColor : theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 4),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'NotoSansArabic',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          style: const TextStyle(fontFamily: 'NotoSansArabic', fontSize: 16, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.35), fontWeight: FontWeight.normal),
            suffixIcon: suffixIcon != null
                ? Icon(suffixIcon, color: theme.colorScheme.onSurface.withValues(alpha: 0.4))
                : null,
            filled: true,
            fillColor: theme.colorScheme.surfaceContainer,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: theme.primaryColor, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
          ),
        ),
      ],
    );
  }
}
