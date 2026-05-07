import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:el7a2ny_app/app/main_shell_screen.dart';
import 'package:el7a2ny_app/core/api/api_exception.dart';
import 'package:el7a2ny_app/data/repositories/auth_repository.dart';
import 'package:el7a2ny_app/widgets/language_toggle_button.dart';
import 'package:el7a2ny_app/core/localization/app_strings.dart';
import 'package:el7a2ny_app/pages/forgot_password_screen.dart';
import 'package:el7a2ny_app/pages/sign_up_screen.dart';
import 'package:el7a2ny_app/pages/admin_screen.dart';
import 'package:el7a2ny_app/core/auth/auth_token_store.dart';
import '../widgets/language_toggle_button.dart';
import '../services/session_service.dart';
import '../widgets/global_fab_overlay.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _rememberMe = true;
  bool _loading = false;
  bool _obscurePassword = true;

  final _auth = AuthRepository();

  Color _kAccentGreen(BuildContext context) => Theme.of(context).primaryColor;
  Color _kTextDark(BuildContext context) => Theme.of(context).colorScheme.onSurface;
  Color _kPlaceholderGrey(BuildContext context) => Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await _auth.login(
        identifier: _identifier.text.trim(),
        password: _password.text,
        rememberMe: _rememberMe,
      );
      if (!mounted) return;
      
      // Check user type and route accordingly
      final userType = AuthTokenStore.userType;
      if (userType == "admin") {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (context) => const AdminScreen()),
        );
      } else {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (context) => MainShellScreen()),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GlobalFabController.hide();
    });

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: _kTextDark(context)),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          LanguageToggleButton(iconColor: _kTextDark(context)),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Text(
                  context.loc.welcomeBack,
                  style: TextStyle(
                    fontFamily: 'NotoSansArabic',
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: _kTextDark(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.loc.loginDesc,
                  style: TextStyle(
                    fontFamily: 'NotoSansArabic',
                    fontSize: 15,
                    color: _kTextDark(context).withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 36),
                Text(
                  context.loc.emailOrMobile,
                  style: TextStyle(
                    fontFamily: 'NotoSansArabic',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kTextDark(context),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _identifier,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontFamily: 'NotoSansArabic'),
                  decoration: _fieldDecoration(context, hint: context.loc.emailOrMobileHint),
                  inputFormatters: [
                    _SmartMobileFormatter(),
                  ],
                  validator: (v) {
                    if (v == null || v.isEmpty) return context.loc.requiredField;
                    // Check if input is numeric (mobile number) or email-like
                    final isNumeric = RegExp(r'^[0-9]+$').hasMatch(v);
                    if (isNumeric) {
                      if (v.length != 11) return context.loc.mobileValidation11;
                    } else {
                      if (!v.contains('@')) return context.loc.emailValidationAt;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  context.loc.password,
                  style: TextStyle(
                    fontFamily: 'NotoSansArabic',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kTextDark(context),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _password,
                  obscureText: _obscurePassword,
                  style: const TextStyle(fontFamily: 'NotoSansArabic'),
                  decoration: _fieldDecoration(context, hint: context.loc.passwordHint).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: _kPlaceholderGrey(context),
                        size: 22,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? context.loc.requiredField : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.loc.rememberMe,
                          style: TextStyle(
                            fontFamily: 'NotoSansArabic',
                            fontSize: 14,
                            color: _kTextDark(context),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _rememberMe,
                            activeColor: _kAccentGreen(context),
                            checkColor: Colors.white,
                            side: BorderSide(
                              color: _kTextDark(context).withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            onChanged: (v) {
                              setState(() => _rememberMe = v ?? false);
                            },
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) => const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            context.loc.forgotPasswordQ,
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              fontFamily: 'NotoSansArabic',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _kAccentGreen(context),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                SizedBox(
                  height: 54,
                  child: FilledButton(
                    onPressed: _loading ? null : _login,
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.onSurface,
                      foregroundColor: theme.colorScheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            context.loc.loginBtnMain,
                            style: const TextStyle(
                              fontFamily: 'NotoSansArabic',
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      context.loc.noAccountQ,
                      style: TextStyle(
                        fontFamily: 'NotoSansArabic',
                        fontSize: 14,
                        color: _kTextDark(context).withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => SignUpScreen(),
                          ),
                        );
                      },
                      child: Text(
                        context.loc.registerNow,
                        style: TextStyle(
                          fontFamily: 'NotoSansArabic',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _kAccentGreen(context),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(BuildContext context, {required String hint}) {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontFamily: 'NotoSansArabic',
        color: _kPlaceholderGrey(context),
        fontSize: 14,
      ),
      filled: true,
      fillColor: theme.colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.primaryColor, width: 1.2),
      ),
    );
  }
}

class _SmartMobileFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // If the input is purely digits and exceeds 11, prevent more typing
    if (RegExp(r'^[0-9]+$').hasMatch(newValue.text) &&
        newValue.text.length > 11) {
      return oldValue;
    }
    return newValue;
  }
}
