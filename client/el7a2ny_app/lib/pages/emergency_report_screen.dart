import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api/api_exception.dart';
import '../core/strings/app_strings.dart';
import '../data/repositories/emergency_report_repository.dart';

/// أحمر العنوان والزر الرئيسي.
const Color _kEmergencyRed = Color(0xFFE51A1A);

/// خلفية الأقسام الوردية الفاتحة.
const Color _kSectionPink = Color(0xFFFDECEC);

const Color _kTextDark = Color(0xFF424242);

class EmergencyReportScreen extends StatefulWidget {
  const EmergencyReportScreen({super.key});

  @override
  State<EmergencyReportScreen> createState() => _EmergencyReportScreenState();
}

class _EmergencyReportScreenState extends State<EmergencyReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _description = TextEditingController();

  bool _cameraGranted = false;
  bool _locationGranted = false;
  bool _micGranted = false;
  bool _submitting = false;

  final _reports = EmergencyReportRepository();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _description.dispose();
    super.dispose();
  }

  bool get _permissionsReady =>
      _cameraGranted && _locationGranted && _micGranted;

  Map<String, dynamic> _buildReportBody() {
    return {
      'reporter_name': _name.text.trim(),
      'phone': _phone.text.trim(),
      'description': _description.text.trim(),
      'permission_camera': _cameraGranted,
      'permission_location': _locationGranted,
      'permission_mic': _micGranted,
    };
  }

  Future<void> _sendReport() async {
    if (!_permissionsReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('فعّلي أذونات الكاميرا والموقع والميكروفون أولاً'),
        ),
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      await _reports.submitReport(_buildReportBody());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال البلاغ')),
      );
      Navigator.of(context).maybePop();
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

  void _pickMedia() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('رفع الملفات — اربطي image_picker ثم أرسلي الروابط مع البلاغ')),
    );
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
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'بلاغ طوارئ',
                style: TextStyle(
                  fontFamily: 'Unixel',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _kEmergencyRed,
                ),
              ),
              Text(
                'بلاغ سريع عن حادث',
                style: TextStyle(
                  fontFamily: 'Unixel',
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PinkSection(
                  title: 'الأذونات المطلوبة',
                  titleColor: _kTextDark,
                  child: Row(
                    children: [
                      Expanded(
                        child: _PermissionSquare(
                          icon: Icons.photo_camera_outlined,
                          label: 'الكاميرا',
                          active: _cameraGranted,
                          onTap: () => setState(() => _cameraGranted = !_cameraGranted),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _PermissionSquare(
                          icon: Icons.location_on_outlined,
                          label: 'الموقع',
                          active: _locationGranted,
                          onTap: () => setState(() => _locationGranted = !_locationGranted),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _PermissionSquare(
                          icon: Icons.mic_none_rounded,
                          label: 'الميكروفون',
                          active: _micGranted,
                          onTap: () => setState(() => _micGranted = !_micGranted),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _PinkSection(
                  title: '',
                  showTitle: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _FieldLabel('الأسم'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _name,
                        style: const TextStyle(fontFamily: 'Unixel'),
                        decoration: _inputDecoration(hint: 'اكتب اسمك'),
                      ),
                      const SizedBox(height: 16),
                      _FieldLabel('رقم الموبيل'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (v) {
                          if (v == null || v.trim().length < 10) {
                            return 'أدخل رقم موبايل صحيح';
                          }
                          return null;
                        },
                        style: const TextStyle(fontFamily: 'Unixel'),
                        decoration: _inputDecoration(
                          hint: AppStrings.phoneFormatHint,
                          prefixIcon: Icon(
                            Icons.phone_android_rounded,
                            color: Colors.grey.shade600,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _FieldLabel('وصف الطوارئ'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _description,
                        minLines: 5,
                        maxLines: 8,
                        validator: (v) {
                          if (v == null || v.trim().length < 8) {
                            return 'اوصف الحالة باختصار (٨ أحرف على الأقل)';
                          }
                          return null;
                        },
                        style: const TextStyle(fontFamily: 'Unixel'),
                        decoration: _inputDecoration(
                          hint: 'اوصف حاله الطوارئ',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _MediaUploadBox(onTap: _pickMedia),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 52,
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _submitting ? null : _sendReport,
                          style: FilledButton.styleFrom(
                            backgroundColor: _kEmergencyRed,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
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
                                  'ارسال البلاغ',
                                  style: TextStyle(
                                    fontFamily: 'Unixel',
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    Widget? prefixIcon,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontFamily: 'Unixel',
        color: Colors.grey.shade500,
        fontSize: 14,
      ),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: Colors.white,
      alignLabelWithHint: alignLabelWithHint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kEmergencyRed, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.right,
      style: TextStyle(
        fontFamily: 'Unixel',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _kTextDark,
      ),
    );
  }
}

class _PinkSection extends StatelessWidget {
  const _PinkSection({
    required this.title,
    required this.child,
    this.titleColor = _kEmergencyRed,
    this.showTitle = true,
  });

  final String title;
  final Widget child;
  final Color titleColor;
  final bool showTitle;

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
          if (showTitle && title.isNotEmpty) ...[
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Unixel',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

class _PermissionSquare extends StatelessWidget {
  const _PermissionSquare({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? _kEmergencyRed : Colors.black87,
              width: active ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: active ? _kEmergencyRed : Colors.black87,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Unixel',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: active ? _kEmergencyRed : _kTextDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaUploadBox extends StatelessWidget {
  const _MediaUploadBox({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: CustomPaint(
          foregroundPainter: _DashedRRectPainter(
            color: Colors.grey.shade500,
            radius: 12,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            color: _kSectionPink,
            child: Column(
              children: [
                Icon(
                  Icons.perm_media_outlined,
                  size: 40,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(height: 10),
                Text(
                  'تحميل الصور/الفيديو',
                  style: TextStyle(
                    fontFamily: 'Unixel',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _kTextDark,
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

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(r);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawPath(_dashPath(path, 5, 4), paint);
  }

  Path _dashPath(Path source, double dash, double gap) {
    final out = Path();
    for (final metric in source.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        final len = (dash < metric.length - d) ? dash : (metric.length - d);
        out.addPath(metric.extractPath(d, d + len), Offset.zero);
        d += dash + gap;
      }
    }
    return out;
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
