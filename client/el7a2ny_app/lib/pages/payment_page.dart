import 'package:flutter/material.dart';
import 'payment_types.dart';
import 'payment_details_page.dart';
import '../core/localization/app_strings.dart';


class _PaymentOption {
  final PaymentMethodType type;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final bool isMostUsed;

  const _PaymentOption({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    this.isMostUsed = false,
  });
}

const _kOrange = Color(0xFFFF6B00);

// ─── Page ─────────────────────────────────────────────────────────────────────
class PaymentPage extends StatefulWidget {
  final double amount;
  final bool isYearly;
  const PaymentPage({
    super.key,
    this.amount = 299,
    this.isYearly = false,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  PaymentMethodType? _selected;

  List<_PaymentOption> get _options {
    final loc = context.loc;
    return [
      _PaymentOption(
        type: PaymentMethodType.card,
        title: loc.methodCreditCard,
        subtitle: 'Visa, Mastercard, Meeza',
        icon: Icons.credit_card_rounded,
        iconBg: const Color(0xFF4F8EF7),
        isMostUsed: true,
      ),
      _PaymentOption(
        type: PaymentMethodType.fawry,
        title: loc.methodFawry,
        subtitle: loc.fawrySubtitle,
        icon: Icons.grid_view_rounded,
        iconBg: const Color(0xFFFF6B00),
        isMostUsed: true,
      ),
      _PaymentOption(
        type: PaymentMethodType.vodafoneCash,
        title: loc.methodVodafoneCash,
        subtitle: loc.vodafoneSubtitle,
        icon: Icons.smartphone_rounded,
        iconBg: const Color(0xFFE3001B),
      ),
      _PaymentOption(
        type: PaymentMethodType.instaPay,
        title: loc.methodInstaPay,
        subtitle: loc.instapaySubtitle,
        icon: Icons.phone_android_rounded,
        iconBg: const Color(0xFF7C3AED),
      ),
      _PaymentOption(
        type: PaymentMethodType.bankTransfer,
        title: loc.methodBankTransfer,
        subtitle: loc.bankSubtitle,
        icon: Icons.account_balance_rounded,
        iconBg: const Color(0xFF374151),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.loc.isAr;
    final options = _options;
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Column(
          children: [
            _buildHeader(context),
            _buildSecurityBanner(),
            Expanded(
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: options.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _buildPaymentCard(options[i]),
              ),
            ),
            _buildConfirmButton(context),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
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
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 24),
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
                  Text(
                    context.loc.choosePaymentMethod,
                    style: const TextStyle(
                      fontFamily: 'NotoSansArabic',
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontFamily: 'NotoSansArabic',
                        fontSize: 16,
                        color: Colors.white,
                      ),
                      children: [
                        TextSpan(
                          text: '${widget.amount.toInt()} ${context.loc.egp}',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        TextSpan(
                          text: widget.isYearly ? context.loc.perYear : context.loc.perMonth,
                          style: const TextStyle(fontWeight: FontWeight.w400),
                        ),
                      ],
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

  // ── Security Banner ─────────────────────────────────────────────────────────
  Widget _buildSecurityBanner() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFEEFBF4),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shield_outlined, color: Color(0xFF22C55E), size: 18),
          const SizedBox(width: 6),
          Text(
            context.loc.secureTransactions,
            style: const TextStyle(
              fontFamily: 'NotoSansArabic',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF15803D),
            ),
          ),
        ],
      ),
    );
  }

  // ── Payment Card ────────────────────────────────────────────────────────────
  Widget _buildPaymentCard(_PaymentOption option) {
    final isSelected = _selected == option.type;

    return GestureDetector(
      onTap: () => setState(() => _selected = option.type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _kOrange : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? _kOrange.withOpacity(0.15)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option.title,
                          style: const TextStyle(
                            fontFamily: 'NotoSansArabic',
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          option.subtitle,
                          style: const TextStyle(
                            fontFamily: 'NotoSansArabic',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Arrow
                  Icon(
                    context.loc.isAr ? Icons.arrow_forward_ios_rounded : Icons.arrow_back_ios_new_rounded,
                    size: 14,
                    color:
                        isSelected ? _kOrange : const Color(0xFFADB5BD),
                  ),
                  const SizedBox(width: 10),
                  // Icon box
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: option.iconBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child:
                        Icon(option.icon, color: Colors.white, size: 26),
                  ),
                ],
              ),
            ),
            // "Most used" badge
            if (option.isMostUsed)
              Positioned(
                top: -1,
                right: -1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: const BoxDecoration(
                    color: _kOrange,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(14),
                      bottomLeft: Radius.circular(10),
                    ),
                  ),
                  child: Text(
                    context.loc.mostUsed,
                    style: const TextStyle(
                      fontFamily: 'NotoSansArabic',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Confirm Button ──────────────────────────────────────────────────────────
  Widget _buildConfirmButton(BuildContext context) {
    final hasSelection = _selected != null;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                hasSelection ? _kOrange : const Color(0xFFD1D5DB),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: hasSelection ? 4 : 0,
            shadowColor: _kOrange.withOpacity(0.4),
          ),
          onPressed: hasSelection
              ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PaymentDetailsPage(
                        method: _selected!,
                        amount: widget.amount,
                        isYearly: widget.isYearly,
                      ),
                    ),
                  );
                }
              : null,
          child: Text(
            context.loc.continueBtn,
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
}
