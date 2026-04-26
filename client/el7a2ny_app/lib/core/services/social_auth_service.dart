import 'dart:async';

class SocialProfile {
  final String provider; // Google, Facebook, X, Instagram
  final String firstName;
  final String lastName;
  final String email;

  SocialProfile({
    required this.provider,
    required this.firstName,
    required this.lastName,
    required this.email,
  });
}

class SocialAuthService {
  /// يحاكي عملية تسجيل الدخول عبر شبكات التواصل الاجتماعي.
  /// سيتم استبدال هذه الدالة بالـ SDKs الحقيقية لاحقاً.
  static Future<SocialProfile> mockLogin(String provider) async {
    // محاكاة وقت التحميل والاتصال بالسيرفر (ثانية ونصف)
    await Future.delayed(const Duration(milliseconds: 1500));

    // إرجاع بيانات وهمية تعتمد على المزود لمساعدة الـ UI
    switch (provider.toLowerCase()) {
      case 'google':
        return SocialProfile(
          provider: 'Google',
          firstName: 'أحمد',
          lastName: 'محمد',
          email: 'ahmed.m.google@example.com',
        );
      case 'facebook':
        return SocialProfile(
          provider: 'Facebook',
          firstName: 'عمر',
          lastName: 'فاروق',
          email: 'omar.fb@example.com',
        );
      case 'x':
        return SocialProfile(
          provider: 'X',
          firstName: 'سارة',
          lastName: 'خالد',
          email: 'sara.x@example.com',
        );
      case 'instagram':
        return SocialProfile(
          provider: 'Instagram',
          firstName: 'منى',
          lastName: 'زكي',
          email: 'mona.insta@example.com',
        );
      default:
        return SocialProfile(
          provider: provider,
          firstName: 'مستخدم',
          lastName: 'جديد',
          email: 'user@example.com',
        );
    }
  }
}
