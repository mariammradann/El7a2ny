import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/course_model.dart';
import '../models/user_model.dart';
import '../core/localization/app_strings.dart';
import '../core/auth/auth_token_store.dart';
import 'lesson_detail_page.dart';
import 'course_quiz_page.dart';
import 'premium_subscription_page.dart';
import 'payment_page.dart';

class CourseDetailPage extends StatefulWidget {
  final CourseModel course;
  const CourseDetailPage({super.key, required this.course});

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  late CourseModel _course;
  bool _loading = false;
  bool _enrolling = false;
  UserModel? _user;
  bool _loadingUser = true;

  @override
  void initState() {
    super.initState();
    _course = widget.course;
    _refreshCourse();
  }

  Future<void> _refreshCourse() async {
    setState(() {
      _loading = true;
      _loadingUser = true;
    });
    try {
      final userId = AuthTokenStore.userId;

      // Fetch courses (always), and user profile only if logged in
      final courses = await ApiService.fetchCourses(userId: userId);
      UserModel? fetchedUser;
      if (userId != null) {
        try {
          fetchedUser = await ApiService.fetchUserProfile();
        } catch (e) {
          debugPrint("Could not load user profile (may not be logged in): $e");
        }
      }

      final updated = courses.firstWhere(
        (c) => c.courseId == _course.courseId,
        orElse: () => _course,
      );
      setState(() {
        _course = updated;
        _user = fetchedUser;
        _loading = false;
        _loadingUser = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _loadingUser = false;
      });
      debugPrint("Error refreshing course: $e");
    }
  }

  Future<void> _enroll() async {
    setState(() => _enrolling = true);
    try {
      final userId = AuthTokenStore.userId;
      if (userId == null) return;
      final success = await ApiService.enrollInCourse(_course.courseId, userId);
      if (success) {
        await _refreshCourse();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.loc.enrolledSuccess,
                style: const TextStyle(fontFamily: 'NotoSansArabic'),
              ),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error enrolling in course: $e");
    } finally {
      setState(() => _enrolling = false);
    }
  }

