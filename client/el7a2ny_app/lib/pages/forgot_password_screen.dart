import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api/api_exception.dart';
import '../core/strings/app_strings.dart';
import '../data/repositories/auth_repository.dart';
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
  final _phone = TextEditingController();
  bool _sending = false;

  final _auth = AuthRepository();

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final phone = _phone.text.trim();
    setState(() => _sending = true);
    try {
      await _auth.requestPasswordReset(phone: phone);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => OtpVerificationScreen(
            phoneNumber: phone,
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
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
            'نسيت الباسورد',
            style: TextStyle(
              fontFamily: 'Unixel',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _kBrandRed,
            ),
          ),
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
                            child: const Icon(
                              Icons.phone_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          'اكتب رقم موبايلك',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Unixel',
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'هنبعتلك كود تحقق في رساله',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Unixel',
                            fontSize: 14,
                            height: 1.4,
                            color: _kTextDark,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'رقم الموبايل',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFamily: 'Unixel',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kTextDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontFamily: 'Unixel'),
                          validator: (v) {
                            if (v == null || v.trim().length < 10) {
                              return 'أدخل رقم موبايل صحيح';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: AppStrings.phoneFormatHint,
                            hintStyle: TextStyle(
                              fontFamily: 'Unixel',
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.phone_rounded,
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
                                    'ارسال كود التحقق',
                                    style: TextStyle(
                                      fontFamily: 'Unixel',
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
      ),
    );
  }
}
