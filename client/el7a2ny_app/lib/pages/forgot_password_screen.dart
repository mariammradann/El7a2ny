import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api/api_exception.dart';
import '../data/repositories/auth_repository.dart';
import '../core/localization/app_strings.dart';
import '../widgets/language_toggle_button.dart';
import 'otp_verification_screen.dart';

/// متوافق مع أحمر التطبيق في الشاشات العربية الأخرى.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contact = TextEditingController();
  bool _sending = false;
  bool _isPhone = true;

  final _auth = AuthRepository();

  Color _kBrandRed(BuildContext context) => Theme.of(context).primaryColor;
  Color _kSectionColor(BuildContext context) => Theme.of(context).brightness == Brightness.light
      ? Theme.of(context).primaryColor.withValues(alpha: 0.05)
      : Theme.of(context).colorScheme.surfaceContainer;
  Color _kTextDark(BuildContext context) => Theme.of(context).colorScheme.onSurface;

  @override
  void dispose() {
    _contact.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final contact = _contact.text.trim();
    setState(() => _sending = true);
    try {
      await _auth.requestPasswordReset(contact: contact, isEmail: !_isPhone);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => OtpVerificationScreen(
            contact: contact,
            isEmail: !_isPhone,
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
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandRed = _kBrandRed(context);
    final textDark = _kTextDark(context);

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
          context.loc.forgotPasswordQ,
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
                            color: brandRed,
                          ),
                          child: Icon(
                            _isPhone ? Icons.phone_rounded : Icons.email_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        context.loc.recoveryTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'NotoSansArabic',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 20),
                      RadioGroup<bool>(
                        groupValue: _isPhone,
                        onChanged: (v) => setState(() {
                          _isPhone = v!;
                          _contact.clear();
                        }),
                        child: Row(
                          children: [
                            Expanded(
                              child: RadioListTile<bool>(
                                title: Text(context.loc.phoneOption,
                                    style: const TextStyle(
                                        fontFamily: 'NotoSansArabic',
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold)),
                                value: true,
                                activeColor: brandRed,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<bool>(
                                title: Text(context.loc.emailOption,
                                    style: const TextStyle(
                                        fontFamily: 'NotoSansArabic',
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold)),
                                value: false,
                                activeColor: brandRed,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        _isPhone ? context.loc.phoneFieldLabel : context.loc.emailFieldLabel,
                        style: TextStyle(
                          fontFamily: 'NotoSansArabic',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _contact,
                        keyboardType: _isPhone ? TextInputType.phone : TextInputType.emailAddress,
                        inputFormatters: _isPhone ? [FilteringTextInputFormatter.digitsOnly] : null,
                        style: const TextStyle(fontFamily: 'NotoSansArabic'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return context.loc.requiredField;
                          if (_isPhone && v.trim().length < 10) {
                            return context.loc.enterValidMobile;
                          }
                          if (!_isPhone && !v.contains('@')) {
                            return context.loc.enterValidEmail;
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: _isPhone ? '01xxxxxxxxx' : 'email@example.com',
                          hintStyle: TextStyle(
                            fontFamily: 'NotoSansArabic',
                            color: textDark.withValues(alpha: 0.4),
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            _isPhone ? Icons.phone_rounded : Icons.email_outlined,
                            color: textDark.withValues(alpha: 0.5),
                            size: 22,
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 16,
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
                          onPressed: _sending ? null : _sendCode,
                          style: FilledButton.styleFrom(
                            backgroundColor: brandRed,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: _sending
                              ? const SizedBox(
                                  width: 26,
                                  height: 26,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  context.loc.sendVerificationCode,
                                  style: const TextStyle(
                                    fontFamily: 'NotoSansArabic',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
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
