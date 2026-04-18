import 'package:flutter/material.dart';
import '../core/api/api_exception.dart';
import '../data/repositories/auth_repository.dart';
import '../core/localization/app_strings.dart';
import '../widgets/language_toggle_button.dart';

const Color _kBrandRed = Color(0xFFE44646);
const Color _kCardPink = Color(0xFFFDECEC);
const Color _kTextDark = Color(0xFF424242);

class ChangePasswordScreen extends StatefulWidget {
  final String oldPassword;
  const ChangePasswordScreen({super.key, required this.oldPassword});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _loading = false;
  final _auth = AuthRepository();

  @override
  void dispose() {
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _change() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    
    setState(() => _loading = true);
    try {
      await _auth.changePassword(
        oldPassword: widget.oldPassword,
        newPassword: _newPassword.text,
      );
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.loc.passwordChangedSuccess),
          backgroundColor: Colors.green,
        ),
      );
      
      // Pop all the way back to settings
      Navigator.of(context).popUntil((route) => route.isFirst || route.settings.name == '/settings');
      // If no route name was set, we might need a better way. 
      // For now, since it's a simple app, we can just pop twice.
      Navigator.of(context).pop(); 
      Navigator.of(context).pop();
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
          context.loc.changePassword,
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
                          child: const Icon(
                            Icons.lock_reset_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        context.loc.changePassword,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'NotoSansArabic',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        context.loc.newPasswordLabel,
                        style: const TextStyle(
                          fontFamily: 'NotoSansArabic',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kTextDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _newPassword,
                        obscureText: true,
                        style: const TextStyle(fontFamily: 'NotoSansArabic'),
                        validator: (v) {
                          if (v == null || v.trim().length < 6) return context.loc.min6Chars;
                          return null;
                        },
                        decoration: _inputDecoration(hint: context.loc.passwordHint),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        context.loc.confirmNewPasswordLabel,
                        style: const TextStyle(
                          fontFamily: 'NotoSansArabic',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kTextDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _confirmPassword,
                        obscureText: true,
                        style: const TextStyle(fontFamily: 'NotoSansArabic'),
                        validator: (v) {
                          if (v != _newPassword.text) return context.loc.noMatch;
                          return null;
                        },
                        decoration: _inputDecoration(hint: context.loc.confirmPassword),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        height: 52,
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _loading ? null : _change,
                          style: FilledButton.styleFrom(
                            backgroundColor: _kBrandRed,
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

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 22),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
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
        borderSide: const BorderSide(color: _kBrandRed, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
    );
  }
}
