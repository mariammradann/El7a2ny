import 'package:flutter/material.dart';
import '../core/localization/app_strings.dart';

class BecomePartnerPage extends StatefulWidget {
  const BecomePartnerPage({super.key});

  @override
  State<BecomePartnerPage> createState() => _BecomePartnerPageState();
}

class _BecomePartnerPageState extends State<BecomePartnerPage> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _contactController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _companyController.dispose();
    _contactController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.loc.isAr ? 'تم إرسال طلب الشراكة بنجاح' : 'Partnership application sent successfully')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(loc.partnershipForm, style: const TextStyle(fontWeight: FontWeight.w900, fontFamily: 'NotoSansArabic')),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                loc.partnerProgramDesc,
                style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 14, fontFamily: 'NotoSansArabic'),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _companyController,
                decoration: InputDecoration(
                  labelText: loc.companyName,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.apartment_rounded),
                ),
                validator: (v) => v!.isEmpty ? loc.requiredField : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _contactController,
                decoration: InputDecoration(
                  labelText: loc.contactPerson,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
                validator: (v) => v!.isEmpty ? loc.requiredField : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: loc.sponsorPhone,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.phone_rounded),
                ),
                validator: (v) => v!.isEmpty ? loc.requiredField : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: loc.partnershipMessage,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.chat_bubble_outline_rounded),
                ),
                validator: (v) => v!.isEmpty ? loc.requiredField : null,
              ),
              const SizedBox(height: 40),
              FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(loc.sendApplication, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'NotoSansArabic')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
