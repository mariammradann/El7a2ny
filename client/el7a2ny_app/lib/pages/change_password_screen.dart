import 'package:flutter/material.dart';
import '../core/api/api_exception.dart';
import '../data/repositories/auth_repository.dart';
import '../core/localization/app_strings.dart';
import '../widgets/language_toggle_button.dart';


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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryRed = theme.primaryColor;
    final onSurface = theme.colorScheme.onSurface;
    final surfaceColor = theme.colorScheme.surface;
    final cardColor = isDark ? theme.colorScheme.surfaceContainer : theme.primaryColor.withValues(alpha: 0.05);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: onSurface),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          context.loc.changePassword,
          style: TextStyle(
            fontFamily: 'NotoSansArabic',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: primaryRed,
          ),
        ),
        actions: [
          LanguageToggleButton(iconColor: primaryRed),
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
                    color: cardColor,
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
                            color: primaryRed,
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
                        style: TextStyle(
                          fontFamily: 'NotoSansArabic',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: onSurface,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        context.loc.newPasswordLabel,
                        style: TextStyle(
                          fontFamily: 'NotoSansArabic',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _newPassword,
                        obscureText: true,
                        style: TextStyle(fontFamily: 'NotoSansArabic', color: onSurface),
                        validator: (v) {
                          if (v == null || v.trim().length < 6) return context.loc.min6Chars;
                          return null;
                        },
                        decoration: _inputDecoration(
                          hint: context.loc.passwordHint,
                          theme: theme,
                          onSurface: onSurface,
                          primaryRed: primaryRed,
                          surfaceColor: surfaceColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        context.loc.confirmNewPasswordLabel,
                        style: TextStyle(
                          fontFamily: 'NotoSansArabic',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _confirmPassword,
                        obscureText: true,
                        style: TextStyle(fontFamily: 'NotoSansArabic', color: onSurface),
                        validator: (v) {
                          if (v != _newPassword.text) return context.loc.noMatch;
                          return null;
                        },
                        decoration: _inputDecoration(
                          hint: context.loc.confirmPassword,
                          theme: theme,
                          onSurface: onSurface,
                          primaryRed: primaryRed,
                          surfaceColor: surfaceColor,
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        height: 52,
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _loading ? null : _change,
                          style: FilledButton.styleFrom(
                            backgroundColor: primaryRed,
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
    required ThemeData theme,
    required Color onSurface,
    required Color primaryRed,
    required Color surfaceColor,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: onSurface.withValues(alpha: 0.4)),
      prefixIcon: Icon(Icons.lock_outline_rounded, size: 22, color: onSurface.withValues(alpha: 0.5)),
      filled: true,
      fillColor: surfaceColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: onSurface.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: onSurface.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryRed, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.error),
      ),
    );
  }
}