  IconData _getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('first aid') || cat.contains('إسعاف')) return Icons.medical_services_rounded;
    if (cat.contains('fire') || cat.contains('حريق')) return Icons.local_fire_department_rounded;
    if (cat.contains('disaster') || cat.contains('كوارث')) return Icons.gavel_rounded;
    return Icons.school_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = context.loc;
    final isAr = loc.isAr;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _course.title(isAr),
          style: const TextStyle(fontWeight: FontWeight.w900, fontFamily: 'NotoSansArabic', fontSize: 16),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- Hero Category Card ---
                      Container(
                        height: 160,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: theme.brightness == Brightness.dark
                                ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                                : [theme.primaryColor.withValues(alpha: 0.08), theme.primaryColor.withValues(alpha: 0.15)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: theme.primaryColor.withValues(alpha: 0.1)),
                        ),
                        child: Center(
                          child: Icon(
                            _getCategoryIcon(_course.categoryEn),
                            size: 72,
                            color: theme.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // --- Metadata Chips ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _DetailMetaChip(
                            icon: Icons.access_time_rounded,
                            label: isAr ? '${_course.durationMinutes} دقيقة' : '${_course.durationMinutes} mins',
                          ),
                          _DetailMetaChip(
                            icon: Icons.menu_book_rounded,
                            label: isAr ? '${_course.lessons.length} دروس' : '${_course.lessons.length} lessons',
                          ),
                          _DetailMetaChip(
                            icon: Icons.workspace_premium_rounded,
                            label: _course.difficulty.toUpperCase(),
                            color: theme.primaryColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // --- Location & Schedule Box ---
                      if (_course.isIrl) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.primaryColor.withValues(alpha: 0.1)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.location_on_rounded, color: theme.primaryColor, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontFamily: 'NotoSansArabic',
                                          color: theme.colorScheme.onSurface,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: loc.locationLabelField,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          TextSpan(text: _course.locationInfo(isAr)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded, color: theme.primaryColor, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontFamily: 'NotoSansArabic',
                                          color: theme.colorScheme.onSurface,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: loc.scheduleLabelField,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          TextSpan(text: _course.scheduleInfo(isAr)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // --- Pricing Section ---
                      _buildPricingCard(context),
                      const SizedBox(height: 24),

                      // --- Description ---
                      Text(
                        loc.aboutCourse,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'NotoSansArabic',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _course.description(isAr),
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          fontFamily: 'NotoSansArabic',
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // --- Curriculum list ---
                      Text(
                        loc.courseCurriculum,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'NotoSansArabic',
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _course.lessons.length,
                        itemBuilder: (context, idx) {
                          final lesson = _course.lessons[idx];
                          return _LessonCurriculumTile(
                            lesson: lesson,
                            isLocked: !_course.isEnrolled,
                            index: idx + 1,
                            onTap: () async {
                              if (!_course.isEnrolled) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      loc.enrollRequiredMsg,
                                      style: const TextStyle(fontFamily: 'NotoSansArabic'),
                                    ),
                                  ),
                                );
                                return;
                              }
                              await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => LessonDetailPage(
                                      lesson: lesson,
                                      course: _course,
                                      allLessons: _course.lessons,
                                      currentLessonIndex: idx,
                                    ),
                                  ),
                              );
                              _refreshCourse();
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // --- Sticky Bottom Button ---
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      border: Border(
                        top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.08)),
                      ),
                    ),
                    child: _enrolling
                        ? const Center(child: CircularProgressIndicator())
                        : _buildActionButton(context),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    final theme = Theme.of(context);
    final loc = context.loc;
    final isAr = loc.isAr;

    if (_loadingUser) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primaryColor.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: null,
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
      );
    }

    final double originalPrice = _course.price;
    final bool isPlusUser = _user?.isPlus ?? false;
    final double finalPrice = isPlusUser ? originalPrice * 0.5 : originalPrice;

    if (!_course.isEnrolled) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
        ),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PaymentPage(
                amount: finalPrice,
                courseId: _course.courseId,
                courseTitle: _course.title(isAr),
              ),
            ),
          ).then((_) => _refreshCourse());
        },
        child: Text(
          loc.enrollAndPay(finalPrice),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'NotoSansArabic'),
        ),
      );
    }

    if (_course.isCompleted) {
      return ElevatedButton.icon(
        icon: const Icon(Icons.workspace_premium_rounded, color: Colors.amber),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
        ),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CourseQuizPage(course: _course),
            ),
          );
        },
        label: Text(
          loc.coursePassed,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'NotoSansArabic'),
        ),
      );
    }

    return ElevatedButton.icon(
      icon: const Icon(Icons.play_arrow_rounded),
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
      ),
      onPressed: () {
        // Go straight to the first lesson
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LessonDetailPage(
              lesson: _course.lessons.first,
              course: _course,
              allLessons: _course.lessons,
              currentLessonIndex: 0,
            ),
          ),
        );
      },
      label: Text(
        loc.startCourseStudy,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'NotoSansArabic'),
      ),
    );
  }

  Widget _buildPricingCard(BuildContext context) {
    final theme = Theme.of(context);
    final loc = context.loc;
    final isAr = loc.isAr;

    if (_loadingUser) {
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_course.isEnrolled) {
      return const SizedBox.shrink();
    }

    final double originalPriceVal = _course.price;
    final bool isPlusUser = _user?.isPlus ?? false;
    final double finalPriceVal = isPlusUser ? originalPriceVal * 0.5 : originalPriceVal;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPlusUser 
              ? Colors.amber.withValues(alpha: 0.3) 
              : theme.dividerColor.withValues(alpha: 0.08),
          width: isPlusUser ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isAr ? 'رسوم التسجيل' : 'Registration Fees',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'NotoSansArabic',
                ),
              ),
              if (_course.isIrl)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    loc.irlClass,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'NotoSansArabic',
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              if (isPlusUser) ...[
                Text(
                  '${originalPriceVal.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey,
                    decoration: TextDecoration.lineThrough,
                    fontFamily: 'NotoSansArabic',
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${finalPriceVal.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF10B981),
                    fontFamily: 'NotoSansArabic',
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  isAr ? 'ج.م' : 'EGP',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.bold,
                    fontFamily: 'NotoSansArabic',
                  ),
                ),
              ] else ...[
                Text(
                  '${originalPriceVal.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                    fontFamily: 'NotoSansArabic',
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  isAr ? 'ج.م' : 'EGP',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.bold,
                    fontFamily: 'NotoSansArabic',
                  ),
                ),
              ],
            ],
          ),
          if (isPlusUser) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.stars_rounded, color: Colors.amber, size: 18),
                const SizedBox(width: 6),
                Text(
                  loc.plusDiscountApplied,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'NotoSansArabic',
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.secondary.withValues(alpha: 0.08),
                    theme.colorScheme.secondaryContainer.withValues(alpha: 0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.upgradePromo,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                            fontFamily: 'NotoSansArabic',
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const PremiumSubscriptionPage(),
                              ),
                            ).then((_) => _refreshCourse());
                          },
                          child: Text(
                            isAr ? 'اشترك الآن ⚡' : 'Subscribe Now ⚡',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'NotoSansArabic',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showCheckoutSheet(BuildContext context, double price) {
    final theme = Theme.of(context);
    final loc = context.loc;
    final isAr = loc.isAr;
    String selectedMethod = 'card';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    loc.checkoutTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'NotoSansArabic',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _course.title(isAr),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'NotoSansArabic'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${price.toStringAsFixed(0)} ${isAr ? 'ج.م' : 'EGP'}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: theme.primaryColor,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 14),
                  Text(
                    loc.paymentMethod,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'NotoSansArabic', fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  _buildPaymentMethodOption(
                    title: loc.creditCard,
                    icon: Icons.credit_card_rounded,
                    isSelected: selectedMethod == 'card',
                    onTap: () => setModalState(() => selectedMethod = 'card'),
                    theme: theme,
                  ),
                  _buildPaymentMethodOption(
                    title: loc.wallet,
                    icon: Icons.account_balance_wallet_rounded,
                    isSelected: selectedMethod == 'wallet',
                    onTap: () => setModalState(() => selectedMethod = 'wallet'),
                    theme: theme,
                  ),
                  _buildPaymentMethodOption(
                    title: loc.fawry,
                    icon: Icons.flash_on_rounded,
                    isSelected: selectedMethod == 'fawry',
                    onTap: () => setModalState(() => selectedMethod = 'fawry'),
                    theme: theme,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _enroll();
                    },
                    child: Text(
                      loc.confirmPayment,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'NotoSansArabic'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentMethodOption({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected 
            ? theme.primaryColor.withValues(alpha: 0.08) 
            : theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? theme.primaryColor : theme.dividerColor.withValues(alpha: 0.08),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Icon(icon, color: isSelected ? theme.primaryColor : Colors.grey),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontFamily: 'NotoSansArabic',
          ),
        ),
        trailing: isSelected 
            ? Icon(Icons.check_circle_rounded, color: theme.primaryColor) 
            : null,
      ),
    );
  }
}

