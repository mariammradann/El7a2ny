import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import '../core/auth/auth_token_store.dart';
import '../core/localization/app_strings.dart';
import '../models/alert_model.dart';
import '../services/api_service.dart';
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
  List<Map<String, dynamic>> _volunteers = [];
  Timer? _pollingTimer;
  AlertModel? _alertDetails;
  bool _loadingDetails = true;

  @override
  void initState() {
    super.initState();
    _incidentLocation = LatLng(
        widget.initialLat ?? 30.0444, widget.initialLng ?? 31.2357);
    _initializeMockVolunteers();
    _fetchIncidentDetails();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _simulateVolunteerMovement();
      _fetchIncidentDetails();
    });
  }

  void _initializeMockVolunteers() {
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
        double diffLat = _incidentLocation.latitude - v['lat'];
        double diffLng = _incidentLocation.longitude - v['lng'];
        v['lat'] = v['lat'] + (diffLat * 0.1);
        v['lng'] = v['lng'] + (diffLng * 0.1);
        int currentEta = int.tryParse(v['eta'].split(' ')[0]) ?? 5;
        if (currentEta > 1 && math.Random().nextDouble() > 0.7) {
          v['eta'] = '${currentEta - 1} min';
        }
      }
    });
  }

  Future<void> _fetchIncidentDetails() async {
    try {
      final details = await ApiService.fetchAlertDetails(widget.incidentId);
      if (mounted && details != null) {
        setState(() {
          _alertDetails = details;
          _loadingDetails = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching incident details: $e');
    }
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

  // ── AI Analysis helpers ───────────────────────────────────────────────────

  Map<String, dynamic>? get _analysis => _alertDetails?.aiAnalysis;

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical': return const Color(0xFFB71C1C);
      case 'high':    return const Color(0xFFE53935);
      case 'medium':  return const Color(0xFFF57C00);
      case 'low':     return const Color(0xFF1976D2);
      default:        return Colors.grey;
    }
  }

  String _severityLabel(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical': return 'حرج';
      case 'high':     return 'عالي';
      case 'medium':   return 'متوسط';
      case 'low':      return 'منخفض';
      default:         return severity;
    }
  }

  Color _validityColor(String validity) {
    switch (validity) {
      case 'genuine':          return const Color(0xFF2E7D32);
      case 'uncertain':        return const Color(0xFFF57C00);
      case 'likely_false':     return const Color(0xFFE53935);
      case 'definitely_false': return const Color(0xFFB71C1C);
      default:                 return Colors.grey;
    }
  }

  String _validityLabel(String validity) {
    switch (validity) {
      case 'genuine':          return '✅ بلاغ حقيقي';
      case 'uncertain':        return '⚠️ غير مؤكد';
      case 'likely_false':     return '❌ محتمل مزيف';
      case 'definitely_false': return '🚫 مزيف';
      default:                 return validity;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'vehicle':      return Icons.directions_car_rounded;
      case 'living_being': return Icons.person_rounded;
      default:             return Icons.category_rounded;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAr = context.loc.isAr;

    return Scaffold(
      body: Stack(
        children: [
          // Map
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
                  Marker(
                    point: _incidentLocation,
                    width: 60,
                    height: 60,
                    child: const Icon(Icons.location_on, color: Colors.red, size: 50),
                  ),
                  ..._volunteers.map((v) => Marker(
                    point: LatLng(v['lat'], v['lng']),
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue.withValues(alpha: 0.2),
                      ),
                      child: const Icon(Icons.person_pin_circle_rounded,
                          color: Colors.blue, size: 34),
                    ),
                  )),
                ],
              ),
            ],
          ),

          // Top bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 10,
                left: 16, right: 16, bottom: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
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
                  // Severity chip in top bar (if analysis available)
                  if (_analysis != null && _analysis!['severity'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _severityColor(_analysis!['severity']),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _severityLabel(_analysis!['severity']),
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Bottom panel
          Positioned(
            bottom: 0, left: 0, right: 0,
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
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          width: 40, height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── AI Analysis Card ────────────────────────────────
                      if (_analysis != null) ...[
                        _buildAnalysisCard(theme),
                        const SizedBox(height: 12),
                      ] else if (_alertDetails?.mediaUrls != null &&
                          _alertDetails!.mediaUrls!.isNotEmpty) ...[
                        _buildAnalyzingCard(theme, isAr),
                        const SizedBox(height: 12),
                      ],

                      // ── Safety Instructions ────────────────────────────
                      if (_alertDetails?.aiInstructions != null &&
                          _alertDetails!.aiInstructions!.isNotEmpty) ...[
                        _buildInstructionsCard(theme, isAr),
                        const SizedBox(height: 12),
                      ],

                      // ── Volunteers header ──────────────────────────────
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.people_alt_rounded, color: Colors.blue),
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
                                  isAr ? 'المساعدة قادمة إليك' : 'Help is on the way',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Volunteers list
                      if (_volunteers.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 130),
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: _volunteers.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final v = _volunteers[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.blue,
                                  child: Icon(Icons.person, color: Colors.white),
                                ),
                                title: Text(v['name'],
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
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

                      const SizedBox(height: 12),

                      // Chat button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _openChatSheet,
                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                        label: Text(
                          isAr ? 'التواصل مع المتطوعين' : 'Chat with Volunteers',
                          style: const TextStyle(
                            fontFamily: 'NotoSansArabic',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sub-widgets ───────────────────────────────────────────────────────────

  Widget _buildAnalysisCard(ThemeData theme) {
    final a = _analysis!;
    final validity   = a['incident_validity'] as String? ?? 'uncertain';
    final severity   = a['severity'] as String? ?? 'low';
    final incType    = a['incident_type'] as String? ?? '';
    final confidence = ((a['confidence'] as num?)?.toDouble() ?? 0) * 100;
    final falsePct   = ((a['false_report_probability'] as num?)?.toDouble() ?? 0) * 100;
    final objects    = a['detected_objects'] as List? ?? [];
    final risks      = a['risks'] as List? ?? [];
    final actions    = a['recommended_actions'] as List? ?? [];
    final duplicate  = a['duplicate_detected'] as bool? ?? false;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _validityColor(validity).withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(16),
        color: _validityColor(validity).withValues(alpha: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _validityColor(validity).withValues(alpha: 0.12),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.analytics_rounded, size: 18, color: Colors.white70),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'تحليل الذكاء الاصطناعي',
                    style: TextStyle(
                      fontFamily: 'NotoSansArabic',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _validityColor(validity),
                    ),
                  ),
                ),
                // Validity badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _validityColor(validity),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _validityLabel(validity),
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Duplicate warning
                if (duplicate)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.copy_rounded, color: Colors.red, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '⚠️ صورة مكررة — تم الإبلاغ بنفس الصورة من قبل',
                            style: TextStyle(color: Colors.red, fontSize: 12, fontFamily: 'NotoSansArabic'),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Incident type + severity + confidence row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (incType.isNotEmpty)
                            Text(
                              incType,
                              style: const TextStyle(
                                fontFamily: 'NotoSansArabic',
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _severityColor(severity),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'خطورة: ${_severityLabel(severity)}',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'ثقة: ${confidence.toStringAsFixed(0)}%',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // False report probability gauge
                    if (falsePct > 20)
                      Column(
                        children: [
                          Text(
                            '${falsePct.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: falsePct > 60 ? Colors.red : Colors.orange,
                            ),
                          ),
                          const Text('احتمال مزيف', style: TextStyle(fontSize: 9, color: Colors.grey)),
                        ],
                      ),
                  ],
                ),

                // Detected objects
                if (objects.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'العناصر المكتشفة',
                    style: TextStyle(fontFamily: 'NotoSansArabic', fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: objects.map((obj) {
                      final o = obj as Map;
                      final cat = o['category'] as String? ?? 'object';
                      final label = o['label_ar'] as String? ?? o['label'] as String? ?? '';
                      final conf = ((o['confidence'] as num?)?.toDouble() ?? 0) * 100;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: cat == 'vehicle'
                              ? Colors.blue.withValues(alpha: 0.1)
                              : cat == 'living_being'
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: cat == 'vehicle'
                                ? Colors.blue.withValues(alpha: 0.3)
                                : cat == 'living_being'
                                    ? Colors.green.withValues(alpha: 0.3)
                                    : Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_categoryIcon(cat),
                                size: 12,
                                color: cat == 'vehicle'
                                    ? Colors.blue
                                    : cat == 'living_being'
                                        ? Colors.green
                                        : Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '$label (${conf.toStringAsFixed(0)}%)',
                              style: const TextStyle(fontSize: 11, fontFamily: 'NotoSansArabic'),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],

                // Risks
                if (risks.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'المخاطر المرصودة',
                    style: TextStyle(fontFamily: 'NotoSansArabic', fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  ...risks.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 14),
                        const SizedBox(width: 6),
                        Expanded(child: Text(r.toString(), style: const TextStyle(fontSize: 12, fontFamily: 'NotoSansArabic'))),
                      ],
                    ),
                  )),
                ],

                // Volunteer actions
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'إجراءات المتطوعين',
                    style: TextStyle(fontFamily: 'NotoSansArabic', fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  ...actions.map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      children: [
                        const Icon(Icons.chevron_left_rounded, color: Colors.blue, size: 16),
                        const SizedBox(width: 4),
                        Expanded(child: Text(a.toString(), style: const TextStyle(fontSize: 12, fontFamily: 'NotoSansArabic'))),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzingCard(ThemeData theme, bool isAr) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isAr ? 'جاري تحليل الصورة بالذكاء الاصطناعي...' : 'AI analyzing incident media...',
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'NotoSansArabic',
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard(ThemeData theme, bool isAr) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emergency_share_outlined, color: Colors.orange, size: 18),
              SizedBox(width: 8),
              Text(
                'تعليمات السلامة (لك)',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  fontFamily: 'NotoSansArabic',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _alertDetails!.aiInstructions!,
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'NotoSansArabic',
              color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
