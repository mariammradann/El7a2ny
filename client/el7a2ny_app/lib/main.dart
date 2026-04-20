import 'package:flutter/material.dart';
import 'package:el7a2ny_app/core/localization/locale_provider.dart';
import 'package:el7a2ny_app/core/theme/app_theme.dart';
import 'package:el7a2ny_app/pages/welcome_screen.dart';
import 'package:el7a2ny_app/widgets/global_fab_overlay.dart';

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
              return GlobalFabOverlay(
                child: Directionality(
                  textDirection: config.isArabic ? TextDirection.rtl : TextDirection.ltr,
                  child: child!,
                ),
              );
            },
            navigatorObservers: [GlobalFabRouteObserver()],
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
