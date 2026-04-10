import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api/api_exception.dart';
import '../data/repositories/auth_repository.dart';

/// ألوان التصميم — أحمر أساسي وخلفيات وردية فاتحة للأقسام.
const Color _kBrandRed = Color(0xFFE32626);
const Color _kSectionPink = Color(0xFFFDECEC);
const Color _kTextDark = Color(0xFF424242);
const Color _kPlaceholderGrey = Color(0xFF9E9E9E);

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

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

  final List<_ContactControllers> _contacts = [];
  final _auth = AuthRepository();

  @override
  void initState() {
    super.initState();
    _contacts.add(_ContactControllers());
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

  /// جسم JSON يُرسل لـ Django — عدّلي أسماء المفاتيح لتطابق الـ serializer.
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
      'has_vehicle': _hasVehicle,
      'permission_mic': _micGranted,
      'permission_location': _locationGranted,
      'permission_camera': _cameraGranted,
      'password': _password.text,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إنشاء الحساب')),
      );
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _kTextDark),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'انشاء حساب',
                style: TextStyle(
                  fontFamily: 'NotoSansArabic',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _kBrandRed,
                ),
              ),
              Text(
                'أكمل بياناتك للاستفادة من خدمات الطوارئ',
                style: TextStyle(
                  fontFamily: 'NotoSansArabic',
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PinkSection(
                  title: 'الأذونات المطلوبة',
                  child: _PermissionsRow(
                    mic: _micGranted,
                    location: _locationGranted,
                    camera: _cameraGranted,
                    onMic: (v) => setState(() => _micGranted = v),
                    onLocation: (v) => setState(() => _locationGranted = v),
                    onCamera: (v) => setState(() => _cameraGranted = v),
                  ),
                ),
                const SizedBox(height: 14),
                _PinkSection(
                  title: 'المعلومات الشخصية',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ProfileAvatarRow(
                        onUploadTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('رفع الصورة — ربط المعرض لاحقاً')),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _OutlinedField(
                              controller: _firstName,
                              label: 'الاسم الأول',
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _OutlinedField(
                              controller: _lastName,
                              label: 'اسم العائلة',
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _OutlinedField(
                        controller: _email,
                        label: 'البريد الإلكتروني',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 12),
                      _OutlinedField(
                        controller: _phone,
                        label: 'رقم الموبايل',
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_android_rounded,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                      const SizedBox(height: 12),
                      _OutlinedField(
                        controller: _nationalId,
                        label: 'رقم البطاقة (١٤ رقم)',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(14),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'تاريخ الميلاد',
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
                              label: 'يوم',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(2),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _OutlinedField(
                              controller: _month,
                              label: 'شهر',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(2),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _OutlinedField(
                              controller: _year,
                              label: 'سنة',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _DropdownField<String>(
                              label: 'النوع',
                              value: _gender,
                              items: const ['ذكر', 'أنثى'],
                              onChanged: (v) => setState(() => _gender = v),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DropdownField<String>(
                              label: 'فصيلة الدم',
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
                        label: 'هل لديك سيارة؟',
                        value: _hasVehicle,
                        items: const ['نعم', 'لا'],
                        onChanged: (v) => setState(() => _hasVehicle = v),
                      ),
                      const SizedBox(height: 12),
                      _OutlinedField(
                        controller: _password,
                        label: 'كلمة السر',
                        obscure: true,
                        validator: (v) {
                          if (v == null || v.length < 6) {
                            return '٦ أحرف على الأقل';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _OutlinedField(
                        controller: _confirmPassword,
                        label: 'تأكيد كلمة السر',
                        obscure: true,
                        validator: (v) {
                          if (v != _password.text) {
                            return 'غير متطابقة';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _PinkSection(
                  title: 'جهات الاتصال الطارئة',
                  trailing: TextButton.icon(
                    onPressed: _addContact,
                    icon: const Icon(Icons.add, color: _kBrandRed, size: 20),
                    label: Text(
                      'إضافة جهات اتصال',
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
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _PinkSection(
                  title: 'الساعة الذكية (اختياري)',
                  child: _DropdownField<String>(
                    label: 'اختر الطراز',
                    value: _smartWatch,
                    items: const [
                      'Apple Watch',
                      'Samsung Galaxy Watch',
                      'Huawei Watch',
                      'أخرى',
                    ],
                    onChanged: (v) => setState(() => _smartWatch = v),
                  ),
                ),
                const SizedBox(height: 14),
                _PinkSection(
                  title: 'الحساس (اختياري)',
                  child: _DropdownField<String>(
                    label: 'اختر الطراز',
                    value: _sensor,
                    items: const [
                      'حساس نبض',
                      'حساس سكر',
                      'أخرى',
                    ],
                    onChanged: (v) => setState(() => _sensor = v),
                  ),
                ),
                const SizedBox(height: 14),
                _PinkSection(
                  title: 'متطوع',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'أرغب في التطوع لمساعدة الآخرين في الطوارئ',
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
                          label: 'أضف مهاراتك',
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        _CertificateUploadZone(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تحميل الشهادات — ربط الملفات لاحقاً'),
                              ),
                            );
                          },
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
                            'تسجيل',
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
  const _PinkSection({
    required this.title,
    required this.child,
    this.trailing,
  });

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
            label: 'الميكروفون',
            value: mic,
            onChanged: onMic,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PermissionTile(
            icon: Icons.location_on_outlined,
            label: 'الموقع',
            value: location,
            onChanged: onLocation,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PermissionTile(
            icon: Icons.photo_camera_outlined,
            label: 'الكاميرا',
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
          child: Icon(Icons.person_rounded, size: 40, color: Colors.blue.shade700),
        ),
        const SizedBox(width: 16),
        TextButton(
          onPressed: onUploadTap,
          child: Text(
            'رفع الصورة',
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<T> items;
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
        'اختر',
        style: TextStyle(fontFamily: 'NotoSansArabic', color: Colors.grey.shade500),
      ),
      items: items
          .map(
            (e) => DropdownMenuItem<T>(
              value: e,
              child: Text(
                e.toString(),
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
  });

  final int index;
  final _ContactControllers controllers;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'جهة اتصال $index',
          style: TextStyle(
            fontFamily: 'NotoSansArabic',
            fontWeight: FontWeight.w700,
            color: _kTextDark,
          ),
        ),
        const SizedBox(height: 10),
        _OutlinedField(
          controller: controllers.name,
          label: 'الاسم',
        ),
        const SizedBox(height: 10),
        _OutlinedField(
          controller: controllers.relation,
          label: 'صلة القرابة',
        ),
        const SizedBox(height: 10),
        _OutlinedField(
          controller: controllers.phone,
          label: 'رقم الهاتف',
          keyboardType: TextInputType.phone,
          prefixIcon: Icons.phone_rounded,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
        ),
      ],
    );
  }
}

class _CertificateUploadZone extends StatelessWidget {
  const _CertificateUploadZone({required this.onTap});

  final VoidCallback onTap;

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
                Icons.upload_file_rounded,
                size: 40,
                color: _kBrandRed.withValues(alpha: 0.85),
              ),
              const SizedBox(height: 8),
              Text(
                'أضف الشهادات الخاصة بك',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'NotoSansArabic',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _kTextDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'تحميل الشهادات',
                style: TextStyle(
                  fontFamily: 'NotoSansArabic',
                  fontSize: 13,
                  color: _kBrandRed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
