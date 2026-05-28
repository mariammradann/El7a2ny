import 'package:flutter/material.dart';
import '../core/localization/app_strings.dart';
import '../services/api_service.dart';

class AddSponsorPage extends StatefulWidget {
  const AddSponsorPage({super.key});

  @override
  State<AddSponsorPage> createState() => _AddSponsorPageState();
}

class _AddSponsorPageState extends State<AddSponsorPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  String _category = 'cars';
  String _level = 'silver';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final success = await ApiService.adminCreateSponsor(
        name: _nameController.text.trim(),
        companyType: _category,
        phone: _phoneController.text.trim(),
        contactEmail: _emailController.text.trim(),
        website: _websiteController.text.trim(),
        sponsorshipLevel: _level,
        status: 'active',
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.loc.isAr ? 'تمت إضافة الراعي بنجاح' : 'Sponsor added successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // return true so caller can refresh
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.loc.isAr ? 'فشل في إضافة الراعي. تحقق من البيانات.' : 'Failed to add sponsor. Check the details.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(loc.addSponsorTitle, style: const TextStyle(fontWeight: FontWeight.w900, fontFamily: 'NotoSansArabic')),
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
              // Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: loc.sponsorName,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.business_rounded),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? loc.requiredField : null,
              ),
              const SizedBox(height: 20),

              // Category
              DropdownButtonFormField<String>(
                value: _category,
                decoration: InputDecoration(
                  labelText: loc.sponsorCategory,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.category_rounded),
                ),
                items: [
                  DropdownMenuItem(value: 'cars', child: Text(loc.carCenters)),
                  DropdownMenuItem(value: 'insurance', child: Text(loc.insuranceSponsors)),
                  DropdownMenuItem(value: 'medical', child: Text(loc.isAr ? 'طبي' : 'Medical')),
                ],
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 20),

              // Phone
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: loc.sponsorPhone,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.phone_rounded),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? loc.requiredField : null,
              ),
              const SizedBox(height: 20),

              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: loc.isAr ? 'البريد الإلكتروني' : 'Contact Email',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.email_rounded),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return loc.requiredField;
                  if (!v.contains('@')) return loc.isAr ? 'بريد إلكتروني غير صالح' : 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Website (optional)
              TextFormField(
                controller: _websiteController,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: loc.isAr ? 'الموقع الإلكتروني (اختياري)' : 'Website (optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.language_rounded),
                ),
              ),
              const SizedBox(height: 20),

              // Sponsorship Level
              DropdownButtonFormField<String>(
                value: _level,
                decoration: InputDecoration(
                  labelText: loc.isAr ? 'مستوى الرعاية' : 'Sponsorship Level',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.star_rounded),
                ),
                items: const [
                  DropdownMenuItem(value: 'bronze', child: Text('Bronze')),
                  DropdownMenuItem(value: 'silver', child: Text('Silver')),
                  DropdownMenuItem(value: 'gold', child: Text('Gold')),
                  DropdownMenuItem(value: 'platinum', child: Text('Platinum')),
                ],
                onChanged: (v) => setState(() => _level = v!),
              ),
              const SizedBox(height: 40),

              // Submit button
              FilledButton(
                onPressed: _isLoading ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        loc.submitSponsor,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'NotoSansArabic'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

