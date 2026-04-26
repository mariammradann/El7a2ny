import 'package:flutter/material.dart';

class AppConfigNotifier extends ChangeNotifier {
  bool isArabic = true;
  bool isDarkMode = false;

  void toggleLanguage() {
    isAr = !isAr;
    notifyListeners();
  }

  // Backwards compatibility for the rename
  bool get isAr => isArabic;
  set isAr(bool value) => isArabic = value;

  void toggleTheme() {
    isDarkMode = !isDarkMode;
    notifyListeners();
  }
}

class AppConfigProvider extends InheritedNotifier<AppConfigNotifier> {
  const AppConfigProvider({
    super.key,
    required AppConfigNotifier super.notifier,
    required super.child,
  });

  static AppConfigNotifier of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppConfigProvider>()!.notifier!;
  }
}

// For backwards compatibility during transition
typedef LocaleNotifier = AppConfigNotifier;
typedef LocaleProvider = AppConfigProvider;