class _DetailMetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _DetailMetaChip({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedColor = color ?? theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: resolvedColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: resolvedColor,
              fontFamily: 'NotoSansArabic',
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonCurriculumTile extends StatelessWidget {
  final LessonModel lesson;
  final bool isLocked;
  final int index;
  final VoidCallback onTap;

  const _LessonCurriculumTile({
    required this.lesson,
    required this.isLocked,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAr = context.loc.isAr;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLocked 
              ? theme.dividerColor.withValues(alpha: 0.04) 
              : theme.primaryColor.withValues(alpha: 0.08),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isLocked 
                ? theme.dividerColor.withValues(alpha: 0.05) 
                : theme.primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$index',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isLocked ? Colors.grey : theme.primaryColor,
              ),
            ),
          ),
        ),
        title: Text(
          lesson.title(isAr),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isLocked ? theme.colorScheme.onSurface.withValues(alpha: 0.5) : theme.colorScheme.onSurface,
            fontFamily: 'NotoSansArabic',
          ),
        ),
        subtitle: Text(
          isAr ? '${lesson.readingTimeMinutes} دقائق قراءة' : '${lesson.readingTimeMinutes} mins read',
          style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'NotoSansArabic'),
        ),
        trailing: Icon(
          isLocked ? Icons.lock_outline_rounded : Icons.arrow_forward_ios_rounded,
          color: isLocked ? Colors.grey : theme.primaryColor.withValues(alpha: 0.7),
          size: 16,
        ),
      ),
    );
  }
}
