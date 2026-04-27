import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

enum UserRole { citizen, volunteer, admin }

class SessionService extends ChangeNotifier {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  UserRole _currentRole = UserRole.citizen;
  bool _isPlus = false;
  bool _isYearlyPlan = false;
  DateTime? _subscriptionDate;
  final List<String> _activityLog = [];

  UserRole get currentRole => _currentRole;
  bool get isAdmin => _currentRole == UserRole.admin;
  bool get isPlus => _isPlus;
  bool get isYearlyPlan => _isYearlyPlan;
  DateTime? get subscriptionDate => _subscriptionDate;

  DateTime? get renewalDate {
    if (_subscriptionDate == null) return null;
    if (_isYearlyPlan) {
      return DateTime(_subscriptionDate!.year + 1, _subscriptionDate!.month, _subscriptionDate!.day);
    } else {
      return DateTime(_subscriptionDate!.year, _subscriptionDate!.month + 1, _subscriptionDate!.day);
    }
  }

  List<String> get activityLog => List.unmodifiable(_activityLog);

  void setRole(UserRole role) {
    _currentRole = role;
    notifyListeners();
  }

  void setPlus(bool value, {bool isYearly = false, DateTime? date}) {
    _isPlus = value;
    _isYearlyPlan = isYearly;
    _subscriptionDate = date ?? (value ? DateTime.now() : null);
    notifyListeners();
  }

  void initFromUser(UserModel user) {
    _isPlus = user.isPlus;
    _isYearlyPlan = user.planType == 'yearly';
    _subscriptionDate = user.subscriptionDate;
    _currentRole = _roleFromString(user.role);
    notifyListeners();
  }

  UserRole _roleFromString(String role) {
    switch (role) {
      case 'admin': return UserRole.admin;
      case 'volunteer': return UserRole.volunteer;
      default: return UserRole.citizen;
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
