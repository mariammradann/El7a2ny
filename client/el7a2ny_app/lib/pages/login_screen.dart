import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../app/main_shell_screen.dart';
import '../core/api/api_exception.dart';
import '../data/repositories/auth_repository.dart';
import 'forgot_password_screen.dart';
import 'sign_up_screen.dart';

const Color _kAccentGreen = Color(0xFF76B947);
const Color _kBlackButton = Color(0xFF000000);
const Color _kTextDark = Color(0xFF424242);
const Color _kPlaceholderGrey = Color(0xFF9E9E9E);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _rememberMe = true;
  bool _loading = false;

  final _auth = AuthRepository();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      await _auth.login(
        email: _email.text.trim(),
        password: _password.text,
        rememberMe: _rememberMe,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (context) => const MainShellScreen(),
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
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _kTextDark),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Text(
                  'مرحبا مجددا !',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Unixel',
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'سجل دخولك.',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Unixel',
                    fontSize: 15,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 36),
                Text(
                  'الايميل',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Unixel',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kTextDark,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontFamily: 'Unixel'),
                  decoration: _fieldDecoration(hint: 'email@example.com'),
                ),
                const SizedBox(height: 20),
                Text(
                  'الباسورد',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Unixel',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kTextDark,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _password,
                  obscureText: true,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontFamily: 'Unixel'),
                  decoration: _fieldDecoration(hint: 'الباسورد'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'افتكرني',
                          style: TextStyle(
                            fontFamily: 'Unixel',
                            fontSize: 14,
                            color: _kTextDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _rememberMe,
                            activeColor: _kAccentGreen,
                            checkColor: Colors.white,
                            side: BorderSide(color: Colors.grey.shade700, width: 1.5),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                            'نسيت الباسورد؟',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontFamily: 'Unixel',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _kAccentGreen,
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
                      backgroundColor: _kBlackButton,
                      foregroundColor: Colors.white,
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
                            'سجل',
                            style: TextStyle(
                              fontFamily: 'Unixel',
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
                      'هل انت جديد معنا؟ ',
                      style: TextStyle(
                        fontFamily: 'Unixel',
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => const SignUpScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'سجل الآن',
                        style: TextStyle(
                          fontFamily: 'Unixel',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _kAccentGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _OrDivider(),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _SocialCircle(
                      backgroundColor: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      onTap: () => _socialTap('Google'),
                      child: const FaIcon(
                        FontAwesomeIcons.google,
                        size: 22,
                        color: Color(0xFF4285F4),
                      ),
                    ),
                    _SocialCircle(
                      backgroundColor: const Color(0xFF1877F2),
                      onTap: () => _socialTap('Facebook'),
                      child: const FaIcon(
                        FontAwesomeIcons.facebookF,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    _SocialCircle(
                      onTap: () => _socialTap('Instagram'),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFFF58529),
                            const Color(0xFFDD2A7B),
                            const Color(0xFF8134AF),
                          ],
                        ),
                      ),
                      child: const FaIcon(
                        FontAwesomeIcons.instagram,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    _SocialCircle(
                      backgroundColor: Colors.grey.shade200,
                      onTap: () => _socialTap('X'),
                      child: FaIcon(
                        FontAwesomeIcons.xTwitter,
                        color: Colors.grey.shade900,
                        size: 20,
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

  void _socialTap(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تسجيل عبر $name — قريباً')),
    );
  }

  InputDecoration _fieldDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontFamily: 'Unixel',
        color: _kPlaceholderGrey,
        fontSize: 14,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kTextDark, width: 1.2),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _DashedLine(color: Colors.grey.shade400)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'او',
            style: TextStyle(
              fontFamily: 'Unixel',
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Expanded(child: _DashedLine(color: Colors.grey.shade400)),
      ],
    );
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dash = 5.0;
        const gap = 4.0;
        final w = constraints.maxWidth;
        final count = (w / (dash + gap)).floor();
        return Row(
          children: List.generate(count, (i) {
            return Padding(
              padding: EdgeInsets.only(right: i < count - 1 ? gap : 0),
              child: Container(
                width: dash,
                height: 1,
                color: color,
              ),
            );
          }),
        );
      },
    );
  }
}

class _SocialCircle extends StatelessWidget {
  const _SocialCircle({
    required this.onTap,
    required this.child,
    this.backgroundColor,
    this.decoration,
    this.border,
  });

  final VoidCallback onTap;
  final Widget child;
  final Color? backgroundColor;
  final BoxDecoration? decoration;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 52,
          height: 52,
          decoration: decoration ??
              BoxDecoration(
                shape: BoxShape.circle,
                color: backgroundColor ?? Colors.white,
                border: border,
              ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
