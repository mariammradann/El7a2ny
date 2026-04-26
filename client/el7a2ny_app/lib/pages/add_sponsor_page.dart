import 'package:flutter/material.dart';
import '../core/localization/app_strings.dart';

class AddSponsorPage extends StatefulWidget {
  const AddSponsorPage({super.key});

  @override
  State<AddSponsorPage> createState() => _AddSponsorPageState();
}

class _AddSponsorPageState extends State<AddSponsorPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _servicesController = TextEditingController();
  String _category = 'Cars';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _servicesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Simulate submission
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.loc.isAr ? 'تمت إضافة الراعي بنجاح' : 'Sponsor added successfully')),
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
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: loc.sponsorName,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.business_rounded),
                ),
                validator: (v) => v!.isEmpty ? loc.requiredField : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: InputDecoration(
                  labelText: loc.sponsorCategory,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.category_rounded),
                ),
                items: [
                  DropdownMenuItem(value: 'Cars', child: Text(loc.carCenters)),
                  DropdownMenuItem(value: 'Insurance', child: Text(loc.insuranceSponsors)),
                ],
                onChanged: (v) => setState(() => _category = v!),
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
                controller: _servicesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: loc.sponsorServices,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.list_rounded),
                ),
                validator: (v) => v!.isEmpty ? loc.requiredField : null,
              ),
              const SizedBox(height: 40),
              FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(loc.submitSponsor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'NotoSansArabic')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
