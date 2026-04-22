import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import '../core/localization/app_strings.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';

class ReportIncidentPage extends StatefulWidget {
  const ReportIncidentPage({super.key});

  @override
  State<ReportIncidentPage> createState() => _ReportIncidentPageState();
}

class _ReportIncidentPageState extends State<ReportIncidentPage> {
  String _selectedType = '';
  final TextEditingController _customTypeCtrl = TextEditingController();
  final TextEditingController _volunteersNeededCtrl = TextEditingController();

  String _locationText = '';

  // Storing items as maps to support different types: image, video, audio
  final List<Map<String, String>> _evidenceItems = [];
  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> _getTypes(BuildContext context) {
    final loc = context.loc;
    return [
      {'id': 'accident', 'label': loc.typeAccident, 'icon': Icons.car_crash_rounded},
      {'id': 'fire', 'label': loc.typeFireAlt, 'icon': Icons.local_fire_department_rounded},
      {'id': 'medical', 'label': loc.typeMedicalAlt, 'icon': Icons.medical_services_rounded},
      {'id': 'flood', 'label': loc.typeFlood, 'icon': Icons.flood_rounded},
      {'id': 'earthquake', 'label': loc.typeEarthquake, 'icon': Icons.house_siding_rounded},
      {'id': 'theft', 'label': loc.typeTheft, 'icon': Icons.back_hand_rounded},
      {'id': 'assault', 'label': loc.typeAssault, 'icon': Icons.sports_martial_arts_rounded},
      {'id': 'other', 'label': loc.typeOtherAlt, 'icon': Icons.more_horiz_rounded},
    ];
  }

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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    Navigator.pop(context);

