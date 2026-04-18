import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api/api_exception.dart';
import '../data/repositories/auth_repository.dart';
import '../core/localization/app_strings.dart';
import '../widgets/language_toggle_button.dart';
import 'otp_verification_screen.dart';

/// متوافق مع أحمر التطبيق في الشاشات العربية الأخرى.
const Color _kBrandRed = Color(0xFFE44646);

const Color _kCardPink = Color(0xFFFDECEC);

const Color _kTextDark = Color(0xFF424242);

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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            context.loc.forgotPasswordQ,
            style: const TextStyle(
              fontFamily: 'NotoSansArabic',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _kBrandRed,
            ),
          ),
          actions: const [
            LanguageToggleButton(iconColor: _kBrandRed),
            SizedBox(width: 8),
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
                      color: _kCardPink,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: _kBrandRed,
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
                          style: const TextStyle(
                            fontFamily: 'NotoSansArabic',
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<bool>(
                                title: Text(context.loc.phoneOption, style: const TextStyle(fontFamily: 'NotoSansArabic', fontSize: 13, fontWeight: FontWeight.bold)),
                                value: true,
                                groupValue: _isPhone,
                                activeColor: _kBrandRed,
                                contentPadding: EdgeInsets.zero,
                                onChanged: (v) => setState(() { _isPhone = v!; _contact.clear(); }),
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<bool>(
                                title: Text(context.loc.emailOption, style: const TextStyle(fontFamily: 'NotoSansArabic', fontSize: 13, fontWeight: FontWeight.bold)),
                                value: false,
                                groupValue: _isPhone,
                                activeColor: _kBrandRed,
                                contentPadding: EdgeInsets.zero,
                                onChanged: (v) => setState(() { _isPhone = v!; _contact.clear(); }),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Text(
                          _isPhone ? context.loc.phoneFieldLabel : context.loc.emailFieldLabel,
                          style: const TextStyle(
                            fontFamily: 'NotoSansArabic',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kTextDark,
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
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              _isPhone ? Icons.phone_rounded : Icons.email_outlined,
                              color: Colors.grey.shade600,
                              size: 22,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade400),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade400),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: _kBrandRed,
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
                              backgroundColor: _kBrandRed,
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
