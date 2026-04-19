import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

import '../core/api/api_exception.dart';
import '../core/localization/app_strings.dart';
import '../data/repositories/emergency_report_repository.dart';

/// أحمر العنوان والزر الرئيسي.
Color _kEmergencyRed(BuildContext context) => Theme.of(context).primaryColor;
Color _kSectionPink(BuildContext context) => Theme.of(context).brightness == Brightness.light
    ? Theme.of(context).primaryColor.withOpacity(0.05)
    : Theme.of(context).colorScheme.surfaceContainer;
Color _kTextDark(BuildContext context) => Theme.of(context).colorScheme.onSurface;

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
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedMedia;
  Position? _currentPosition;

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
      if (_currentPosition != null) 'location_lat': _currentPosition!.latitude,
      if (_currentPosition != null) 'location_lng': _currentPosition!.longitude,
    };
  }

  Future<void> _requestCamera() async {
    final status = await Permission.camera.request();
    setState(() => _cameraGranted = status.isGranted);
  }

  Future<void> _requestLocation() async {
    final status = await Permission.locationWhenInUse.request();
    if (status.isGranted) {
      setState(() => _locationGranted = true);
      try {
        _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } catch (_) {}
    } else {
      setState(() => _locationGranted = false);
    }
  }

  Future<void> _requestMic() async {
    final status = await Permission.microphone.request();
    setState(() => _micGranted = status.isGranted);
  }

  Future<void> _sendReport() async {
    if (!_permissionsReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.loc.enablePermissionsFirst),
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
        SnackBar(content: Text(context.loc.reportSubmitted)),
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

  Future<void> _pickMedia() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt_outlined, color: _kEmergencyRed(context)),
              title: Text(context.loc.takePhoto, style: const TextStyle(fontFamily: 'NotoSansArabic')),
              onTap: () async {
                Navigator.pop(context);
                final file = await _picker.pickImage(source: ImageSource.camera);
                if (file != null) setState(() => _selectedMedia = file);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: _kEmergencyRed(context)),
              title: Text(context.loc.chooseFromGallery, style: const TextStyle(fontFamily: 'NotoSansArabic')),
              onTap: () async {
                Navigator.pop(context);
                final file = await _picker.pickImage(source: ImageSource.gallery);
                if (file != null) setState(() => _selectedMedia = file);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: _kTextDark(context)),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.loc.emergencyReportTitle,
                style: TextStyle(
                  fontFamily: 'NotoSansArabic',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _kEmergencyRed(context),
                ),
              ),
              Text(
                context.loc.quickAccidentReport,
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PinkSection(
                  title: context.loc.requiredPermissions,
                  titleColor: _kTextDark(context),
                  child: Row(
                    children: [
                      Expanded(
                        child: _PermissionSquare(
                          icon: Icons.photo_camera_outlined,
                          label: context.loc.camera,
                          active: _cameraGranted,
                          onTap: _requestCamera,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _PermissionSquare(
                          icon: Icons.location_on_outlined,
                          label: context.loc.location,
                          active: _locationGranted,
                          onTap: _requestLocation,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _PermissionSquare(
                          icon: Icons.mic_none_rounded,
                          label: context.loc.mic,
                          active: _micGranted,
                          onTap: _requestMic,
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
                      _FieldLabel(context.loc.theName),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _name,
                        style: const TextStyle(fontFamily: 'NotoSansArabic'),
                        decoration: _inputDecoration(hint: context.loc.typeNameHint),
                      ),
                      const SizedBox(height: 16),
                      _FieldLabel(context.loc.mobileNum),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
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
                        style: const TextStyle(fontFamily: 'NotoSansArabic'),
                        decoration: _inputDecoration(
                          hint: context.loc.phoneFormatHint,
                          prefixIcon: Icon(
                            Icons.phone_android_rounded,
                            color: Colors.grey.shade600,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _FieldLabel(context.loc.emergencyDesc),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _description,
                        minLines: 5,
                        maxLines: 8,
                        validator: (v) {
                          if (v == null || v.trim().length < 8) {
                            return context.loc.describeMin8;
                          }
                          return null;
                        },
                        style: const TextStyle(fontFamily: 'NotoSansArabic'),
                        decoration: _inputDecoration(
                          hint: context.loc.describeStateShort,
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _MediaUploadBox(
                        onTap: _pickMedia,
                        hasMedia: _selectedMedia != null,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 52,
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _submitting ? null : _sendReport,
                          style: FilledButton.styleFrom(
                            backgroundColor: _kEmergencyRed(context),
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
                                  context.loc.sendReport,
                                  style: const TextStyle(
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
              ],
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
        fontFamily: 'NotoSansArabic',
        color: Colors.grey.shade500,
        fontSize: 14,
      ),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      alignLabelWithHint: alignLabelWithHint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _kEmergencyRed(context), width: 1.2),
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
      textAlign: context.loc.isAr ? TextAlign.right : TextAlign.left,
      style: TextStyle(
        fontFamily: 'NotoSansArabic',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _kTextDark(context),
      ),
    );
  }
}

class _PinkSection extends StatelessWidget {
  const _PinkSection({
    required this.title,
    required this.child,
    this.titleColor,
    this.showTitle = true,
  });

  final String title;
  final Widget child;
  final Color? titleColor;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSectionPink(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showTitle && title.isNotEmpty) ...[
            Text(
              title,
              style: TextStyle(
                fontFamily: 'NotoSansArabic',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: titleColor ?? _kEmergencyRed(context),
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
              color: active ? _kEmergencyRed(context) : _kTextDark(context).withOpacity(0.4),
              width: active ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: active ? _kEmergencyRed(context) : _kTextDark(context),
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'NotoSansArabic',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: active ? _kEmergencyRed(context) : _kTextDark(context),
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
  const _MediaUploadBox({required this.onTap, this.hasMedia = false});

  final VoidCallback onTap;
  final bool hasMedia;

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
            color: _kSectionPink(context),
            child: Column(
              children: [
                Icon(
                  hasMedia ? Icons.check_circle_outline : Icons.perm_media_outlined,
                  size: 40,
                  color: hasMedia ? _kEmergencyRed(context) : _kTextDark(context).withOpacity(0.7),
                ),
                const SizedBox(height: 10),
                Text(
                  hasMedia ? context.loc.mediaFileAdded : context.loc.evidenceMedia,
                  style: TextStyle(
                    fontFamily: 'NotoSansArabic',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: hasMedia ? _kEmergencyRed(context) : _kTextDark(context),
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
