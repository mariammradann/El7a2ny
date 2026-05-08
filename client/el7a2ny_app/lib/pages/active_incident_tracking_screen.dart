import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import '../core/localization/app_strings.dart';
import '../widgets/incident_chat_sheet.dart';

class ActiveIncidentTrackingScreen extends StatefulWidget {
  final String incidentId;
  final double? initialLat;
  final double? initialLng;

  const ActiveIncidentTrackingScreen({
    super.key,
    required this.incidentId,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<ActiveIncidentTrackingScreen> createState() =>
      _ActiveIncidentTrackingScreenState();
}

class _ActiveIncidentTrackingScreenState
    extends State<ActiveIncidentTrackingScreen> {
  final MapController _mapController = MapController();
  late LatLng _incidentLocation;
  
  // Mock Volunteers Data
  List<Map<String, dynamic>> _volunteers = [];
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    // Default location (e.g. Cairo) if none provided
    _incidentLocation = LatLng(
        widget.initialLat ?? 30.0444, widget.initialLng ?? 31.2357);

    _initializeMockVolunteers();

    // Start polling to simulate movement
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _simulateVolunteerMovement();
    });
  }

  void _initializeMockVolunteers() {
    // Generate 2 mock volunteers near the incident
    final random = math.Random();
    _volunteers = [
      {
        'id': 'v1',
        'name': 'Ahmed Ali',
        'phone': '01011111111',
        'lat': _incidentLocation.latitude + (random.nextDouble() - 0.5) * 0.02,
        'lng': _incidentLocation.longitude + (random.nextDouble() - 0.5) * 0.02,
        'eta': '5 min',
        'status': 'en_route',
      },
      {
        'id': 'v2',
        'name': 'Sara Hassan',
        'phone': '01222222222',
        'lat': _incidentLocation.latitude + (random.nextDouble() - 0.5) * 0.03,
        'lng': _incidentLocation.longitude + (random.nextDouble() - 0.5) * 0.03,
        'eta': '8 min',
        'status': 'en_route',
      }
    ];
  }

  void _simulateVolunteerMovement() {
    if (!mounted) return;
    setState(() {
      for (var v in _volunteers) {
        // Move slightly towards the incident
        double currentLat = v['lat'];
        double currentLng = v['lng'];

        double diffLat = _incidentLocation.latitude - currentLat;
        double diffLng = _incidentLocation.longitude - currentLng;

        v['lat'] = currentLat + (diffLat * 0.1);
        v['lng'] = currentLng + (diffLng * 0.1);
        
        // Update ETA mock
        int currentEta = int.tryParse(v['eta'].split(' ')[0]) ?? 5;
        if (currentEta > 1 && math.Random().nextDouble() > 0.7) {
          v['eta'] = '${currentEta - 1} min';
        }
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAr = context.loc.isAr;

    return Scaffold(
      body: Stack(
        children: [
          // Flutter Map
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
                  // Incident Marker
                  Marker(
                    point: _incidentLocation,
                    width: 60,
                    height: 60,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 50,
                    ),
                  ),
                  // Volunteer Markers
                  ..._volunteers.map((v) {
                    return Marker(
                      point: LatLng(v['lat'], v['lng']),
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue.withValues(alpha: 0.2),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.directions_car,
                            color: Colors.blue,
                            size: 30,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // Top App Bar Overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 16,
                  right: 16,
                  bottom: 16),
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
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white),
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

          // Bottom Info Panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle line
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Status Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.people_alt_rounded,
                              color: Colors.blue),
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
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                isAr
                                    ? 'المساعدة قادمة إليك، يرجى البقاء آمناً'
                                    : 'Help is on the way, please stay safe',
                                style: TextStyle(
                                  fontFamily: 'NotoSansArabic',
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Volunteers List
                    if (_volunteers.isNotEmpty)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 150),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: _volunteers.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final v = _volunteers[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(
                                backgroundColor: Colors.blue,
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              title: Text(v['name'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                  isAr ? 'يصل خلال ${v['eta']}' : 'ETA: ${v['eta']}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.phone, color: Colors.green),
                                onPressed: () {},
                              ),
                            );
                          },
                        ),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Chat Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _openChatSheet,
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                      label: Text(
                        isAr ? 'التواصل مع المتطوعين' : 'Chat with Volunteers',
                        style: const TextStyle(
                          fontFamily: 'NotoSansArabic',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
