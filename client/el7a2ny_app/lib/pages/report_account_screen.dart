import 'package:flutter/material.dart';
import '../core/localization/app_strings.dart';
import '../app/main_shell_screen.dart';

class ReportAccountScreen extends StatefulWidget {
  const ReportAccountScreen({super.key});

  @override
  State<ReportAccountScreen> createState() => _ReportAccountScreenState();
}

class _ReportAccountScreenState extends State<ReportAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _accountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitReport() {
    if (_formKey.currentState!.validate()) {
      setState(() => _submitting = true);

      // We just mock sending the report
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.loc.isAr ? 'تم إرسال البلاغ بنجاح!' : 'Report submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Go back to the main shell
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => MainShellScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = context.loc;

    return Directionality(
      textDirection: loc.isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.isAr ? 'الإبلاغ عن حساب' : 'Report Account'),
          backgroundColor: theme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  loc.isAr
                      ? 'برجاء إدخال اسم الحساب أو بريده الإلكتروني والسبب'
                      : 'Please enter the account name or email and the reason',
                  style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                
                Text(
                  loc.isAr ? 'اسم الحساب / البريد الإلكتروني' : 'Account Name / Email',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _accountController,
                  decoration: InputDecoration(
                    hintText: loc.isAr ? 'مثال: ahmed123' : 'e.g. ahmed123',
                    filled: true,
                    fillColor: Colors.grey.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  validator: (v) => v == null || v.isEmpty
                      ? (loc.isAr ? 'برجاء إدخال الحساب' : 'Please enter the account')
                      : null,
                ),
                const SizedBox(height: 24),

                Text(
                  loc.isAr ? 'الوصف' : 'Description',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: loc.isAr ? 'اشرح بالتفصيل ما حدث...' : 'Explain in detail what happened...',
                    filled: true,
                    fillColor: Colors.grey.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  validator: (v) => v == null || v.isEmpty
                      ? (loc.isAr ? 'برجاء إدخال الوصف' : 'Please enter description')
                      : null,
                ),
                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: _submitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          loc.isAr ? 'إرسال البلاغ' : 'Submit Report',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
