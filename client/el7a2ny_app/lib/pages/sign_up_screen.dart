import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../core/api/api_exception.dart';
import '../core/services/social_auth_service.dart';
import '../data/repositories/auth_repository.dart';
import '../core/localization/app_strings.dart';
import '../widgets/language_toggle_button.dart';

/// ألوان التصميم — أحمر أساسي وخلفيات وردية فاتحة للأقسام.
const Color _kBrandRed = Color(0xFFE32626);
const Color _kSectionPink = Color(0xFFFDECEC);
const Color _kTextDark = Color(0xFF424242);
const Color _kPlaceholderGrey = Color(0xFF9E9E9E);

class SignUpScreen extends StatefulWidget {
  final SocialProfile? socialProfile;

  const SignUpScreen({super.key, this.socialProfile});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _micGranted = false;
  bool _locationGranted = false;
  bool _cameraGranted = false;

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

  bool _volunteerEnabled = false;
  bool _submitting = false;
  String? _selectedCertificateName;

  final List<_ContactControllers> _contacts = [];
  final _auth = AuthRepository();

  @override
  void initState() {
    super.initState();
    _contacts.add(_ContactControllers());
    _contacts.add(_ContactControllers());

    if (widget.socialProfile != null) {
      _firstName.text = widget.socialProfile!.firstName;
      _lastName.text = widget.socialProfile!.lastName;
      _email.text = widget.socialProfile!.email;
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _nationalId.dispose();
    _day.dispose();
    _month.dispose();
    _year.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _skills.dispose();
    for (final c in _contacts) {
      c.dispose();
    }
    super.dispose();
  }

  void _addContact() {
    setState(() {
      _contacts.add(_ContactControllers());
    });
  }

  Future<void> _pickContact(int index) async {
    final status = await Permission.contacts.request();
    if (status.isGranted) {
      final contactId = await FlutterContacts.native.showPicker();
      if (contactId != null) {
        final fullContact = await FlutterContacts.get(
          contactId,
          properties: {ContactProperty.phone},
        );
        if (fullContact != null && mounted) {
          setState(() {
            _contacts[index].name.text = fullContact.displayName ?? '';
            if (fullContact.phones.isNotEmpty) {
              _contacts[index].phone.text = fullContact.phones.first.number
                  .replaceAll(RegExp(r'[^\d]'), '');
            }
          });
        }
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.loc.allowContactAccess)));
    }
  }

  Future<void> _requestMic(bool allow) async {
    if (allow) {
      final status = await Permission.microphone.request();
      setState(() => _micGranted = status.isGranted);
    } else {
      setState(() => _micGranted = false);
    }
  }

  Future<void> _requestLocation(bool allow) async {
    if (allow) {
      final status = await Permission.location.request();
      setState(() => _locationGranted = status.isGranted);
    } else {
      setState(() => _locationGranted = false);
    }
  }

  Future<void> _requestCamera(bool allow) async {
    if (allow) {
      final status = await Permission.camera.request();
      setState(() => _cameraGranted = status.isGranted);
    } else {
      setState(() => _cameraGranted = false);
    }
  }

  Future<void> _pickCertificate() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedCertificateName = result.files.first.name;
      });
    }
  }

  /// جسم JSON يُرسل لـ Django — عدّلي أسماء المفاتيح لتطابق الـ serializer.
  Map<String, dynamic> _buildRegistrationBody() {
    return {
      'first_name': _firstName.text.trim(),
      'last_name': _lastName.text.trim(),
      'email': _email.text.trim(),
      'phone': _phone.text.trim(),
      'national_id': _nationalId.text.trim(),
      'birth_date':
          '${_year.text.trim()}-${_month.text.trim()}-${_day.text.trim()}',
      'gender': _gender,
      'blood_type': _bloodType,
      'has_vehicle': _hasVehicle,
      'permission_mic': _micGranted,
      'permission_location': _locationGranted,
      'permission_camera': _cameraGranted,
      if (widget.socialProfile == null) 'password': _password.text,
      if (widget.socialProfile != null)
        'social_provider': widget.socialProfile!.provider,
      'volunteer_enabled': _volunteerEnabled,
      'skills': _skills.text.trim(),
      'smart_watch_model': _smartWatch,
      'sensor_model': _sensor,
      'emergency_contacts': [
        for (final c in _contacts)
          {
            'name': c.name.text.trim(),
            'relation': c.relation.text.trim(),
            'phone': c.phone.text.trim(),
          },
      ],
    };
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      await _auth.register(_buildRegistrationBody());
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.loc.accountCreated)));
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _kTextDark),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          context.loc.signUpTitle,
          style: const TextStyle(
            fontFamily: 'NotoSansArabic',
            fontWeight: FontWeight.w800,
            color: _kTextDark,
          ),
        ),
        actions: const [
          LanguageToggleButton(iconColor: _kTextDark),
          SizedBox(width: 8),
        ],
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.loc.signUpSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'NotoSansArabic',
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              _PinkSection(
                title: context.loc.requiredPermissions,
                child: _PermissionsRow(
                  mic: _micGranted,
                  location: _locationGranted,
                  camera: _cameraGranted,
                  onMic: _requestMic,
                  onLocation: _requestLocation,
                  onCamera: _requestCamera,
                ),
              ),
              const SizedBox(height: 14),
              _PinkSection(
                title: context.loc.basicInfo,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ProfileAvatarRow(
                      onUploadTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(context.loc.uploadPhotoHint)),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _OutlinedField(
                            controller: _firstName,
                            label: context.loc.firstNameLabel,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? context.loc.requiredField
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _OutlinedField(
                            controller: _lastName,
                            label: context.loc.lastNameLabel,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? context.loc.requiredField
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _OutlinedField(
                      controller: _email,
                      label: context.loc.emailLabel,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return context.loc.requiredField;
                        if (!v.contains('@'))
                          return context.loc.emailValidationAt;
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _OutlinedField(
                      controller: _phone,
                      label: context.loc.mobileLabel,
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_android_rounded,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                      validator: (v) {
                        if (v == null || v.trim().length != 11) {
                          return context.loc.mobileValidation11;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _OutlinedField(
                      controller: _nationalId,
                      label: context.loc.nationalIdLabel,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(14),
                      ],
                      validator: (v) {
                        if (v != null && v.isNotEmpty && v.length != 14) {
                          return context.loc.nationalIdValidation;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.loc.birthDateLabel,
                      style: TextStyle(
                        fontFamily: 'NotoSansArabic',
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _OutlinedField(
                            controller: _day,
                            label: context.loc.dayLabel,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(2),
                            ],
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return context.loc.requiredField;
                              final val = int.tryParse(v);
                              if (val == null || val < 1 || val > 31) {
                                return context.loc.invalidVal;
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _OutlinedField(
                            controller: _month,
                            label: context.loc.monthLabel,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(2),
                            ],
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return context.loc.requiredField;
                              final val = int.tryParse(v);
                              if (val == null || val < 1 || val > 12) {
                                return context.loc.invalidVal;
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _OutlinedField(
                            controller: _year,
                            label: context.loc.yearLabel,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return context.loc.requiredField;
                              final val = int.tryParse(v);
                              if (val == null || val > DateTime.now().year) {
                                return context.loc.invalidVal;
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _DropdownField<String>(
                            label: context.loc.genderLabel,
                            value: _gender,
                            items: const ['male', 'female'],
                            itemLabel: (v) => v == 'male'
                                ? context.loc.maleOption
                                : context.loc.femaleOption,
                            onChanged: (v) => setState(() => _gender = v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DropdownField<String>(
                            label: context.loc.bloodTypeLabel,
                            value: _bloodType,
                            items: const [
                              'A+',
                              'A-',
                              'B+',
                              'B-',
                              'O+',
                              'O-',
                              'AB+',
                              'AB-',
                            ],
                            onChanged: (v) => setState(() => _bloodType = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _DropdownField<String>(
                      label: context.loc.hasVehicleLabel,
                      value: _hasVehicle,
                      items: const ['yes', 'no'],
                      itemLabel: (v) =>
                          v == 'yes' ? context.loc.yes : context.loc.no,
                      onChanged: (v) => setState(() => _hasVehicle = v),
                    ),
                    if (widget.socialProfile == null) ...[
                      const SizedBox(height: 12),
                      _OutlinedField(
                        controller: _password,
                        label: context.loc.password,
                        obscure: true,
                        validator: (v) {
                          if (v == null || v.length < 6) {
                            return context.loc.min6Chars;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _OutlinedField(
                        controller: _confirmPassword,
                        label: context.loc.confirmPassword,
                        obscure: true,
                        validator: (v) {
                          if (v != _password.text) {
                            return context.loc.noMatch;
                          }
                          return null;
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _PinkSection(
                title: context.loc.emergencyContacts,
                trailing: TextButton.icon(
                  onPressed: _addContact,
                  icon: const Icon(Icons.add, color: _kBrandRed, size: 20),
                  label: Text(
                    context.loc.addContactsLabel,
                    style: TextStyle(
                      fontFamily: 'NotoSansArabic',
                      fontWeight: FontWeight.w700,
                      color: _kBrandRed,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < _contacts.length; i++) ...[
                      if (i > 0) const SizedBox(height: 16),
                      _ContactBlock(
                        index: i + 1,
                        controllers: _contacts[i],
                        isRequired: i < 2,
                        onPickContact: () => _pickContact(i),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _PinkSection(
                title: context.loc.smartWatchLabel,
                child: _DropdownField<String>(
                  label: context.loc.selectModel,
                  value: _smartWatch,
                  items: const [
                    'Apple Watch',
                    'Samsung Galaxy Watch',
                    'Huawei Watch',
                    'other',
                  ],
                  itemLabel: (v) => v == 'other' ? context.loc.otherModel : v,
                  onChanged: (v) => setState(() => _smartWatch = v),
                ),
              ),
              const SizedBox(height: 14),
              _PinkSection(
                title: context.loc.sensorLabel,
                child: _DropdownField<String>(
                  label: context.loc.selectModel,
                  value: _sensor,
                  items: const ['pulse', 'glucose', 'other'],
                  itemLabel: (v) {
                    if (v == 'pulse') return context.loc.pulseSensor;
                    if (v == 'glucose') return context.loc.glucoseSensor;
                    return context.loc.otherModel;
                  },
                  onChanged: (v) => setState(() => _sensor = v),
                ),
              ),
              const SizedBox(height: 14),
              _PinkSection(
                title: context.loc.volunteerLabel,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        context.loc.volunteerConsent,
                        style: TextStyle(
                          fontFamily: 'NotoSansArabic',
                          fontSize: 14,
                          color: _kTextDark,
                        ),
                      ),
                      value: _volunteerEnabled,
                      activeThumbColor: _kBrandRed,
                      onChanged: (v) => setState(() => _volunteerEnabled = v),
                    ),
                    if (_volunteerEnabled) ...[
                      const SizedBox(height: 12),
                      _OutlinedField(
                        controller: _skills,
                        label: context.loc.addSkillsHint,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      _CertificateUploadZone(
                        onTap: _pickCertificate,
                        fileName: _selectedCertificateName,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: _kBrandRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          context.loc.registerBtn,
                          style: TextStyle(
                            fontFamily: 'NotoSansArabic',
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactControllers {
  final name = TextEditingController();
  final relation = TextEditingController();
  final phone = TextEditingController();

  void dispose() {
    name.dispose();
    relation.dispose();
    phone.dispose();
  }
}

class _PinkSection extends StatelessWidget {
  const _PinkSection({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSectionPink,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'NotoSansArabic',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _kBrandRed,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _PermissionsRow extends StatelessWidget {
  const _PermissionsRow({
    required this.mic,
    required this.location,
    required this.camera,
    required this.onMic,
    required this.onLocation,
    required this.onCamera,
  });

  final bool mic;
  final bool location;
  final bool camera;
  final ValueChanged<bool> onMic;
  final ValueChanged<bool> onLocation;
  final ValueChanged<bool> onCamera;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PermissionTile(
            icon: Icons.mic_none_rounded,
            label: context.loc.mic,
            value: mic,
            onChanged: onMic,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PermissionTile(
            icon: Icons.location_on_outlined,
            label: context.loc.location,
            value: location,
            onChanged: onLocation,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PermissionTile(
            icon: Icons.photo_camera_outlined,
            label: context.loc.camera,
            value: camera,
            onChanged: onCamera,
          ),
        ),
      ],
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _kBrandRed, size: 28),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'NotoSansArabic',
              fontSize: 11,
              color: _kTextDark,
            ),
          ),
          const SizedBox(height: 4),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: _kBrandRed,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatarRow extends StatelessWidget {
  const _ProfileAvatarRow({required this.onUploadTap});

  final VoidCallback onUploadTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: Colors.blue.shade100,
          child: Icon(
            Icons.person_rounded,
            size: 40,
            color: Colors.blue.shade700,
          ),
        ),
        const SizedBox(width: 16),
        TextButton(
          onPressed: onUploadTap,
          child: Text(
            context.loc.uploadPhotoBtn,
            style: TextStyle(
              fontFamily: 'NotoSansArabic',
              fontWeight: FontWeight.w700,
              color: _kBrandRed,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}

class _OutlinedField extends StatelessWidget {
  const _OutlinedField({
    required this.controller,
    required this.label,
    this.validator,
    this.keyboardType,
    this.prefixIcon,
    this.obscure = false,
    this.maxLines = 1,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final bool obscure;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscure,
      maxLines: obscure ? 1 : maxLines,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontFamily: 'NotoSansArabic'),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontFamily: 'NotoSansArabic',
          color: _kPlaceholderGrey,
          fontSize: 14,
        ),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: Colors.grey.shade600, size: 22)
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kBrandRed, width: 1.5),
        ),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<T> items;
  final String Function(T)? itemLabel;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      key: ValueKey<Object?>((label, value)),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontFamily: 'NotoSansArabic',
          color: _kPlaceholderGrey,
          fontSize: 14,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kBrandRed, width: 1.5),
        ),
      ),
      hint: Text(
        context.loc.selectHint,
        style: TextStyle(
          fontFamily: 'NotoSansArabic',
          color: Colors.grey.shade500,
        ),
      ),
      items: items
          .map(
            (e) => DropdownMenuItem<T>(
              value: e,
              child: Text(
                itemLabel != null ? itemLabel!(e) : e.toString(),
                style: const TextStyle(fontFamily: 'NotoSansArabic'),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _ContactBlock extends StatelessWidget {
  const _ContactBlock({
    required this.index,
    required this.controllers,
    this.isRequired = false,
    this.onPickContact,
  });

  final int index;
  final _ContactControllers controllers;
  final bool isRequired;
  final VoidCallback? onPickContact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${context.loc.contactNLabel} $index ${isRequired ? context.loc.requiredSymbol : ""}',
              style: TextStyle(
                fontFamily: 'NotoSansArabic',
                fontWeight: FontWeight.w700,
                color: _kTextDark,
              ),
            ),
            if (onPickContact != null)
              TextButton.icon(
                onPressed: onPickContact,
                icon: const Icon(
                  Icons.contacts_rounded,
                  size: 18,
                  color: _kBrandRed,
                ),
                label: Text(
                  context.loc.chooseBtn,
                  style: const TextStyle(
                    fontFamily: 'NotoSansArabic',
                    color: _kBrandRed,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        _OutlinedField(
          controller: controllers.name,
          label: context.loc.theName,
          validator: isRequired
              ? (v) => (v == null || v.trim().isEmpty)
                    ? context.loc.requiredField
                    : null
              : null,
        ),
        const SizedBox(height: 10),
        _OutlinedField(
          controller: controllers.relation,
          label: context.loc.relationLabel,
          validator: isRequired
              ? (v) => (v == null || v.trim().isEmpty)
                    ? context.loc.requiredField
                    : null
              : null,
        ),
        const SizedBox(height: 10),
        _OutlinedField(
          controller: controllers.phone,
          label: context.loc.mobileNum,
          keyboardType: TextInputType.phone,
          prefixIcon: Icons.phone_rounded,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: isRequired
              ? (v) => (v == null || v.trim().isEmpty)
                    ? context.loc.requiredField
                    : null
              : null,
        ),
      ],
    );
  }
}

class _CertificateUploadZone extends StatelessWidget {
  const _CertificateUploadZone({required this.onTap, this.fileName});

  final VoidCallback onTap;
  final String? fileName;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _kBrandRed.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                fileName != null
                    ? Icons.check_circle_outline
                    : Icons.upload_file_rounded,
                size: 40,
                color: fileName != null
                    ? Colors.green
                    : _kBrandRed.withValues(alpha: 0.85),
              ),
              const SizedBox(height: 8),
              Text(
                fileName != null
                    ? context.loc.successfullySelected
                    : context.loc.uploadCertLabel,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'NotoSansArabic',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: fileName != null ? Colors.green : _kTextDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                fileName ?? context.loc.downloadCertLabel,
                style: TextStyle(
                  fontFamily: 'NotoSansArabic',
                  fontSize: 13,
                  color: fileName != null ? Colors.grey.shade600 : _kBrandRed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
