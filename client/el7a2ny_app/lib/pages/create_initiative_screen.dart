import 'package:flutter/material.dart';
import '../models/help_initiative_model.dart';
import '../core/localization/app_strings.dart';

class CreateInitiativeScreen extends StatefulWidget {
  const CreateInitiativeScreen({super.key});

  @override
  State<CreateInitiativeScreen> createState() => _CreateInitiativeScreenState();
}

class _CreateInitiativeScreenState extends State<CreateInitiativeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  HelpCategory _selectedCategory = HelpCategory.other;
  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      // Mock creation - in a real app this would call ApiService.createHelpInitiative
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.loc.isAr ? 'تم إنشاء المبادرة بنجاح' : 'Initiative created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = context.loc;
    final isAr = loc.isAr;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isAr ? 'إنشاء مبادرة جديدة' : 'Create New Initiative'),
          backgroundColor: theme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: _loading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'تفاصيل المبادرة' : 'Initiative Details',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                      controller: _titleCtrl,
                      label: isAr ? 'عنوان المبادرة' : 'Title',
                      hint: isAr ? 'مثال: توزيع وجبات إفطار' : 'e.g. Free Breakfast Distribution',
                      validator: (v) => v!.isEmpty ? (isAr ? 'برجاء إدخال العنوان' : 'Please enter title') : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _descCtrl,
                      label: isAr ? 'الوصف' : 'Description',
                      hint: isAr ? 'اشرح مبادرتك وكيف يمكن للناس المساعدة' : 'Explain your initiative and how people can help',
                      maxLines: 4,
                      validator: (v) => v!.isEmpty ? (isAr ? 'برجاء إدخال الوصف' : 'Please enter description') : null,
                    ),
                    const SizedBox(height: 16),
                    Text(isAr ? 'التصنيف' : 'Category', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildCategoryDropdown(context),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _locationCtrl,
                      label: isAr ? 'الموقع' : 'Location',
                      hint: isAr ? 'مثال: مدينة نصر، القاهرة' : 'e.g. Nasr City, Cairo',
                      validator: (v) => v!.isEmpty ? (isAr ? 'برجاء إدخال الموقع' : 'Please enter location') : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _contactCtrl,
                      label: isAr ? 'معلومات التواصل (هاتف أو إيميل)' : 'Contact Info (Phone or Email)',
                      hint: isAr ? 'مثال: 01012345678' : 'e.g. 01012345678',
                      validator: (v) => v!.isEmpty ? (isAr ? 'برجاء إدخال معلومات التواصل' : 'Please enter contact info') : null,
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          isAr ? 'نشر المبادرة' : 'Post Initiative',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainer,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<HelpCategory>(
          value: _selectedCategory,
          isExpanded: true,
          onChanged: (v) {
            if (v != null) setState(() => _selectedCategory = v);
          },
          items: HelpCategory.values.map((cat) {
            return DropdownMenuItem(
              value: cat,
              child: Row(
                children: [
                  Text(cat.categoryIcon),
                  const SizedBox(width: 12),
                  Text(context.loc.helpCategoryName(cat.name)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
