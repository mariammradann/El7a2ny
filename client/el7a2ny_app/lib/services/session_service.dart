import 'package:flutter/foundation.dart';

enum UserRole { citizen, volunteer, admin }

class SessionService extends ChangeNotifier {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  UserRole _currentRole = UserRole.citizen;
  final List<String> _activityLog = [];

  UserRole get currentRole => _currentRole;
  bool get isAdmin => _currentRole == UserRole.admin;
  List<String> get activityLog => List.unmodifiable(_activityLog);

  void setRole(UserRole role) {
    _currentRole = role;
    notifyListeners();
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
