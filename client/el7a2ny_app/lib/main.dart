import 'package:el7a2ny_app/core/auth/auth_token_store.dart';
import 'package:flutter/material.dart';
import 'package:el7a2ny_app/core/localization/locale_provider.dart';
import 'package:el7a2ny_app/core/theme/app_theme.dart';
import 'package:el7a2ny_app/pages/welcome_screen.dart';
import 'package:el7a2ny_app/pages/landing_screen.dart';
import 'package:el7a2ny_app/pages/login_screen.dart';
import 'package:el7a2ny_app/pages/sign_up_screen.dart';
import 'package:el7a2ny_app/pages/emergency_report_screen.dart';
import 'package:el7a2ny_app/widgets/global_fab_overlay.dart';
import 'package:el7a2ny_app/services/session_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthTokenStore.init();
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
            navigatorKey: GlobalFabController.navigatorKey,
            navigatorObservers: [GlobalFabRouteObserver()],
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: config.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            builder: (context, child) {
              return ListenableBuilder(
                listenable: SessionService(),
                builder: (context, _) {
                  final isPlus = SessionService().isPlus;
                  return Theme(
                    data: isPlus ? AppTheme.premiumTheme : Theme.of(context),
                    child: GlobalFabOverlay(
                      child: Directionality(
                        textDirection: config.isArabic ? TextDirection.rtl : TextDirection.ltr,
                        child: child!,
                      ),
                    ),
                  );
                },
              );
            },
            home: const WelcomeScreen(),
            routes: {
              '/landing': (context) => const LandingScreen(),
              '/login': (context) => const LoginScreen(),
              '/signup': (context) => SignUpScreen(),
              '/emergency-report': (context) => const EmergencyReportScreen(),
            },
          );
        },
      ),
    );
  }
}
