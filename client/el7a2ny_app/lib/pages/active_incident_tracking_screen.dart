import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import '../core/localization/app_strings.dart';
import '../models/alert_model.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../widgets/incident_chat_sheet.dart';
import 'package:url_launcher/url_launcher.dart';
import 'report_fake_incident_screen.dart';
import 'report_volunteer_screen.dart';
import 'user_rating_screen.dart';
import 'sign_up_screen.dart';
import 'volunteer_rating_screen.dart';
import 'banned_screen.dart';
import '../core/auth/auth_token_store.dart';
import '../widgets/global_fab_overlay.dart';

class ActiveIncidentTrackingScreen extends StatefulWidget {
  final String incidentId;
  final double? initialLat;
  final double? initialLng;
  /// Pass `true` if the current user is the one who created the report.
  /// Pass `false` if the current user is a volunteer responding to it.
  /// If null, falls back to session/API detection.
  final bool? isCreatorOverride;

  const ActiveIncidentTrackingScreen({
    super.key,
    required this.incidentId,
    this.initialLat,
    this.initialLng,
    this.isCreatorOverride,
  });

  @override
  State<ActiveIncidentTrackingScreen> createState() =>
      _ActiveIncidentTrackingScreenState();
}

class _ActiveIncidentTrackingScreenState
    extends State<ActiveIncidentTrackingScreen> {
  final MapController _mapController = MapController();
  late LatLng _incidentLocation;
  List<Map<String, dynamic>> _volunteers = [];
  Timer? _pollingTimer;
  Timer? _volunteerLocationTimer;
  int _previousVolunteerCount = 0;
  AlertModel? _alertDetails;
  bool _hasShownCompletionPopup = false;
  bool _canceling = false;
  bool _dangerEnding = false;

  bool get _isCreator {
    // Highest priority: explicit override passed when navigating to this screen
    if (widget.isCreatorOverride != null) return widget.isCreatorOverride!;

    // Second: check session role set right before navigation
    if (SessionService().incidentRole == IncidentRole.volunteer) return false;
    if (SessionService().incidentRole == IncidentRole.reporter) return true;

    // Only use API data once loaded — do NOT default to creator during loading
    if (_alertDetails == null) return false; // neutral: show loading skeleton
    if (_alertDetails!.isMyAlert) return true;
    // Guests are always creators because volunteers must be logged in
    if (AuthTokenStore.userId == null || AuthTokenStore.userId == 'guest')
      return true;
    return false;
  }

  @override
  void initState() {
    super.initState();
    _incidentLocation = LatLng(
      widget.initialLat ?? 30.0444,
      widget.initialLng ?? 31.2357,
    );
    _fetchIncidentDetails();
    _fetchResponders();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchIncidentDetails();
      _fetchResponders();
    });
    if (!_isCreator) {
      _startVolunteerLocationUpdates();
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _volunteerLocationTimer?.cancel();
    super.dispose();
  }

  void _startVolunteerLocationUpdates() {
    if (_volunteerLocationTimer != null) return;
    _sendVolunteerLocation();
    _volunteerLocationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _sendVolunteerLocation();
    });
  }

  Future<void> _sendVolunteerLocation() async {
    if (!mounted) return;
    if (_isCreator) {
      _volunteerLocationTimer?.cancel();
      _volunteerLocationTimer = null;
      return;
    }
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      await ApiService.updateResponderLocation(
        widget.incidentId,
        pos.latitude,
        pos.longitude,
      );
      debugPrint('Volunteer live location updated: ${pos.latitude}, ${pos.longitude}');
    } catch (e) {
      debugPrint('Error updating volunteer live location: $e');
    }
  }

  void _fitMapCamera() {
    if (!mounted || _volunteers.isEmpty) return;
    try {
      final validVolunteers = _volunteers.where((v) => v['lat'] != null && v['lng'] != null);
      final points = [
        _incidentLocation,
        ...validVolunteers.map((v) => LatLng(v['lat'] as double, v['lng'] as double)),
      ];
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(50.0),
        ),
      );
    } catch (e) {
      debugPrint('Error fitting map camera: $e');
    }
  }

  Future<void> _fetchResponders() async {
    try {
      final responders = await ApiService.fetchIncidentResponders(
        widget.incidentId,
      );
      if (!mounted) return;
      
      final updatedVolunteers = responders
          .map(
            (r) => {
              'id': r['id'],
              'name': r['name'] ?? 'Volunteer',
              'phone': r['phone'] ?? '',
              'lat': r['lat'] != null ? (r['lat'] as num).toDouble() : null,
              'lng': r['lng'] != null ? (r['lng'] as num).toDouble() : null,
              'eta': (r['lat'] != null && r['lng'] != null)
                  ? _calculateEta(r['lat'], r['lng'])
                  : null,
              'status': 'en_route',
              'badges': r['badges'] ?? [],
            },
          )
          .toList();

      setState(() {
        _volunteers = updatedVolunteers;
      });

      if (_volunteers.length > _previousVolunteerCount) {
        _previousVolunteerCount = _volunteers.length;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _fitMapCamera();
        });
      } else {
        _previousVolunteerCount = _volunteers.length;
      }
    } catch (e) {
      debugPrint('Error fetching responders: $e');
    }
  }

  String _calculateEta(dynamic lat, dynamic lng) {
    const earthRadius = 6371.0;
    final lat1 = _incidentLocation.latitude * (math.pi / 180);
    final lat2 = (lat as num).toDouble() * (math.pi / 180);
    final dLat = lat2 - lat1;
    final dLng =
        ((lng as num).toDouble() - _incidentLocation.longitude) *
        (math.pi / 180);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final distance =
        earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final minutes = ((distance / 30) * 60).round();
    return minutes < 1 ? '< 1 min' : '$minutes min';
  }

  Future<void> _fetchIncidentDetails() async {
    try {
      final details = await ApiService.fetchAlertDetails(widget.incidentId);
      if (mounted && details != null) {
        setState(() {
          _alertDetails = details;
        });

        if (!_isCreator) {
          _startVolunteerLocationUpdates();
        }

        // If the incident is resolved or finished, clear it from session
        if (details.status.toLowerCase() == 'resolved' ||
            details.status.toLowerCase() == 'completed' ||
            details.status.toLowerCase() == 'cancelled') {
          if (!_hasShownCompletionPopup) {
            _hasShownCompletionPopup = true;
            SessionService().setActiveIncident(null);
            if (_isCreator) {
              _checkBanAndShowRating();
            } else {
              _showCompletionPopup();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching incident details: $e');
    }
  }

  Future<void> _checkBanAndShowRating() async {
    try {
      final user = await ApiService.fetchUserProfile();
      if (user.status == 'banned' && user.bannedUntil != null) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => BannedScreen(bannedUntil: user.bannedUntil!),
            ),
          );
        }
        return;
      }
    } catch (e) {
      debugPrint('Error checking user ban status: $e');
    }

    if (mounted) {
      _showCreatorRatingPopup();
    }
  }

  Future<void> _showCompletionPopup() async {
    final isAr = context.loc.isAr;
    final isFake = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAr ? 'انتهاء البلاغ' : 'Incident Ended',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            isAr
                ? 'تم إنهاء هذا البلاغ.\nهل كان البلاغ كاذباً؟'
                : 'This incident has ended.\nWas it a false alarm?',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                isAr ? 'لا، بلاغ حقيقي' : 'No, Real',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE61717),
              ),
              child: Text(
                isAr ? 'نعم، كاذب' : 'Yes, Fake',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (mounted) {
      if (isFake == true) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ReportFakeIncidentScreen(
              incidentId: widget.incidentId,
              incidentDetails: _alertDetails,
            ),
            settings: const RouteSettings(name: '/report_fake_incident'),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const VolunteerRatingScreen(),
            settings: const RouteSettings(name: '/volunteer_rating'),
          ),
        );
      }
    }
  }

  Future<void> _showCreatorRatingPopup() async {
    final isAr = context.loc.isAr;
    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.star_rate_rounded,
                color: const Color(0xFFF18F34),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAr ? 'تقييم التجربة' : 'Rate Experience',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            isAr
                ? 'لقد انتهى البلاغ. هل ترغب في تقييم تجربتك أم الإبلاغ عن متطوع أساء التصرف؟'
                : 'The incident has ended. Would you like to rate your experience or report a volunteer?',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'skip'),
              child: Text(
                isAr ? 'تخطي' : 'Skip',
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (_volunteers.isNotEmpty)
              TextButton(
                onPressed: () => Navigator.pop(context, 'report'),
                child: Text(
                  isAr ? 'الإبلاغ' : 'Report',
                  style: const TextStyle(
                    color: const Color(0xFFE61717),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 'rate'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text(
                isAr ? 'تقييم التجربة' : 'Rate Experience',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (mounted) {
      if (action == 'report') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ReportVolunteerScreen(volunteers: _volunteers),
            settings: const RouteSettings(name: '/report_volunteer'),
          ),
        );
      } else if (action == 'rate') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const UserRatingScreen(),
            settings: const RouteSettings(name: '/user_rating'),
          ),
        );
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  void _openChatSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => IncidentChatSheet(
        incidentId: widget.incidentId,
        volunteers: _volunteers,
      ),
    );
  }

  Future<void> _cancelIncident() async {
    final isAr = context.loc.isAr;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          title: Text(
            isAr ? 'إلغاء البلاغ' : 'Cancel Incident',
            style: const TextStyle(
              fontFamily: 'NotoSansArabic',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            isAr
                ? 'هل أنت متأكد من إلغاء هذا البلاغ نهائياً؟'
                : 'Are you sure you want to cancel this incident?',
            style: const TextStyle(fontFamily: 'NotoSansArabic'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                isAr ? 'تراجع' : 'No',
                style: const TextStyle(fontFamily: 'NotoSansArabic'),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                isAr ? 'نعم، إلغاء' : 'Yes, Cancel',
                style: const TextStyle(
                  color: const Color(0xFFE61717),
                  fontFamily: 'NotoSansArabic',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      setState(() => _canceling = true);
      try {
        await ApiService.updateAlertStatus(widget.incidentId, 'cancelled');
        SessionService().setActiveIncident(null);
        if (mounted) {
          if (_isCreator) {
            final isGuest =
                AuthTokenStore.userId == null ||
                AuthTokenStore.userId == 'guest';
            if (isGuest) {
              _showGuestRegistrationPopup();
            } else {
              _showCreatorRatingPopup();
            }
          } else {
            Navigator.of(context).pop();
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isAr ? 'حدث خطأ أثناء الإلغاء' : 'Error cancelling incident',
                style: const TextStyle(fontFamily: 'NotoSansArabic'),
              ),
              backgroundColor: const Color(0xFFE61717),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _canceling = false);
      }
    }
  }

  Future<void> _dangerEnded() async {
    final isAr = context.loc.isAr;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          title: Text(
            isAr ? 'انتهاء الخطر' : 'Danger Ended',
            style: const TextStyle(
              fontFamily: 'NotoSansArabic',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            isAr
                ? 'هل تود إنهاء البلاغ لأن الخطر قد انتهى؟'
                : 'Would you like to end the incident because the danger has ended?',
            style: const TextStyle(fontFamily: 'NotoSansArabic'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                isAr ? 'تراجع' : 'Cancel',
                style: const TextStyle(fontFamily: 'NotoSansArabic'),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                isAr ? 'نعم، انتهى' : 'Yes, Ended',
                style: const TextStyle(
                  color: Colors.green,
                  fontFamily: 'NotoSansArabic',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      setState(() => _dangerEnding = true);
      try {
        await ApiService.updateAlertStatus(widget.incidentId, 'resolved');
        SessionService().setActiveIncident(null);
        if (mounted) {
          if (_isCreator) {
            final isGuest =
                AuthTokenStore.userId == null ||
                AuthTokenStore.userId == 'guest';
            if (isGuest) {
              _showGuestRegistrationPopup();
            } else {
              _showCreatorRatingPopup();
            }
          } else {
            Navigator.of(context).pop();
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isAr ? 'حدث خطأ' : 'Error',
                style: const TextStyle(fontFamily: 'NotoSansArabic'),
              ),
              backgroundColor: const Color(0xFFE61717),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _dangerEnding = false);
      }
    }
  }

  void _showGuestRegistrationPopup() {
    final isAr = context.loc.isAr;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            isAr ? 'تنبيه' : 'Notice',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'NotoSansArabic',
            ),
          ),
          content: Text(
            isAr
                ? 'لكي تتمكن من استخدام التطبيق مرة أخرى، يجب عليك إنشاء حساب.'
                : 'To use the app again, you must create an account.',
            style: const TextStyle(fontSize: 16, fontFamily: 'NotoSansArabic'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(context).pop();
              },
              child: Text(
                isAr ? 'تخطي' : 'Skip',
                style: const TextStyle(
                  color: Colors.grey,
                  fontFamily: 'NotoSansArabic',
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SignUpScreen(),
                    settings: const RouteSettings(name: '/signup'),
                  ),
                );
                if (mounted) {
                  _showCreatorRatingPopup();
                }
              },
              child: Text(
                isAr ? 'إنشاء حساب' : 'Register',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'NotoSansArabic',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchMaps() async {
    final lat = _incidentLocation.latitude;
    final lng = _incidentLocation.longitude;
    final uri = Uri.parse(
      "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng",
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        final isAr = context.loc.isAr;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr ? 'لا يمكن فتح الخرائط' : 'Could not open maps',
              style: const TextStyle(fontFamily: 'NotoSansArabic'),
            ),
          ),
        );
      }
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Ensure global FABs are visible on this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GlobalFabController.show();
      GlobalFabController.currentRoute.value = '/active-incident';
    });

    final theme = Theme.of(context);
    final isAr = context.loc.isAr;

    return Scaffold(
      body: Stack(
        children: [
          // ── Map ──
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _incidentLocation,
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.el7a2ny_app',
              ),
              MarkerLayer(
                markers: [
                  // Incident pin
                  Marker(
                    point: _incidentLocation,
                    width: 60,
                    height: 60,
                    child: const Icon(
                      Icons.location_on,
                      color: const Color(0xFFE61717),
                      size: 50,
                    ),
                  ),
                  // Responder pins
                  ..._volunteers
                      .where((v) => v['lat'] != null && v['lng'] != null)
                      .map(
                        (v) => Marker(
                          point: LatLng(v['lat'] as double, v['lng'] as double),
                          width: 60,
                          height: 60,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade700,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (v['badges'] != null && (v['badges'] as List).isNotEmpty) ...[
                                      const Icon(
                                        Icons.military_tech_rounded,
                                        color: Color(0xFFFFD700),
                                        size: 11,
                                      ),
                                      const SizedBox(width: 2),
                                    ],
                                    Text(
                                      v['name'].toString().split(' ').first,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blue.withValues(alpha: 0.2),
                                ),
                                child: const Icon(
                                  Icons.person_pin_circle_rounded,
                                  color: Colors.blue,
                                  size: 34,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            ],
          ),

          // ── Recenter Map Button ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            right: isAr ? null : 16,
            left: isAr ? 16 : null,
            child: FloatingActionButton.small(
              heroTag: 'recenter_map',
              backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
              foregroundColor: Theme.of(context).primaryColor,
              onPressed: _fitMapCamera,
              child: const Icon(Icons.my_location_rounded),
            ),
          ),

          // ── Top bar ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 10,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isAr ? 'تتبع البلاغ' : 'Incident Tracking',
                      style: const TextStyle(
                        fontFamily: 'NotoSansArabic',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom panel ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 15,
                    spreadRadius: 1,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Handle
                        Center(
                          child: Container(
                            width: 50,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(2.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),



                      if (!_isCreator) ...[ 
                        // ── Volunteer View ──
                        // Show loading placeholder if incident details not loaded yet
                        if (_alertDetails == null) ...[
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ] else ...[
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.info_outline_rounded,
                                  color: Colors.green),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isAr ? 'تفاصيل البلاغ' : 'Incident Details',
                                    style: const TextStyle(
                                      fontFamily: 'NotoSansArabic',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    isAr ? 'أنت في طريقك للمساعدة' : 'You are on your way to help',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        fontFamily: 'NotoSansArabic'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAr ? 'صاحب البلاغ: ${_alertDetails!.reporterName ?? 'مستخدم'}' : 'Reporter: ${_alertDetails!.reporterName ?? 'User'}',
                                style: const TextStyle(fontFamily: 'NotoSansArabic', fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isAr ? 'نوع البلاغ: ${_alertDetails!.getLocalizedType(context.loc)}' : 'Type: ${_alertDetails!.type}',
                                style: const TextStyle(fontFamily: 'NotoSansArabic', fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isAr ? 'الموقع: ${_alertDetails!.address ?? _alertDetails!.location}' : 'Location: ${_alertDetails!.address ?? _alertDetails!.location}',
                                style: const TextStyle(fontFamily: 'NotoSansArabic'),
                              ),
                              if (_alertDetails!.description != null && _alertDetails!.description!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  isAr ? 'الوصف: ${_alertDetails!.description}' : 'Description: ${_alertDetails!.description}',
                                  style: const TextStyle(fontFamily: 'NotoSansArabic'),
                                ),
                              ],
                              if (_alertDetails!.mediaUrls != null && _alertDetails!.mediaUrls!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  isAr ? 'الصور المرفقة:' : 'Attached Photos:',
                                  style: const TextStyle(
                                    fontFamily: 'NotoSansArabic',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 100,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _alertDetails!.mediaUrls!.length,
                                    itemBuilder: (context, idx) {
                                      final mediaUrl = _alertDetails!.mediaUrls![idx];
                                      final absoluteMediaUrl = mediaUrl.startsWith('http')
                                          ? mediaUrl
                                          : '${ApiService.baseUrl}${mediaUrl.startsWith('/') ? '' : '/'}$mediaUrl';
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          right: isAr ? 8 : 0,
                                          left: isAr ? 0 : 8,
                                        ),
                                        child: GestureDetector(
                                          onTap: () {
                                            showDialog(
                                              context: context,
                                              barrierDismissible: true,
                                              builder: (context) => Dialog(
                                                backgroundColor: Colors.black.withValues(alpha: 0.85),
                                                insetPadding: const EdgeInsets.all(16),
                                                child: Stack(
                                                  alignment: Alignment.center,
                                                  children: [
                                                    InteractiveViewer(
                                                      panEnabled: true,
                                                      minScale: 0.5,
                                                      maxScale: 4.0,
                                                      child: ClipRRect(
                                                        borderRadius: BorderRadius.circular(16),
                                                        child: Image.network(
                                                          absoluteMediaUrl,
                                                          fit: BoxFit.contain,
                                                          loadingBuilder: (context, child, loadingProgress) {
                                                            if (loadingProgress == null) return child;
                                                            return const Center(
                                                              child: CircularProgressIndicator(
                                                                color: Colors.white,
                                                              ),
                                                            );
                                                          },
                                                          errorBuilder: (context, error, stackTrace) =>
                                                              Container(
                                                            color: Colors.black54,
                                                            padding: const EdgeInsets.all(24),
                                                            child: Column(
                                                              mainAxisSize: MainAxisSize.min,
                                                              children: [
                                                                const Icon(Icons.broken_image, color: Colors.white, size: 50),
                                                                const SizedBox(height: 12),
                                                                Text(
                                                                  isAr ? 'خطأ في تحميل الصورة' : 'Failed to load image',
                                                                  style: const TextStyle(color: Colors.white),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Positioned(
                                                      top: 8,
                                                      right: 8,
                                                      child: Container(
                                                        decoration: const BoxDecoration(
                                                          color: Colors.black54,
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: IconButton(
                                                          icon: const Icon(Icons.close, color: Colors.white, size: 24),
                                                          onPressed: () => Navigator.of(context).pop(),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              absoluteMediaUrl,
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  Container(
                                                width: 100,
                                                height: 100,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.withValues(alpha: 0.2),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Icon(
                                                  Icons.broken_image,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ]
                            ],
                          ),
                        ),
                        if (_alertDetails != null &&
                            ((_alertDetails!.getSummary(isAr) != null && _alertDetails!.getSummary(isAr)!.isNotEmpty) ||
                                (_alertDetails!.getVolunteerInstructions(isAr) != null &&
                                    _alertDetails!.getVolunteerInstructions(isAr)!.isNotEmpty))) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.shade900.withValues(alpha: 0.1),
                                  Colors.indigo.shade900.withValues(alpha: 0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.blue.shade300.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.psychology_rounded,
                                      color: Colors.blueAccent,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isAr ? 'تحليل الذكاء الاصطناعي للاستجابة السريعة' : 'AI Analysis & Triage Briefing',
                                      style: const TextStyle(
                                        fontFamily: 'NotoSansArabic',
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueAccent,
                                      ),
                                    ),
                                  ],
                                ),
                                if (_alertDetails!.getSummary(isAr) != null && _alertDetails!.getSummary(isAr)!.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    isAr ? 'ملخص البلاغ:' : 'Incident Summary:',
                                    style: const TextStyle(
                                      fontFamily: 'NotoSansArabic',
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _alertDetails!.getSummary(isAr)!,
                                    style: TextStyle(
                                      fontFamily: 'NotoSansArabic',
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                                if (_alertDetails!.getVolunteerInstructionsList(isAr) != null && _alertDetails!.getVolunteerInstructionsList(isAr)!.isNotEmpty) ...[
                                  const Divider(height: 24, thickness: 1),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.health_and_safety_rounded,
                                        color: Color(0xFF10B981),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        isAr ? 'تعليمات فور الوصول للموقع:' : 'On-Arrival Instructions:',
                                        style: const TextStyle(
                                          fontFamily: 'NotoSansArabic',
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF10B981),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ..._alertDetails!.getVolunteerInstructionsList(isAr)!.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final step = entry.value;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 10.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 22,
                                            height: 22,
                                            margin: const EdgeInsets.only(top: 2),
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: LinearGradient(
                                                colors: [
                                                  Color(0xFF10B981),
                                                  Color(0xFF059669),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              '${index + 1}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              step,
                                              style: TextStyle(
                                                fontFamily: 'NotoSansArabic',
                                                fontSize: 13,
                                                color: Colors.grey.shade700,
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Directions Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _launchMaps,
                            icon: const Icon(Icons.directions_rounded),
                            label: Text(
                              isAr ? 'احصل على الاتجاهات' : 'Get Directions',
                              style: const TextStyle(
                                fontFamily: 'NotoSansArabic',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Help Completed Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const VolunteerRatingScreen(),
                                  settings: const RouteSettings(
                                    name: '/volunteer-rating',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.check_circle_outline_rounded,
                            ),
                            label: Text(
                              isAr
                                  ? 'تمت المساعدة (إنهاء)'
                                  : 'Help Completed (Finish)',
                              style: const TextStyle(
                                fontFamily: 'NotoSansArabic',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _openChatSheet,
                                icon: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                ),
                                label: Text(
                                  isAr ? 'تواصل' : 'Chat',
                                  style: const TextStyle(
                                    fontFamily: 'NotoSansArabic',
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFE61717),
                                  side: const BorderSide(
                                    color: const Color(0xFFE61717),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ReportFakeIncidentScreen(
                                            incidentId: widget.incidentId,
                                            incidentDetails: _alertDetails,
                                          ),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.report_problem_outlined,
                                ),
                                label: Text(
                                  isAr ? 'بلاغ كاذب' : 'Fake Report',
                                  style: const TextStyle(
                                    fontFamily: 'NotoSansArabic',
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        ], // end of else (alertDetails != null) inner block
                      ] else ...[
                          // ── Creator View ──
                          // Volunteers Header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.people_alt_rounded,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isAr
                                          ? '${_volunteers.length} متطوعين في الطريق'
                                          : '${_volunteers.length} volunteers en route',
                                      style: const TextStyle(
                                        fontFamily: 'NotoSansArabic',
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      isAr
                                          ? 'المساعدة قادمة إليك'
                                          : 'Help is on the way',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Volunteers List
                          if (_volunteers.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.hourglass_empty_rounded,
                                    color: Colors.grey.shade400,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isAr
                                        ? 'لا يوجد متطوعون بعد'
                                        : 'No volunteers yet',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              constraints: const BoxConstraints(maxHeight: 160),
                              child: ListView.separated(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemCount: _volunteers.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final v = _volunteers[index];
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.blue.shade700,
                                      child: Text(
                                        v['name']
                                            .toString()
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Wrap(
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        Text(
                                          v['name'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (v['badges'] != null && (v['badges'] as List).isNotEmpty)
                                          ... (v['badges'] as List).map<Widget>((badge) {
                                            final badgeName = isAr
                                                ? (badge['badge_name_ar'] ?? badge['badge_name_en'] ?? '')
                                                : (badge['badge_name_en'] ?? '');
                                            return Tooltip(
                                              message: badgeName,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFDC800).withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: const Color(0xFFFDC800),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.military_tech_rounded,
                                                      color: Color(0xFFB48900),
                                                      size: 11,
                                                    ),
                                                    const SizedBox(width: 2),
                                                    Text(
                                                      badgeName,
                                                      style: const TextStyle(
                                                        fontSize: 8.5,
                                                        fontWeight: FontWeight.bold,
                                                        color: Color(0xFFB48900),
                                                        fontFamily: 'NotoSansArabic',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                      ],
                                    ),
                                    subtitle: Text(
                                      v['eta'] != null
                                          ? (isAr
                                              ? 'يصل خلال ${v['eta']}'
                                              : 'ETA: ${v['eta']}')
                                          : (isAr
                                              ? 'جاري تحديد الموقع...'
                                              : 'Locating...'),
                                    ),
                                    trailing:
                                        v['phone'] != null &&
                                            v['phone'].toString().isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(
                                              Icons.phone,
                                              color: Colors.green,
                                            ),
                                            onPressed: () {},
                                          )
                                        : null,
                                  );
                                },
                              ),
                            ),
                          if (_alertDetails != null &&
                              ((_alertDetails!.getSummary(isAr) != null &&
                                      _alertDetails!
                                          .getSummary(isAr)!
                                          .isNotEmpty) ||
                                  (_alertDetails!.getInstructionsList(isAr) !=
                                          null &&
                                      _alertDetails!
                                          .getInstructionsList(isAr)!
                                          .isNotEmpty))) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(
                                      0xFFE95F32,
                                    ).withValues(alpha: 0.1),
                                    const Color(
                                      0xFF8A1717,
                                    ).withValues(alpha: 0.05),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(
                                    0xFFF18F34,
                                  ).withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFF18F34,
                                    ).withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.security_rounded,
                                        color: const Color(0xFFF18F34),
                                        size: 22,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isAr
                                            ? 'إرشادات السلامة الفورية (AI)'
                                            : 'Immediate Safety Actions (AI)',
                                        style: const TextStyle(
                                          fontFamily: 'NotoSansArabic',
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFFF18F34),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_alertDetails!.getSummary(isAr) != null &&
                                      _alertDetails!
                                          .getSummary(isAr)!
                                          .isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      isAr
                                          ? 'ملخص تحليل الطوارئ:'
                                          : 'Emergency Analysis Summary:',
                                      style: const TextStyle(
                                        fontFamily: 'NotoSansArabic',
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _alertDetails!.getSummary(isAr)!,
                                      style: TextStyle(
                                        fontFamily: 'NotoSansArabic',
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                  if (_alertDetails!.getInstructionsList(
                                            isAr,
                                          ) !=
                                          null &&
                                      _alertDetails!
                                          .getInstructionsList(isAr)!
                                          .isNotEmpty) ...[
                                    const Divider(height: 24, thickness: 1),
                                    Text(
                                      isAr
                                          ? 'خطوات السلامة المطلوبة منك:'
                                          : 'Safety Steps to Follow Now:',
                                      style: const TextStyle(
                                        fontFamily: 'NotoSansArabic',
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ..._alertDetails!
                                        .getInstructionsList(isAr)!
                                        .map(
                                          (instruction) => Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 8.0,
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  margin: const EdgeInsets.only(
                                                    top: 2,
                                                  ),
                                                  padding: const EdgeInsets.all(
                                                    2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFFF18F34,
                                                    ).withValues(alpha: 0.15),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.check_rounded,
                                                    color: const Color(
                                                      0xFFF18F34,
                                                    ),
                                                    size: 14,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    instruction,
                                                    style: TextStyle(
                                                      fontFamily:
                                                          'NotoSansArabic',
                                                      fontSize: 13,
                                                      color:
                                                          Colors.grey.shade700,
                                                      height: 1.4,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),

                          // Creator Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: _openChatSheet,
                                  icon: const Icon(
                                    Icons.chat_bubble_outline_rounded,
                                  ),
                                  label: Text(
                                    isAr ? 'تواصل' : 'Chat',
                                    style: const TextStyle(
                                      fontFamily: 'NotoSansArabic',
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFE61717),
                                    side: const BorderSide(
                                      color: const Color(0xFFE61717),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: _canceling
                                      ? null
                                      : _cancelIncident,
                                  icon: _canceling
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: const Color(0xFFE61717),
                                          ),
                                        )
                                      : const Icon(Icons.cancel_outlined),
                                  label: Text(
                                    isAr ? 'إلغاء البلاغ' : 'Cancel Report',
                                    style: const TextStyle(
                                      fontFamily: 'NotoSansArabic',
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _dangerEnding ? null : _dangerEnded,
                              icon: _dangerEnding
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.check_circle_outline_rounded,
                                    ),
                              label: Text(
                                isAr ? 'الخطر انتهى' : 'Danger Ended',
                                style: const TextStyle(
                                  fontFamily: 'NotoSansArabic',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          ],
        ),
    );
  }
}
