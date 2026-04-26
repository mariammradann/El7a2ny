import 'package:flutter/material.dart';
import '../core/localization/app_strings.dart';

class EditPlanPage extends StatefulWidget {
  const EditPlanPage({super.key});

  @override
  State<EditPlanPage> createState() => _EditPlanPageState();
}

class _EditPlanPageState extends State<EditPlanPage> {
  final _priceController = TextEditingController(text: '299');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.loc.isAr ? 'تم حفظ تعديلات الخطة بنجاح' : 'Plan changes saved successfully')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(loc.editPlanTitle, style: const TextStyle(fontWeight: FontWeight.w900, fontFamily: 'NotoSansArabic')),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                loc.isAr ? 'عدل سعر الاشتراك المميز والمزايا' : 'Modify premium subscription price and features',
                style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 14, fontFamily: 'NotoSansArabic'),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: loc.planPrice,
                  suffixText: 'EGP',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.payments_rounded),
                ),
                validator: (v) => v!.isEmpty ? loc.requiredField : null,
              ),
              const SizedBox(height: 40),
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(loc.saveChanges, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'NotoSansArabic')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
