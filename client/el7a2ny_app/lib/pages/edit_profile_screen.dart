import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../core/localization/app_strings.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../data/models/emergency_contact.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _nationalId;
  late final TextEditingController _skills;

  String? _gender;
  String? _bloodType;
  bool _hasVehicle = false;
  String? _smartWatch;
  String? _sensor;

  late final List<_ContactControllers> _contacts;

  @override
  void initState() {
    super.initState();
    _firstName = TextEditingController(text: widget.user.firstName);
    _lastName = TextEditingController(text: widget.user.lastName);
    _email = TextEditingController(text: widget.user.email);
    _phone = TextEditingController(text: widget.user.phone);
    _nationalId = TextEditingController(text: widget.user.nationalId);
    _skills = TextEditingController(text: widget.user.skills);
    _gender = widget.user.gender;
    _bloodType = widget.user.bloodType;
    _hasVehicle = widget.user.hasVehicle;
    _smartWatch = widget.user.smartWatchModel;
    _sensor = widget.user.sensorModel;

    _contacts = widget.user.emergencyContacts.map((c) => _ContactControllers(
      nameText: c.name,
      phoneText: c.phone,
      relationText: c.relationship,
    )).toList();
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _nationalId.dispose();
    _skills.dispose();
    for (var c in _contacts) { c.dispose(); }
    super.dispose();
  }

  void _addContact() => setState(() => _contacts.add(_ContactControllers()));

  Future<void> _pickContact(int index) async {
    if (await Permission.contacts.request().isGranted) {
      final contactId = await FlutterContacts.native.showPicker();
      if (contactId != null) {
        final full = await FlutterContacts.get(contactId, properties: {ContactProperty.phone});
        if (full != null && mounted) {
          setState(() {
            _contacts[index].name.text = full.displayName ?? '';
            if (full.phones.isNotEmpty) {
              _contacts[index].phone.text = full.phones.first.number.replaceAll(RegExp(r'[^\d]'), '');
            }
          });
        }
      }
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.loc.allowContactAccess)));
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    try {
      final updatedUser = UserModel(
        id: widget.user.id,
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        role: widget.user.role,
        status: widget.user.status,
        nationalId: _nationalId.text.trim(),
        birthDate: widget.user.birthDate,
        gender: _gender ?? 'male',
        bloodType: _bloodType ?? 'O+',
        hasVehicle: _hasVehicle,
        volunteerEnabled: widget.user.volunteerEnabled,
        skills: _skills.text.trim(),
        smartWatchModel: _smartWatch,
        sensorModel: _sensor,
        emergencyContacts: _contacts.map((c) => EmergencyContact(
          name: c.name.text.trim(),
          phone: c.phone.text.trim(),
          relationship: c.relation.text.trim(),
        )).toList(),
        certifications: widget.user.certifications,
        profileImageUrl: widget.user.profileImageUrl,
      );

      await ApiService.updateUserProfile(updatedUser);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.loc.isAr ? 'تم حفظ التغييرات بنجاح' : 'Changes saved successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = context.loc;
    final isAr = loc.isAr;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'تعديل الملف الشخصي' : 'Edit Profile', style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Basic Info
              _buildSection(
                title: loc.basicInfo,
                children: [
                  Row(
                    children: [
                      Expanded(child: _AppField(controller: _firstName, label: loc.firstNameLabel)),
                      const SizedBox(width: 12),
                      Expanded(child: _AppField(controller: _lastName, label: loc.lastNameLabel)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _AppField(
                    controller: _email,
                    label: loc.emailLabel,
                    keyboardType: TextInputType.emailAddress,
                    prefix: Icons.email_outlined,
                  ),
                  const SizedBox(height: 16),
                  _AppField(
                    controller: _phone,
                    label: loc.mobileNum,
                    keyboardType: TextInputType.phone,
                    prefix: Icons.phone_outlined,
                    formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
                  ),
                  const SizedBox(height: 16),
                  _AppField(
                    controller: _nationalId,
                    label: loc.nationalIdLabel,
                    keyboardType: TextInputType.number,
                    prefix: Icons.badge_outlined,
                    formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(14)],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. Medical Info
              _buildSection(
                title: isAr ? 'المعلومات الطبية' : 'Medical Information',
                children: [
                  Row(
                    children: [
                      Expanded(child: _AppDropdown<String>(
                        label: loc.genderLabel,
                        value: _gender,
                        items: const ['male', 'female'],
                        itemLabel: (v) => v == 'male' ? loc.maleOption : loc.femaleOption,
                        onChanged: (v) => setState(() => _gender = v),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _AppDropdown<String>(
                        label: loc.bloodTypeLabel,
                        value: _bloodType,
                        items: const ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'],
                        onChanged: (v) => setState(() => _bloodType = v),
                      )),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 3. Emergency Contacts
              _buildSection(
                title: loc.emergencyContacts,
                trailing: TextButton.icon(
                  onPressed: _addContact, 
                  icon: const Icon(Icons.add, size: 18), 
                  label: Text(loc.addContactsLabel, style: const TextStyle(fontSize: 12)),
                ),
                children: [
                  if (_contacts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(isAr ? 'لا يوجد جهات اتصال' : 'No contacts added', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                    ),
                  ...List.generate(_contacts.length, (i) => Padding(
                    padding: EdgeInsets.only(top: i == 0 ? 0 : 20),
                    child: _EditContactItem(
                      index: i + 1, 
                      controllers: _contacts[i], 
                      onPick: () => _pickContact(i),
                      onRemove: () => setState(() => _contacts.removeAt(i)),
                    ),
                  )),
                ],
              ),
              const SizedBox(height: 24),

              // 4. Hardware & Assets
              _buildSection(
                title: isAr ? 'الأجهزة والأصول' : 'Hardware & Assets',
                children: [
                  _AppDropdown<String>(
                    label: loc.hasVehicleLabel,
                    value: _hasVehicle ? 'yes' : 'no',
                    items: const ['yes', 'no'],
                    itemLabel: (v) => v == 'yes' ? loc.yes : loc.no,
                    onChanged: (v) => setState(() => _hasVehicle = v == 'yes'),
                  ),
                  const SizedBox(height: 16),
                  _AppDropdown<String>(
                    label: loc.smartWatchLabel,
                    value: _smartWatch,
                    items: const ['Apple Watch', 'Samsung Galaxy Watch', 'Huawei Watch', 'other', 'Apple Watch Series 9'], // Added user's model to avoid crash
                    itemLabel: (v) => v == 'other' ? loc.otherModel : v,
                    onChanged: (v) => setState(() => _smartWatch = v),
                    isRequired: false,
                  ),
                  const SizedBox(height: 16),
                  _AppDropdown<String>(
                    label: loc.sensorLabel,
                    value: _sensor,
                    items: const ['pulse', 'glucose', 'other', 'Pulse Oximeter'], // Added user's model to avoid crash
                    itemLabel: (v) => v == 'pulse' ? loc.pulseSensor : (v == 'glucose' ? loc.glucoseSensor : loc.otherModel),
                    onChanged: (v) => setState(() => _sensor = v),
                    isRequired: false,
                  ),
                ],
              ),

              // 5. Volunteer Info
              if (widget.user.volunteerEnabled) ...[
                const SizedBox(height: 24),
                _buildSection(
                  title: loc.volunteerLabel,
                  children: [
                    _AppField(controller: _skills, label: isAr ? 'المهارات' : 'Skills', maxLines: 3),
                  ],
                ),
              ],
              const SizedBox(height: 40),
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: _saving ? null : _submit,
                  style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: _saving ? const CircularProgressIndicator(color: Colors.white) : Text(isAr ? 'حفظ التغييرات' : 'Save Changes', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children, Widget? trailing}) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryColor, fontSize: 16)),
              if (trailing != null) trailing,
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _EditContactItem extends StatelessWidget {
  final int index;
  final _ContactControllers controllers;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _EditContactItem({
    required this.index, 
    required this.controllers, 
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${loc.contactNLabel} $index', style: const TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                IconButton(onPressed: onPick, icon: const Icon(Icons.contact_phone_outlined, size: 20)),
                IconButton(onPressed: onRemove, icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        _AppField(controller: controllers.name, label: loc.theName),
        const SizedBox(height: 12),
        _AppField(controller: controllers.relation, label: loc.relationLabel),
        const SizedBox(height: 12),
        _AppField(
          controller: controllers.phone, 
          label: loc.mobileNum, 
          keyboardType: TextInputType.phone,
          formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
        ),
      ],
    );
  }
}

class _AppField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final IconData? prefix;
  final int maxLines;
  final List<TextInputFormatter>? formatters;

  const _AppField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.prefix,
    this.maxLines = 1,
    this.formatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefix != null ? Icon(prefix, size: 20) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: (v) => (v == null || v.isEmpty) ? context.loc.requiredField : null,
    );
  }
}

class _AppDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T)? itemLabel;
  final ValueChanged<T?> onChanged;
  final bool isRequired;

  const _AppDropdown({
    required this.label,
    required this.value,
    required this.items,
    this.itemLabel,
    required this.onChanged,
    this.isRequired = true,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure value is in items to avoid crash
    final List<T> safeItems = items.toList();
    if (value != null && !items.contains(value)) {
      safeItems.add(value!);
    }

    return DropdownButtonFormField<T>(
      initialValue: value,
      items: safeItems.map((e) => DropdownMenuItem(value: e, child: Text(itemLabel != null ? itemLabel!(e) : e.toString()))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: isRequired ? (v) => v == null ? context.loc.requiredField : null : null,
    );
  }
}

class _ContactControllers {
  final name = TextEditingController();
  final relation = TextEditingController();
  final phone = TextEditingController();
  
  _ContactControllers({String? nameText, String? relationText, String? phoneText}) {
    name.text = nameText ?? '';
    relation.text = relationText ?? '';
    phone.text = phoneText ?? '';
  }

  void dispose() { name.dispose(); relation.dispose(); phone.dispose(); }
}
