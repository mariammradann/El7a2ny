import 'package:flutter/material.dart';

import 'package:el7a2ny_app/app/main_shell_screen.dart';
import 'package:el7a2ny_app/core/api/api_exception.dart';
import 'package:el7a2ny_app/data/repositories/auth_repository.dart';
import 'package:el7a2ny_app/widgets/language_toggle_button.dart';
import 'package:el7a2ny_app/core/localization/app_strings.dart';
import 'package:el7a2ny_app/pages/forgot_password_screen.dart';
import 'package:el7a2ny_app/pages/sign_up_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _rememberMe = true;
  bool _loading = false;

  final _auth = AuthRepository();

  Color _kAccentGreen(BuildContext context) => Theme.of(context).primaryColor;
  Color _kTextDark(BuildContext context) => Theme.of(context).colorScheme.onSurface;
  Color _kPlaceholderGrey(BuildContext context) => Theme.of(context).colorScheme.onSurface.withOpacity(0.5);

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      await _auth.login(
        identifier: _identifier.text.trim(),
        password: _password.text,
        rememberMe: _rememberMe,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (context) => const MainShellScreen()),
      );
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
                  color: _kTextDark(context).withOpacity(0.6),
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
              TextField(
                controller: _identifier,
                keyboardType: TextInputType.visiblePassword,
                style: const TextStyle(fontFamily: 'NotoSansArabic'),
                decoration: _fieldDecoration(context, hint: context.loc.emailOrMobileHint),
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
              TextField(
                controller: _password,
                obscureText: true,
                style: const TextStyle(fontFamily: 'NotoSansArabic'),
                decoration: _fieldDecoration(context, hint: context.loc.passwordHint),
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
                            color: _kTextDark(context).withOpacity(0.4),
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
                      color: _kTextDark(context).withOpacity(0.7),
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
        borderSide: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.primaryColor, width: 1.2),
      ),
    );
  }
}
