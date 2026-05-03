import 'package:flutter/material.dart';
import '../core/localization/app_strings.dart';
import '../models/help_initiative_model.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';

class CreateInitiativeScreen extends StatefulWidget {
  const CreateInitiativeScreen({super.key});

  @override
  State<CreateInitiativeScreen> createState() => _CreateInitiativeScreenState();
}

class _CreateInitiativeScreenState extends State<CreateInitiativeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactController = TextEditingController();
  HelpCategory _selectedCategory = HelpCategory.other;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _loading = true);
      
      try {
        // 1. Fetch current user to get author info
        final user = await ApiService.fetchUserProfile();
        
        // 2. Create the initiative object
        final initiative = HelpInitiative(
          id: 0, // Backend will assign ID
          title: _titleController.text,
          description: _descriptionController.text,
          authorName: user.name,
          authorRole: user.role, // e.g. normal, volunteer
          category: _selectedCategory,
          location: _locationController.text,
          createdAt: DateTime.now(),
          contactInfo: [_contactController.text],
          participantsCount: 0,
          isActive: true,
          userId: user.id,
        );

        // 3. Send to backend
        final success = await ApiService.createHelpInitiative(initiative);

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.loc.isAr ? 'تم نشر المبادرة بنجاح!' : 'Initiative posted successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop(true);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.loc.isAr ? 'فشل في نشر المبادرة' : 'Failed to post initiative'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = context.loc;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.isAr ? 'إضافة مبادرة جديدة' : 'Add New Initiative'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel(loc.isAr ? 'العنوان' : 'Title'),
              TextFormField(
                controller: _titleController,
                decoration: _buildInputDecoration(loc.isAr ? 'مثال: توزيع وجبات إفطار' : 'e.g. Food distribution'),
                validator: (v) => v == null || v.isEmpty ? (loc.isAr ? 'برجاء إدخال العنوان' : 'Please enter a title') : null,
              ),
              const SizedBox(height: 20),
              
              _buildLabel(loc.isAr ? 'التصنيف' : 'Category'),
              DropdownButtonFormField<HelpCategory>(
                value: _selectedCategory,
                items: HelpCategory.values.map((cat) => DropdownMenuItem(
                  value: cat,
                  child: Text('${cat.categoryIcon} ${loc.helpCategoryDisplayName(cat.name)}'),
                )).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
                decoration: _buildInputDecoration(''),
              ),
              const SizedBox(height: 20),

              _buildLabel(loc.isAr ? 'الوصف' : 'Description'),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: _buildInputDecoration(loc.isAr ? 'اشرح المبادرة وكيف يمكن للآخرين المساعدة' : 'Explain the initiative and how others can help'),
                validator: (v) => v == null || v.isEmpty ? (loc.isAr ? 'برجاء إدخال الوصف' : 'Please enter a description') : null,
              ),
              const SizedBox(height: 20),

              _buildLabel(loc.isAr ? 'الموقع' : 'Location'),
              TextFormField(
                controller: _locationController,
                decoration: _buildInputDecoration(loc.isAr ? 'مثال: حي المعادي، القاهرة' : 'e.g. Maadi, Cairo'),
                validator: (v) => v == null || v.isEmpty ? (loc.isAr ? 'برجاء إدخال الموقع' : 'Please enter a location') : null,
              ),
              const SizedBox(height: 20),

              _buildLabel(loc.isAr ? 'بيانات التواصل' : 'Contact Info'),
              TextFormField(
                controller: _contactController,
                decoration: _buildInputDecoration(loc.isAr ? 'رقم الهاتف أو البريد الإلكتروني' : 'Phone number or Email'),
                validator: (v) => v == null || v.isEmpty ? (loc.isAr ? 'برجاء إدخال بيانات التواصل' : 'Please enter contact info') : null,
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        loc.isAr ? 'نشر المبادرة' : 'Post Initiative',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.withValues(alpha: 0.1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
