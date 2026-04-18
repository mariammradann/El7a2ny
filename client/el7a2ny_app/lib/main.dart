import 'package:flutter/material.dart';
import 'core/localization/locale_provider.dart';
import 'core/theme/app_theme.dart';
import 'pages/welcome_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppConfigNotifier _configNotifier;

  @override
  void initState() {
    super.initState();
    _configNotifier = AppConfigNotifier();
  }

  @override
  void dispose() {
    _configNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppConfigProvider(
      notifier: _configNotifier,
      child: Builder(
        builder: (ctx) {
          final config = AppConfigProvider.of(ctx);
          return MaterialApp(
            title: 'El7a2ny App',
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              return Directionality(
                textDirection: config.isArabic ? TextDirection.rtl : TextDirection.ltr,
                child: child!,
              );
            },
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: config.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const WelcomeScreen(),
          );
        },
      ),
    );
  }
}