    setState(() {
      _evidenceItems.add({'path': 'mock_audio_$method.mp3', 'type': 'audio'});
    });
  }

  // --- PICKERS ---

  void _showImageSourcePicker() {
    final theme = Theme.of(context);
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
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.camera_alt_rounded, color: theme.primaryColor),
              title: Text(loc.takePhoto, style: const TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library_rounded, color: theme.primaryColor),
              title: Text(loc.chooseFromGallery, style: const TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showVideoSourcePicker() {
    final theme = Theme.of(context);
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
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.videocam_rounded, color: theme.primaryColor),
              title: Text(loc.recordVideo, style: const TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                _pickVideo(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.video_library_rounded, color: theme.primaryColor),
              title: Text(loc.chooseFromGallery, style: const TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                _pickVideo(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showAudioSourcePicker() {
    final theme = Theme.of(context);
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
            const SizedBox(height: 12),
            ListTile(
              leading: Icon(Icons.mic_rounded, color: theme.primaryColor),
              title: Text(loc.evidenceRecord, style: const TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                _mockPickAudio('recording');
              },
            ),
            const SizedBox(height: 12),
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
          setState(() {
            _locationText = newLoc;
          });
        },
      ),
    );
  }

  void _showSuccessDialog() {
    final loc = context.loc;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final theme = Theme.of(context);
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark ? const Color(0xFF10B981).withValues(alpha: 0.2) : const Color(0xFF10B981).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF10B981),
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  loc.helpOnWayTitle,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, fontFamily: 'NotoSansArabic'),
                ),
                const SizedBox(height: 10),
                Text(
                  loc.helpOnWayDesc,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontFamily: 'NotoSansArabic',
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      loc.readInstructionsBtn,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'NotoSansArabic'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _triggerEmergencyAutomations() async {
    // 1. Send location to backend first
    try {
      final pos = await Geolocator.getCurrentPosition();
      // Use standard alert submission with location
      await ApiService.sendEmergencyAlert(
        type: _selectedType,
        lat: pos.latitude,
        lng: pos.longitude,
        description: _customTypeCtrl.text,
      );
    } catch (e) {
      debugPrint("Failed to send location: $e");
    }

    // 2. Fetch emergency contacts
    UserModel? user;
    try {
      user = await ApiService.fetchUserProfile();
    } catch (_) {}

    // 3. Trigger calls to official services (Direct calls)
    final officials = ['122', '123', '180'];
    for (var num in officials) {
      bool? res = await FlutterPhoneDirectCaller.callNumber(num);
      if (res == true) {
        // Wait longer if call was initiated to let the user finish
        await Future.delayed(const Duration(seconds: 10)); 
      }
    }

    // 4. Trigger calls to user's emergency contacts
    if (user != null && user.emergencyContacts.isNotEmpty) {
      for (var contact in user.emergencyContacts) {
        bool? res = await FlutterPhoneDirectCaller.callNumber(contact.phone);
        if (res == true) {
          await Future.delayed(const Duration(seconds: 10));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = context.loc;
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final cardColor = isDark ? theme.colorScheme.surfaceContainer : theme.colorScheme.surface;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          loc.reportIncidentTitle,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'NotoSansArabic'),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Incident Type
            Text(
              loc.incidentQuestion,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, fontFamily: 'NotoSansArabic'),
            ),
            const SizedBox(height: 20),
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
                  onTap: () => setState(() => _selectedType = t['id'] as String),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? theme.primaryColor : cardColor,
                          border: Border.all(
                            color: isSelected ? theme.primaryColor : theme.dividerColor.withValues(alpha: 0.08),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected ? theme.primaryColor.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          t['icon'] as IconData,
                          color: isSelected ? Colors.white : onSurface.withValues(alpha: 0.6),
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        t['label'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'NotoSansArabic',
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                          color: isSelected ? theme.primaryColor : onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            if (_selectedType == 'other') ...[
              const SizedBox(height: 20),
              TextField(
                controller: _customTypeCtrl,
                style: const TextStyle(fontFamily: 'NotoSansArabic', fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: loc.otherTypeHint,
                  hintStyle: TextStyle(color: onSurface.withValues(alpha: 0.35)),
                  filled: true,
                  fillColor: cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.primaryColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.primaryColor.withValues(alpha: 0.2))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.primaryColor, width: 2)),
                ),
              ),
            ],

            const SizedBox(height: 36),

            // 2. Location
            _SectionLabel(label: loc.locationLabel),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on_rounded, color: theme.primaryColor, size: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _locationText.isEmpty ? loc.locationUpdating : _locationText,
                      style: TextStyle(fontWeight: FontWeight.w600, color: onSurface, fontFamily: 'NotoSansArabic'),
                    ),
                  ),
                  TextButton(
                    onPressed: _showLocationSheet,
                    child: Text(
                      loc.changeLocation,
                      style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w900, fontFamily: 'NotoSansArabic'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Volunteers Needed
            _SectionLabel(label: loc.volunteersNeededLabel),
            const SizedBox(height: 14),
            TextField(
              controller: _volunteersNeededCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: loc.volunteersNeededHint,
                hintStyle: TextStyle(color: onSurface.withValues(alpha: 0.35)),
                filled: true,
                fillColor: cardColor,
                prefixIcon: Icon(Icons.people_alt_rounded, color: theme.primaryColor.withValues(alpha: 0.5)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.primaryColor, width: 1.5)),
              ),
            ),

            const SizedBox(height: 32),

            // 3. Evidence
            _SectionLabel(label: loc.addEvidenceLabel),
            const SizedBox(height: 16),
            if (_evidenceItems.isNotEmpty) ...[
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _evidenceItems.length,
                  separatorBuilder: (_, i) => const SizedBox(width: 14),
                  itemBuilder: (context, i) {
                    final item = _evidenceItems[i];
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: item['type'] == 'image'
                              ? Image.file(File(item['path']!), width: 110, height: 110, fit: BoxFit.cover)
                              : Container(
                                  width: 110,
                                  height: 110,
                                  color: theme.primaryColor.withValues(alpha: 0.1),
                                  child: Icon(item['type'] == 'video' ? Icons.videocam_rounded : Icons.mic_rounded, color: theme.primaryColor, size: 36),
                                ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => setState(() => _evidenceItems.removeAt(i)),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                              child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(child: _EvidenceButton(icon: Icons.camera_alt_rounded, label: loc.evidencePhoto, onTap: _showImageSourcePicker)),
                const SizedBox(width: 12),
                Expanded(child: _EvidenceButton(icon: Icons.videocam_rounded, label: loc.evidenceVideo, onTap: _showVideoSourcePicker)),
                const SizedBox(width: 12),
                Expanded(child: _EvidenceButton(icon: Icons.mic_rounded, label: loc.evidenceRecord, onTap: _showAudioSourcePicker)),
              ],
            ),

            const SizedBox(height: 48),

            // Report Button
            SizedBox(
              width: double.infinity,
              height: 60,
              child: FilledButton(
                onPressed: () async {
                  if (_selectedType.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.selectProblemFirst)));
                    return;
                  }
                  
                  // Start automations in background
                  _triggerEmergencyAutomations();
                  
                  _showSuccessDialog();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 4,
                  shadowColor: theme.primaryColor.withValues(alpha: 0.4),
                ),
                child: Text(
                  loc.reportBtn,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'NotoSansArabic'),
                ),
              ),
            ),
            const SizedBox(height: 48),
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
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, fontFamily: 'NotoSansArabic'),
    );
  }
}

