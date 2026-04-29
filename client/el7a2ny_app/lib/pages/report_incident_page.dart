import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import '../core/localization/app_strings.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';

class ReportIncidentPage extends StatefulWidget {
  final String userId;
  final double latitude;
  final double longitude;

  const ReportIncidentPage({
    super.key,
    required this.userId,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<ReportIncidentPage> createState() => _ReportIncidentPageState();
}

class _ReportIncidentPageState extends State<ReportIncidentPage> {
  String _selectedType = '';
  final TextEditingController _customTypeCtrl = TextEditingController();
  final TextEditingController _volunteersNeededCtrl = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();
  String _locationText = '';
  final List<Map<String, String>> _evidenceItems = [];
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _locationText =
        "Lat: ${widget.latitude.toStringAsFixed(4)}, Lng: ${widget.longitude.toStringAsFixed(4)}";
  }

  // --- دوال الأنواع (بأيقونات الكود القديم) ---
  List<Map<String, dynamic>> _getTypes(BuildContext context) {
    final loc = context.loc;
    return [
      {
        'id': 'accident',
        'label': loc.typeAccident,
        'icon': Icons.car_crash_rounded,
      },
      {
        'id': 'fire',
        'label': loc.typeFireAlt,
        'icon': Icons.local_fire_department_rounded,
      },
      {
        'id': 'medical',
        'label': loc.typeMedicalAlt,
        'icon': Icons.medical_services_rounded,
      },
      {'id': 'flood', 'label': loc.typeFlood, 'icon': Icons.flood_rounded},
      {
        'id': 'earthquake',
        'label': loc.typeEarthquake,
        'icon': Icons.house_siding_rounded,
      },
      {'id': 'theft', 'label': loc.typeTheft, 'icon': Icons.back_hand_rounded},
      {
        'id': 'assault',
        'label': loc.typeAssault,
        'icon': Icons.sports_martial_arts_rounded,
      },
      {
        'id': 'other',
        'label': loc.typeOtherAlt,
        'icon': Icons.more_horiz_rounded,
      },
    ];
  }

  // --- الميديا (صور وفيديو وصوت) ---
Future<void> _pickMedia(ImageSource source, bool isVideo) async {
  try {
    final XFile? file = isVideo 
        ? await _picker.pickVideo(source: source) 
        : await _picker.pickImage(source: source);

    if (file != null) {
      // ✅ DO NOT use File(file.path) here. It will crash on Web.
      setState(() {
        _evidenceItems.add({
          'path': file.path, 
          'type': isVideo ? 'video' : 'image',
          'name': file.name, // Store the name for the upload
        });
      });
      print("📸 File picked successfully: ${file.name}");
    }
  } catch (e) {
    print("❌ Error picking media: $e");
  }
}

  void _mockPickAudio() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.loc.isAr
              ? 'يرجى إضافة صورة أو فيديو كدليل. الصوت غير مدعوم حالياً.'
              : 'Please add a photo or video as evidence. Audio is not currently supported.',
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // --- دوال الاختيار (Sheets) ---
  void _showMediaPicker(bool isVideo) {
    final loc = context.loc;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(isVideo ? loc.recordVideo : loc.takePhoto),
              onTap: () {
                Navigator.pop(context);
                _pickMedia(ImageSource.camera, isVideo);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(loc.chooseFromGallery),
              onTap: () {
                Navigator.pop(context);
                _pickMedia(ImageSource.gallery, isVideo);
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- الإرسال لـ Django ---
  Future<void> _triggerEmergencyAutomations() async {
    print("🚀 Starting submission...");
    print("📸 All evidence items: $_evidenceItems");

    // Count REAL files (not mock files)
    final realFiles = _evidenceItems
        .where((item) => !item['path']!.startsWith('mock_'))
        .toList();

    print("📸 Real files count: ${realFiles.length}");
    print("📸 Real files: $realFiles");

    if (realFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.loc.isAr
                ? 'يجب إضافة صورة أو فيديو (الصوت وحده غير كافي)'
                : 'Please add a photo or video (audio alone is not enough)',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_volunteersNeededCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.loc.isAr
                ? 'عدد المتطوعين مطلوب'
                : 'Volunteers needed is required',
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      print("📤 Sending to API with ${realFiles.length} files...");
      // استخدم الدالة الجديدة التي تدعم الملفات
      await ApiService.sendEmergencyAlertWithMedia(
        userId: widget.userId,
        type: _selectedType == 'other' ? _customTypeCtrl.text : _selectedType,
        lat: widget.latitude,
        lng: widget.longitude,
        description:
            "Desc: ${_descriptionCtrl.text}\nVolunteers: ${_volunteersNeededCtrl.text}",
        evidenceItems: _evidenceItems,
      );
      _makeEmergencyCalls();
      if (mounted) _showSuccessDialog();
    } catch (e) {
      print("❌ Submission error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _makeEmergencyCalls() async {
    final officials = ['122', '123', '180'];
    for (var num in officials) {
      await FlutterPhoneDirectCaller.callNumber(num);
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = context.loc;
    final cardColor = theme.brightness == Brightness.dark
        ? theme.colorScheme.surfaceContainer
        : theme.colorScheme.surface;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.reportIncidentTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontFamily: 'NotoSansArabic',
          ),
        ),
        backgroundColor: theme.primaryColor,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.incidentQuestion,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                fontFamily: 'NotoSansArabic',
              ),
            ),
            const SizedBox(height: 20),

            // Grid بأنيميشن الكود القديم
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
                childAspectRatio: 0.82,
              ),
              itemCount: _getTypes(context).length,
              itemBuilder: (context, index) {
                final t = _getTypes(context)[index];
                final isSelected = _selectedType == t['id'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = t['id']),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? theme.primaryColor : cardColor,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: theme.primaryColor.withOpacity(0.3),
                                    blurRadius: 10,
                                  ),
                                ]
                              : [],
                        ),
                        child: Icon(
                          t['icon'],
                          color: isSelected
                              ? Colors.white
                              : theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t['label'],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'NotoSansArabic',
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 30),
            _SectionLabel(label: loc.locationLabel),
            const SizedBox(height: 10),
            _buildLocationBox(cardColor, theme),

            const SizedBox(height: 30),
            _SectionLabel(label: loc.addEvidenceLabel),
            const SizedBox(height: 15),
            if (_evidenceItems.isNotEmpty) _buildEvidenceList(theme),

            Row(
              children: [
                Expanded(
                  child: _EvidenceButton(
                    icon: Icons.camera_alt,
                    label: loc.evidencePhoto,
                    onTap: () => _showMediaPicker(false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _EvidenceButton(
                    icon: Icons.videocam,
                    label: loc.evidenceVideo,
                    onTap: () => _showMediaPicker(true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _EvidenceButton(
                    icon: Icons.mic,
                    label: loc.evidenceRecord,
                    onTap: _mockPickAudio,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
            _SectionLabel(label: loc.volunteersNeededLabel),
            const SizedBox(height: 10),
            TextField(
              controller: _volunteersNeededCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: loc.volunteersNeededHint,
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 30),
            _SectionLabel(
              label: context.loc.isAr
                  ? 'وصف إضافي (اختياري)'
                  : 'Additional Description (Optional)',
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionCtrl,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: context.loc.isAr
                    ? 'تفاصيل إضافية...'
                    : 'More details...',
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: FilledButton(
                onPressed: (_selectedType.isEmpty || _isSubmitting)
                    ? null
                    : _triggerEmergencyAutomations,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        loc.reportBtn,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationBox(Color cardColor, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: theme.primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _locationText,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () {},
            child: Text(
              context.loc.changeLocation,
              style: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceList(ThemeData theme) {
    return Container(
      height: 100,
      margin: const EdgeInsets.only(bottom: 15),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _evidenceItems.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final item = _evidenceItems[i];
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                item['type'] == 'image'
                    ? (kIsWeb
                          ? Image.network(
                              item['path']!,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(item['path']!),
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ))
                    : Container(
                        width: 100,
                        height: 100,
                        color: theme.primaryColor.withOpacity(0.1),
                        child: Icon(
                          item['type'] == 'video' ? Icons.videocam : Icons.mic,
                          color: theme.primaryColor,
                        ),
                      ),
                Positioned(
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () => setState(() => _evidenceItems.removeAt(i)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.loc.helpOnWayTitle, textAlign: TextAlign.center),
        content: Text(context.loc.helpOnWayDesc, textAlign: TextAlign.center),
        actions: [
          Center(
            child: FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text(context.loc.readInstructionsBtn),
            ),
          ),
        ],
      ),
    );
  }
}

class _EvidenceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _EvidenceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: theme.primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: theme.primaryColor.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: theme.primaryColor),
            Text(
              label,
              style: TextStyle(
                color: theme.primaryColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      fontFamily: 'NotoSansArabic',
    ),
  );
}
