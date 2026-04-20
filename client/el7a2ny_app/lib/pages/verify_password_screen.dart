import 'package:flutter/material.dart';
import '../core/api/api_exception.dart';
import '../data/repositories/auth_repository.dart';
import '../core/localization/app_strings.dart';
import '../widgets/language_toggle_button.dart';
import 'forgot_password_screen.dart';
import 'change_password_screen.dart';

/// متوافق مع أحمر التطبيق في الشاشات العربية الأخرى.

class VerifyCurrentPasswordScreen extends StatefulWidget {
  const VerifyCurrentPasswordScreen({super.key});

  @override
  State<VerifyCurrentPasswordScreen> createState() => _VerifyCurrentPasswordScreenState();
}

class _VerifyCurrentPasswordScreenState extends State<VerifyCurrentPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  bool _loading = false;
  final _auth = AuthRepository();

  Color _kBrandRed(BuildContext context) => Theme.of(context).primaryColor;
  Color _kSectionColor(BuildContext context) => Theme.of(context).brightness == Brightness.light
      ? Theme.of(context).primaryColor.withValues(alpha: 0.05)
      : Theme.of(context).colorScheme.surfaceContainer;
  Color _kTextDark(BuildContext context) => Theme.of(context).colorScheme.onSurface;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    
    setState(() => _loading = true);
    try {
      await _auth.validateCurrentPassword(_password.text);
      if (!mounted) return;
      
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => ChangePasswordScreen(oldPassword: _password.text),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
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
          context.loc.changePassword,
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
                          child: const Icon(
                            Icons.lock_person_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        context.loc.enterCurrentPassword,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'NotoSansArabic',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        context.loc.currentPasswordLabel,
                        style: TextStyle(
                          fontFamily: 'NotoSansArabic',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textDark.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _password,
                        obscureText: true,
                        style: const TextStyle(fontFamily: 'NotoSansArabic'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return context.loc.requiredField;
                          return null;
                        },
                        decoration: _inputDecoration(
                          hint: context.loc.passwordHint,
                          textDark: textDark,
                          brandRed: brandRed,
                          fillColor: theme.colorScheme.surface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (context) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: Text(
                            context.loc.forgotPasswordQ,
                            style: TextStyle(
                              fontFamily: 'NotoSansArabic',
                              color: brandRed,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 52,
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _loading ? null : _verify,
                          style: FilledButton.styleFrom(
                            backgroundColor: brandRed,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 26,
                                  height: 26,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  context.loc.okBtn,
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

  InputDecoration _inputDecoration({
    required String hint,
    required Color textDark,
    required Color brandRed,
    required Color fillColor,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: textDark.withValues(alpha: 0.4)),
      prefixIcon: Icon(Icons.lock_outline_rounded, size: 22, color: textDark.withValues(alpha: 0.5)),
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
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
        borderSide: BorderSide(color: brandRed, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
    );
  }
}