// ─── BOTTOM SHEET FOR LOCATION ──────────────────────────────────────────────────

class _LocationBottomSheet extends StatefulWidget {
  final String initialLocation;
  final ValueChanged<String> onLocationSelected;

  const _LocationBottomSheet({
    required this.initialLocation,
    required this.onLocationSelected,
  });

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
    _cityCtrl.text = 'Maadi';
    _govCtrl.text = 'Cairo';
    _streetCtrl.text = '9th Street';
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLoc = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      if (p == LocationPermission.deniedForever) return;

      Position pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      List<Placemark> pm = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (pm.isNotEmpty) {
        final first = pm.first;
        setState(() {
          _cityCtrl.text = first.locality ?? first.subAdministrativeArea ?? '';
          _govCtrl.text = first.administrativeArea ?? '';
          _streetCtrl.text = first.street ?? '';
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
    final theme = Theme.of(context);
    final loc = context.loc;
    final onSurface = theme.colorScheme.onSurface;
    final cardColor = theme.colorScheme.surfaceContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -10))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(width: 48, height: 6, decoration: BoxDecoration(color: theme.dividerColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(3))),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(Icons.map_rounded, color: theme.primaryColor, size: 24),
              const SizedBox(width: 14),
              Text(loc.locationPickerTitle, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, fontFamily: 'NotoSansArabic')),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _searchCtrl,
            style: const TextStyle(fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: loc.searchAddressHint,
              hintStyle: TextStyle(color: onSurface.withValues(alpha: 0.35)),
              prefixIcon: Icon(Icons.search_rounded, color: theme.primaryColor.withValues(alpha: 0.5)),
              filled: true,
              fillColor: cardColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1))),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: cardColor,
              image: const DecorationImage(
                image: NetworkImage('https://maps.googleapis.com/maps/api/staticmap?center=30.044,31.235&zoom=14&size=600x300&maptype=roadmap&key=mock'),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.location_pin, color: theme.primaryColor, size: 48),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: ElevatedButton.icon(
                    onPressed: _isLoadingLoc ? null : _getCurrentLocation,
                    icon: _isLoadingLoc ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.my_location_rounded, size: 16),
                    label: Text(loc.findMyLocation, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.surface,
                      foregroundColor: theme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _LocField(ctrl: _cityCtrl, label: loc.cityLabel)),
              const SizedBox(width: 12),
              Expanded(child: _LocField(ctrl: _govCtrl, label: loc.govLabel)),
            ],
          ),
          const SizedBox(height: 16),
          _LocField(ctrl: _streetCtrl, label: loc.buildingLabel),
          const SizedBox(height: 32),
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: () {
                widget.onLocationSelected('${_cityCtrl.text}, ${_govCtrl.text} ${_streetCtrl.text}');
                Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(backgroundColor: theme.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: Text(loc.confirmLocationBtn, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'NotoSansArabic')),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _LocField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  const _LocField({required this.ctrl, required this.label});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: ctrl,
      style: const TextStyle(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.primaryColor.withValues(alpha: 0.7), fontWeight: FontWeight.bold, fontSize: 13),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainer,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.primaryColor, width: 1.5)),
      ),
    );
  }
}

class _EvidenceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _EvidenceButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: theme.primaryColor, size: 32),
            const SizedBox(height: 10),
            Text(label, style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w900, fontSize: 13, fontFamily: 'NotoSansArabic')),
          ],
        ),
      ),
    );
  }
}
