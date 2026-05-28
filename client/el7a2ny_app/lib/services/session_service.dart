import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'sensor_service.dart';

enum UserRole { citizen, volunteer, admin }
enum IncidentRole { reporter, volunteer }

class SessionService extends ChangeNotifier {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  UserRole _currentRole = UserRole.citizen;
  bool _isPlus = false;
  bool _isYearlyPlan = false;
  DateTime? _subscriptionDate;
  final List<String> _activityLog = [];
  String? _activeIncidentId;
  double? _activeIncidentLat;
  double? _activeIncidentLng;
  IncidentRole? _incidentRole;
  String? _userId;
  String? get userId => _userId;


  UserRole get currentRole => _currentRole;
  bool get isAdmin => _currentRole == UserRole.admin;
  bool get isPlus => _isPlus;
  bool get isYearlyPlan => _isYearlyPlan;
  DateTime? get subscriptionDate => _subscriptionDate;
  String? get activeIncidentId => _activeIncidentId;
  double? get activeIncidentLat => _activeIncidentLat;
  double? get activeIncidentLng => _activeIncidentLng;
  IncidentRole? get incidentRole => _incidentRole;

  DateTime? get renewalDate {
    if (_subscriptionDate == null) return null;
    if (_isYearlyPlan) {
      return DateTime(
        _subscriptionDate!.year + 1,
        _subscriptionDate!.month,
        _subscriptionDate!.day,
      );
    } else {
      return DateTime(
        _subscriptionDate!.year,
        _subscriptionDate!.month + 1,
        _subscriptionDate!.day,
      );
    }
  }

  List<String> get activityLog => List.unmodifiable(_activityLog);

  void setRole(UserRole role) {
    _currentRole = role;
    notifyListeners();
  }

  void setUserId(String? id) {
    _userId = id;
    notifyListeners();
  }

  void setPlus(bool value, {bool isYearly = false, DateTime? date}) {
    _isPlus = value;
    _isYearlyPlan = isYearly;
    _subscriptionDate = date ?? (value ? DateTime.now() : null);
    notifyListeners();
  }

  bool? _showVolunteerAlert = false;
  bool get showVolunteerAlert => _showVolunteerAlert ?? false;

  void setActiveIncident(String? id, {double? lat, double? lng, IncidentRole? role}) {
    debugPrint("🔔 SESSION: Setting active incident to $id as $role");
    _activeIncidentId = id;
    _activeIncidentLat = lat;
    _activeIncidentLng = lng;
    _incidentRole = role;

    if (id != null && role == IncidentRole.volunteer) {
      _showVolunteerAlert = true;
      notifyListeners();
      Future.delayed(const Duration(seconds: 5), () {
        _showVolunteerAlert = false;
        notifyListeners();
      });
    } else {
      _showVolunteerAlert = false;
      notifyListeners();
    }
  }

void initFromUser(UserModel user) {
  _userId = user.id; // ← check your UserModel for the exact field name
  _isPlus = user.isPlus;
  _isYearlyPlan = user.planType == 'yearly';
  _subscriptionDate = user.subscriptionDate;
  _currentRole = _roleFromString(user.role);
  SensorMonitorService().startMonitoring();
  notifyListeners();
}

  UserRole _roleFromString(String role) {
    switch (role) {
      case 'admin':
        return UserRole.admin;
      case 'volunteer':
        return UserRole.volunteer;
      default:
        return UserRole.citizen;
    }
  }

  void logAction(String action) {
    final timestamp = DateTime.now().toString().split('.')[0];
    _activityLog.insert(0, '[$timestamp] $action');
    notifyListeners();
  }

  void clearLogs() {
    _activityLog.clear();
    notifyListeners();
  }
}
