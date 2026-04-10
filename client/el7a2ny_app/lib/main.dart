import 'package:flutter/material.dart';
// تأكدي إن اسم الملف هنا مطابق لاسم الملف اللي عملتي فيه صفحة الترحيب
import 'pages/welcome_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emergency App',
      debugShowCheckedModeBanner: false, // عشان نشيل العلامة الحمراء اللي فوق
      theme: ThemeData(
        // تم تصحيح الخطأ هنا بإضافة ColorScheme
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFEB1010)),
        useMaterial3: true,
        fontFamily: 'NotoSansArabic',
      ),
      // هنا خلينا التطبيق يبدأ بصفحة الترحيب اللي عملناها
      home: const WelcomeScreen(),
    );
  }
}
