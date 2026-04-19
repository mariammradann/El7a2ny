import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import 'package:el7a2ny_app/core/api/api_exception.dart';
import 'package:el7a2ny_app/core/services/social_auth_service.dart';
import 'package:el7a2ny_app/data/repositories/auth_repository.dart';
import 'package:el7a2ny_app/core/localization/app_strings.dart';
import 'package:el7a2ny_app/widgets/language_toggle_button.dart';

class SignUpScreen extends StatefulWidget {
  final SocialProfile? socialProfile;
  const SignUpScreen({super.key, this.socialProfile});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthRepository();

  bool _micGranted = false;
  bool _locationGranted = false;
  bool _cameraGranted = false;
  bool _submitting = false;
  bool _volunteerEnabled = false;

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _nationalId = TextEditingController();
  final _day = TextEditingController();
  final _month = TextEditingController();
  final _year = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _skills = TextEditingController();

  String? _gender;
  String? _bloodType;
  String? _hasVehicle;
  String? _smartWatch;
  String? _sensor;
  String? _selectedCertificateName;

  final List<_ContactControllers> _contacts = [
    _ContactControllers(),
    _ContactControllers(),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.socialProfile != null) {
      _firstName.text = widget.socialProfile!.firstName;
      _lastName.text = widget.socialProfile!.lastName;
      _email.text = widget.socialProfile!.email;
    }
  }

  @override
  void dispose() {
    _firstName.dispose(); _lastName.dispose(); _email.dispose(); _phone.dispose();
    _nationalId.dispose(); _day.dispose(); _month.dispose(); _year.dispose();
    _password.dispose(); _confirmPassword.dispose(); _skills.dispose();
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

  Future<void> _pickCertificate() async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'png']);
    if (result != null && mounted) {
      setState(() => _selectedCertificateName = result.files.single.name);
    }
  }

  Map<String, dynamic> _buildRegistrationBody() {
    return {
      'first_name': _firstName.text.trim(),
      'last_name': _lastName.text.trim(),
      'email': _email.text.trim(),
      'phone': _phone.text.trim(),
      'national_id': _nationalId.text.trim(),
      'birth_date': '${_year.text.trim()}-${_month.text.trim()}-${_day.text.trim()}',
      'gender': _gender,
      'blood_type': _bloodType,
      'has_vehicle': _hasVehicle == 'yes',
      'permission_mic': _micGranted,
      'permission_location': _locationGranted,
      'permission_camera': _cameraGranted,
      if (widget.socialProfile == null) 'password': _password.text,
      if (widget.socialProfile != null) 'social_provider': widget.socialProfile!.provider,
      'volunteer_enabled': _volunteerEnabled,
      'skills': _skills.text.trim(),
      'smart_watch_model': _smartWatch,
      'sensor_model': _sensor,
      'emergency_contacts': _contacts.map((c) => {
        'name': c.name.text.trim(),
        'relation': c.relation.text.trim(),
        'phone': c.phone.text.trim(),
      }).toList(),
    };
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      await _auth.register(_buildRegistrationBody());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.loc.accountCreated)));
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = context.loc;
    final primary = theme.primaryColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(loc.signUpTitle, style: const TextStyle(fontWeight: FontWeight.w900, fontFamily: 'NotoSansArabic')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [const LanguageToggleButton(), const SizedBox(width: 8)],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(loc.signUpSubtitle, textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontFamily: 'NotoSansArabic')),
              const SizedBox(height: 24),
              
              _PremiumSection(
                title: loc.basicInfo,
                child: Column(
                  children: [
                    _AvatarUploader(onTap: () {}, primary: primary),
                    const SizedBox(height: 24),
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
                      validator: (v) {
                        if (v == null || v.isEmpty) return context.loc.requiredField;
                        if (!v.contains('@')) return context.loc.emailValidationAt;
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _AppField(
                      controller: _phone,
                      label: loc.mobileNum,
                      keyboardType: TextInputType.phone,
                      prefix: Icons.phone_outlined,
                      formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
                      validator: (v) => (v == null || v.trim().length != 11) ? context.loc.mobileValidation11 : null,
                    ),
                    const SizedBox(height: 16),
                    _AppField(
                      controller: _nationalId,
                      label: loc.nationalIdLabel,
                      keyboardType: TextInputType.number,
                      prefix: Icons.badge_outlined,
                      formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(14)],
                      validator: (v) => (v == null || v.trim().length != 14) ? context.loc.nationalIdValidation : null,
                    ),
                    const SizedBox(height: 16),
                    _DateRow(day: _day, month: _month, year: _year),
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
                    _AppDropdown<String>(
                      label: loc.hasVehicleLabel,
                      value: _hasVehicle,
                      items: const ['yes', 'no'],
                      itemLabel: (v) => v == 'yes' ? loc.yes : loc.no,
                      onChanged: (v) => setState(() => _hasVehicle = v),
                    ),
                    if (widget.socialProfile == null) ...[
                      const SizedBox(height: 16),
                      _AppField(controller: _password, label: loc.password, obscure: true, prefix: Icons.lock_outline),
                      const SizedBox(height: 16),
                      _AppField(controller: _confirmPassword, label: loc.confirmPassword, obscure: true, prefix: Icons.lock_reset_outlined),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              _PremiumSection(
                title: loc.emergencyContacts,
                trailing: TextButton.icon(onPressed: _addContact, icon: const Icon(Icons.add), label: Text(loc.addContactsLabel)),
                child: Column(
                  children: List.generate(_contacts.length, (i) => Padding(
                    padding: EdgeInsets.only(top: i == 0 ? 0 : 20),
                    child: _ContactItem(index: i + 1, controllers: _contacts[i], onPick: () => _pickContact(i)),
                  )),
                ),
              ),

              const SizedBox(height: 20),
              _PremiumSection(
                title: loc.smartWatchLabel,
                child: _AppDropdown<String>(
                  label: loc.selectModel,
                  value: _smartWatch,
                  items: const ['Apple Watch', 'Samsung Galaxy Watch', 'Huawei Watch', 'other'],
                  itemLabel: (v) => v == 'other' ? loc.otherModel : v,
                  onChanged: (v) => setState(() => _smartWatch = v),
                  isRequired: false,
                ),
              ),

              const SizedBox(height: 20),
              _PremiumSection(
                title: loc.sensorLabel,
                child: _AppDropdown<String>(
                  label: loc.selectModel,
                  value: _sensor,
                  items: const ['pulse', 'glucose', 'other'],
                  itemLabel: (v) => v == 'pulse' ? loc.pulseSensor : (v == 'glucose' ? loc.glucoseSensor : loc.otherModel),
                  onChanged: (v) => setState(() => _sensor = v),
                  isRequired: false,
                ),
              ),

              const SizedBox(height: 20),
              _PremiumSection(
                title: loc.volunteerLabel,
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(loc.volunteerConsent, style: const TextStyle(fontSize: 14, fontFamily: 'NotoSansArabic')),
                      value: _volunteerEnabled,
                      activeColor: primary,
                      onChanged: (v) => setState(() => _volunteerEnabled = v),
                    ),
                    if (_volunteerEnabled) ...[
                      const SizedBox(height: 12),
                      _AppField(controller: _skills, label: loc.addSkillsHint, maxLines: 2, isRequired: false),
                      const SizedBox(height: 16),
                      _UploadBox(onTap: _pickCertificate, fileName: _selectedCertificateName),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: _submitting ? const CircularProgressIndicator(color: Colors.white) : Text(loc.registerBtn, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'NotoSansArabic')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumSection extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  const _PremiumSection({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: theme.primaryColor, fontSize: 16, fontFamily: 'NotoSansArabic')),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _AppField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final TextInputType? keyboardType;
  final IconData? prefix;
  final int maxLines;
  final bool isRequired;
  final List<TextInputFormatter>? formatters;
  final String? Function(String?)? validator;

  const _AppField({
    required this.controller,
    required this.label,
    this.obscure = false,
    this.keyboardType,
    this.prefix,
    this.maxLines = 1,
    this.isRequired = true,
    this.formatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      maxLines: obscure ? 1 : maxLines,
      style: const TextStyle(fontFamily: 'NotoSansArabic'),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefix != null ? Icon(prefix, size: 20) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      validator: validator ?? (isRequired 
          ? (v) => (v == null || v.isEmpty) ? context.loc.requiredField : null
          : null),
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
    return DropdownButtonFormField<T>(
      value: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(itemLabel != null ? itemLabel!(e) : e.toString(), style: const TextStyle(fontFamily: 'NotoSansArabic')))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      validator: isRequired ? (v) => v == null ? context.loc.requiredField : null : null,
    );
  }
}

class _DateRow extends StatelessWidget {
  final TextEditingController day, month, year;
  const _DateRow({required this.day, required this.month, required this.year});

  @override
  Widget build(BuildContext context) {
    final curYear = DateTime.now().year;
    return Row(
      children: [
        Expanded(child: _AppField(
          controller: day, 
          label: context.loc.dayLabel, 
          keyboardType: TextInputType.number,
          formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
          validator: (v) {
            final n = int.tryParse(v ?? '');
            if (n == null || n < 1 || n > 31) return context.loc.invalidVal;
            return null;
          },
        )),
        const SizedBox(width: 8),
        Expanded(child: _AppField(
          controller: month, 
          label: context.loc.monthLabel, 
          keyboardType: TextInputType.number,
          formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
          validator: (v) {
            final n = int.tryParse(v ?? '');
            if (n == null || n < 1 || n > 12) return context.loc.invalidVal;
            return null;
          },
        )),
        const SizedBox(width: 8),
        Expanded(child: _AppField(
          controller: year, 
          label: context.loc.yearLabel, 
          keyboardType: TextInputType.number,
          formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
          validator: (v) {
            final n = int.tryParse(v ?? '');
            if (n == null || n < 1900 || n > curYear) return context.loc.invalidVal;
            return null;
          },
        )),
      ],
    );
  }
}

class _ContactItem extends StatelessWidget {
  final int index;
  final _ContactControllers controllers;
  final VoidCallback onPick;
  const _ContactItem({required this.index, required this.controllers, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${loc.contactNLabel} $index', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'NotoSansArabic')),
            IconButton(onPressed: onPick, icon: const Icon(Icons.contact_phone_outlined, size: 20)),
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
          validator: (v) => (v == null || v.trim().length != 11) ? context.loc.mobileValidation11 : null,
        ),
      ],
    );
  }
}

class _AvatarUploader extends StatelessWidget {
  final VoidCallback onTap;
  final Color primary;
  const _AvatarUploader({required this.onTap, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(radius: 50, backgroundColor: primary.withOpacity(0.1), child: Icon(Icons.person_outline, size: 50, color: primary)),
          Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 18, backgroundColor: primary, child: const Icon(Icons.camera_alt, size: 18, color: Colors.white))),
        ],
      ),
    );
  }
}

class _UploadBox extends StatelessWidget {
  final VoidCallback onTap;
  final String? fileName;
  const _UploadBox({required this.onTap, this.fileName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = context.loc;
    final isDone = fileName != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDone ? Colors.green : theme.primaryColor.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(isDone ? Icons.check_circle_outline : Icons.cloud_upload_outlined, color: isDone ? Colors.green : theme.primaryColor, size: 32),
            const SizedBox(height: 8),
            Text(isDone ? fileName! : loc.uploadCertLabel, style: TextStyle(fontWeight: FontWeight.bold, color: isDone ? Colors.green : null, fontFamily: 'NotoSansArabic')),
          ],
        ),
      ),
    );
  }
}

class _ContactControllers {
  final name = TextEditingController();
  final relation = TextEditingController();
  final phone = TextEditingController();
  void dispose() { name.dispose(); relation.dispose(); phone.dispose(); }
}
