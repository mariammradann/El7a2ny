import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api/api_exception.dart';
import '../data/repositories/auth_repository.dart';
import '../widgets/language_toggle_button.dart';
import '../core/localization/app_strings.dart';
import 'reset_password_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    super.key,
    required this.contact,
    required this.isEmail,
  });

  final String contact;
  final bool isEmail;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  bool _verifying = false;
  bool _resending = false;

  final _auth = AuthRepository();

  Color _kBrandRed(BuildContext context) => Theme.of(context).primaryColor;
  Color _kSectionColor(BuildContext context) => Theme.of(context).brightness == Brightness.light
      ? Theme.of(context).primaryColor.withValues(alpha: 0.05)
      : Theme.of(context).colorScheme.surfaceContainer;
  Color _kIconCircleColor(BuildContext context) => Theme.of(context).brightness == Brightness.light
      ? Theme.of(context).primaryColor.withValues(alpha: 0.15)
      : Theme.of(context).colorScheme.primary.withValues(alpha: 0.2);
  Color _kTextDark(BuildContext context) => Theme.of(context).colorScheme.onSurface;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (widget.contact.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.loc.contactMissing)),
      );
      return;
    }
    setState(() => _verifying = true);
    try {
      await _auth.verifyOtp(
        contact: widget.contact.trim(),
        isEmail: widget.isEmail,
        code: _code.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.loc.verifiedSuccess)),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (context) => ResetPasswordScreen(
            contact: widget.contact.trim(),
            isEmail: widget.isEmail,
            code: _code.text.trim(),
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    if (widget.contact.trim().isEmpty) return;
    setState(() => _resending = true);
    try {
      await _auth.resendOtp(contact: widget.contact.trim(), isEmail: widget.isEmail);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.loc.resendSuccess)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandRed = _kBrandRed(context);
    final textDark = _kTextDark(context);
    final displayContact = widget.contact.trim().isNotEmpty
        ? widget.contact.trim()
        : '—';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textDark),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          context.loc.otpTitle,
          style: TextStyle(
            fontFamily: 'NotoSansArabic',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: brandRed,
          ),
        ),
        actions: [
          LanguageToggleButton(iconColor: brandRed),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
                  decoration: BoxDecoration(
                    color: _kSectionColor(context),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _kIconCircleColor(context),
                          ),
                          child: Icon(
                            Icons.shield_outlined,
                            color: brandRed,
                            size: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        context.loc.otpTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'NotoSansArabic',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        context.loc.otpSentMsg,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'NotoSansArabic',
                          fontSize: 14,
                          height: 1.4,
                          color: textDark.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        displayContact,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'NotoSansArabic',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: brandRed,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _code,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'NotoSansArabic',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 8,
                          color: textDark,
                        ),
                        validator: (v) {
                          if (v == null || v.length != 6) {
                            return context.loc.otpInvalid;
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: '******',
                          hintStyle: TextStyle(
                            fontFamily: 'NotoSansArabic',
                            color: textDark.withValues(alpha: 0.3),
                            fontSize: 16,
                            letterSpacing: 4,
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 18,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: textDark.withValues(alpha: 0.1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: textDark.withValues(alpha: 0.1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: brandRed,
                              width: 1.2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.red.shade400),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 52,
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _verifying ? null : _verify,
                          style: FilledButton.styleFrom(
                            backgroundColor: brandRed,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: _verifying
                              ? const SizedBox(
                                  width: 26,
                                  height: 26,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  context.loc.sendBtn,
                                  style: const TextStyle(
                                    fontFamily: 'NotoSansArabic',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            context.loc.didntReceiveCode,
                            style: TextStyle(
                              fontFamily: 'NotoSansArabic',
                              fontSize: 14,
                              color: textDark.withValues(alpha: 0.6),
                            ),
                          ),
                          InkWell(
                            onTap: _resending ? null : _resend,
                            child: Text(
                              context.loc.resendCode,
                              style: TextStyle(
                                fontFamily: 'NotoSansArabic',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: brandRed,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
