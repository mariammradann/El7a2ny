import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';

class ReportIncidentPage extends StatefulWidget {
  const ReportIncidentPage({super.key});

  @override
  State<ReportIncidentPage> createState() => _ReportIncidentPageState();
}

class _ReportIncidentPageState extends State<ReportIncidentPage> {
  String _selectedType = '';
  final TextEditingController _customTypeCtrl = TextEditingController();
  final TextEditingController _volunteersNeededCtrl = TextEditingController();
  
  String _locationText = 'مدينة نصر، القاهرة 11740';
  
  // Storing items as maps to support different types: image, video, audio
  final List<Map<String, String>> _evidenceItems = []; 
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, dynamic>> _types = [
    {'id': 'accident', 'label': 'حادث', 'icon': Icons.car_crash_rounded},
    {'id': 'fire', 'label': 'حريق', 'icon': Icons.local_fire_department_rounded},
    {'id': 'medical', 'label': 'طبية', 'icon': Icons.medical_services_rounded},
    {'id': 'flood', 'label': 'فيضان', 'icon': Icons.flood_rounded},
    {'id': 'earthquake', 'label': 'إنزال', 'icon': Icons.house_siding_rounded},
    {'id': 'theft', 'label': 'سرقة', 'icon': Icons.back_hand_rounded},
    {'id': 'assault', 'label': 'اعتداء', 'icon': Icons.sports_martial_arts_rounded},
    {'id': 'other', 'label': 'حاجة تانية', 'icon': Icons.more_horiz_rounded},
  ];

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _evidenceItems.add({'path': image.path, 'type': 'image'});
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final XFile? video = await _picker.pickVideo(source: source);
      if (video != null) {
        setState(() {
          _evidenceItems.add({'path': video.path, 'type': 'video'});
        });
      }
    } catch (e) {
      debugPrint('Error picking video: $e');
    }
  }

  void _mockPickAudio(String method) async {
    // Show a loading indicator
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    // Mock delay to simulate recording or picking an audio file
    await Future.delayed(const Duration(seconds: 2));
    if (context.mounted) Navigator.pop(context); // close dialog
    
    setState(() {
      _evidenceItems.add({'path': 'mock_audio_$method.mp3', 'type': 'audio'});
    });
  }

  // --- BOTTOM SHEETS ---

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFFDC2626)),
              title: const Text('التقاط صورة بالكاميرا', style: TextStyle(fontFamily: 'NotoSansArabic', fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFFDC2626)),
              title: const Text('اختيار من المعرض', style: TextStyle(fontFamily: 'NotoSansArabic', fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showVideoSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.videocam, color: Color(0xFFDC2626)),
              title: const Text('تصوير فيديو بالكاميرا', style: TextStyle(fontFamily: 'NotoSansArabic', fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                _pickVideo(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library, color: Color(0xFFDC2626)),
              title: const Text('اختيار من المعرض', style: TextStyle(fontFamily: 'NotoSansArabic', fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                _pickVideo(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAudioSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.mic, color: Color(0xFFDC2626)),
              title: const Text('تسجيل مقطع صوتي', style: TextStyle(fontFamily: 'NotoSansArabic', fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                _mockPickAudio('recording');
              },
            ),
            ListTile(
              leading: const Icon(Icons.audio_file, color: Color(0xFFDC2626)),
              title: const Text('اختيار ملف صوتي', style: TextStyle(fontFamily: 'NotoSansArabic', fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                _mockPickAudio('file');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LocationBottomSheet(
        initialLocation: _locationText,
        onLocationSelected: (newLoc) {
          setState(() { _locationText = newLoc; });
        },
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80, height: 80,
                decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 20),
              const Text('المساعدة في الطريق', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('اقرأ التعليمات لحد ما المساعدة توصل', style: TextStyle(color: Color(0xFF64748B))),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close Dialog
                    Navigator.of(context).pop(); // Close Report Page
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('اقرأ التعليمات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9), // Light grayish background
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          leading: const BackButton(),
          centerTitle: true,
          title: const Text('تبليغ عن مشكلة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Incident Type
              const Text('ايه المشكله اللي بتواجهك؟', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: _types.length,
                itemBuilder: (context, index) {
                  final t = _types[index];
                  final isSelected = _selectedType == t['id'];
                  return GestureDetector(
                    onTap: () {
                      setState(() { _selectedType = t['id'] as String; });
                    },
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? const Color(0xFFDC2626) : Colors.transparent,
                          ),
                          child: Stack(
                            children: [
                              Icon(
                                t['icon'] as IconData,
                                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                                size: 32,
                              ),
                              if (isSelected)
                                Positioned(
                                  top: -4, right: -4,
                                  child: Container(
                                    width: 14, height: 14,
                                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                    child: const Icon(Icons.check, size: 10, color: Color(0xFFDC2626)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          t['label'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              if (_selectedType == 'other') ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _customTypeCtrl,
                  decoration: InputDecoration(
                    hintText: 'Stuck in elevator...',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5)),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // 2. Location
              const Text('المكان', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: Color(0xFF64748B)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_locationText, style: const TextStyle(fontWeight: FontWeight.w600))),
                    GestureDetector(
                      onTap: _showLocationSheet,
                      child: const Text('تغيير', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Volunteers Needed
              const Text('عدد المتطوعين المطلوب (تقريبي)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: _volunteersNeededCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'مثال: 5',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.people_outline, color: Color(0xFF64748B)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDC2626))),
                ),
              ),

              const SizedBox(height: 32),

              // 3. Evidence
              const Text('زود دليل', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (_evidenceItems.isNotEmpty) ...[
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _evidenceItems.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final item = _evidenceItems[i];
                      if (item['type'] == 'image') {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(File(item['path']!), width: 100, height: 100, fit: BoxFit.cover),
                        );
                      } else {
                        // Video or Audio generic icon
                        return Container(
                          width: 100, height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300)
                          ),
                          child: Icon(
                            item['type'] == 'video' ? Icons.videocam : Icons.audiotrack,
                            size: 40, color: const Color(0xFFDC2626)
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Expanded(
                    child: _EvidenceButton(
                      icon: Icons.camera_alt_outlined,
                      label: 'صورة',
                      onTap: _showImageSourcePicker,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _EvidenceButton(
                      icon: Icons.videocam_outlined,
                      label: 'مقطع فيديو',
                      onTap: _showVideoSourcePicker, 
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _EvidenceButton(
                      icon: Icons.mic_none_rounded,
                      label: 'ريكورد',
                      onTap: _showAudioSourcePicker,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Report Button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    // Mute validation for mock flow
                    if (_selectedType.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اختار المشكلة الأول')));
                      return;
                    }
                    _showSuccessDialog();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('بلغ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── BOTTOM SHEET FOR LOCATION ──────────────────────────────────────────────────

class _LocationBottomSheet extends StatefulWidget {
  final String initialLocation;
  final ValueChanged<String> onLocationSelected;

  const _LocationBottomSheet({required this.initialLocation, required this.onLocationSelected});

  @override
  State<_LocationBottomSheet> createState() => _LocationBottomSheetState();
}

class _LocationBottomSheetState extends State<_LocationBottomSheet> {
  final _searchCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _govCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();

  bool _isLoadingLoc = false;

  @override
  void initState() {
    super.initState();
    _cityCtrl.text = 'مدينة نصر';
    _govCtrl.text = 'القاهرة';
    _streetCtrl.text = '11740';
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLoc = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location disabled');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception('Permission denied');
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        setState(() {
          _cityCtrl.text = p.subAdministrativeArea ?? p.locality ?? 'Unknown';
          _govCtrl.text = p.administrativeArea ?? 'Unknown';
          _streetCtrl.text = p.street ?? p.name ?? '';
          _searchCtrl.text = '${_streetCtrl.text}, ${_cityCtrl.text}';
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => _isLoadingLoc = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.arrow_back, size: 20),
                SizedBox(width: 8),
                Text('لوكيشن', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            
            // Search Input
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search Address',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
            ),
            const SizedBox(height: 16),

            // Map Mock Image
            Container(
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFFE2E8F0),
                image: const DecorationImage(
                  image: NetworkImage('https://maps.googleapis.com/maps/api/staticmap?center=30.044,31.235&zoom=14&size=600x300&maptype=roadmap&key=mock'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.location_pin, color: Color(0xFFDC2626), size: 40),
                  Positioned(
                    bottom: 12, right: 12,
                    child: GestureDetector(
                      onTap: _getCurrentLocation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                        ),
                        child: Row(
                          children: [
                            if (_isLoadingLoc)
                              const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFDC2626)))
                            else
                              const Icon(Icons.my_location_rounded, color: Color(0xFFDC2626), size: 16),
                            const SizedBox(width: 6),
                            const Text('Locate my location', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Fields
            Row(
              children: [
                const Icon(Icons.location_on_outlined, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Expanded(child: Text('${_cityCtrl.text}، ${_govCtrl.text} ${_streetCtrl.text}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
              ],
            ),
            const SizedBox(height: 16),
            
            _LocationField(ctrl: _cityCtrl, hint: 'المدينة'),
            const SizedBox(height: 12),
            _LocationField(ctrl: _govCtrl, hint: 'محافظة'),
            const SizedBox(height: 12),
            _LocationField(ctrl: _streetCtrl, hint: 'رقم المبنى'),
            
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  widget.onLocationSelected('${_cityCtrl.text}، ${_govCtrl.text} ${_streetCtrl.text}');
                  Navigator.of(context).pop();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('تأكيد', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  
  const _LocationField({required this.ctrl, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDC2626))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDC2626))),
      ),
    );
  }
}

// ─── SMALL EVIDENCE BUTTON ────────────────────────────────────────────────────────

class _EvidenceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _EvidenceButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFFDC2626), size: 28),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
