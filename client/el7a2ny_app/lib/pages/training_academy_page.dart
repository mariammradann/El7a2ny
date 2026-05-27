import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../models/course_model.dart';
import '../core/localization/app_strings.dart';
import '../core/auth/auth_token_store.dart';
import 'course_detail_page.dart';

class TrainingAcademyPage extends StatefulWidget {
  const TrainingAcademyPage({super.key});

  @override
  State<TrainingAcademyPage> createState() => _TrainingAcademyPageState();
}

class _TrainingAcademyPageState extends State<TrainingAcademyPage> {
  List<CourseModel> _courses = [];
  bool _loading = true;
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() => _loading = true);
    try {
      final userId = AuthTokenStore.userId;
      final data = await ApiService.fetchCourses(userId: userId);
      setState(() {
        _courses = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      debugPrint("Error loading training courses: $e");
    }
  }

  List<CourseModel> get _filteredCourses {
    if (_selectedCategory == 'all') return _courses;
    return _courses.where((c) {
      final cat = c.categoryEn.toLowerCase();
      if (_selectedCategory == 'first_aid') return cat.contains('first aid') || cat.contains('إسعاف');
      if (_selectedCategory == 'firefighting') return cat.contains('fire') || cat.contains('حريق') || cat.contains('حرائق');
      if (_selectedCategory == 'disaster') return cat.contains('disaster') || cat.contains('كارثة') || cat.contains('كوارث');
      return true;
    }).toList();
  }

  int get _completedCount => _courses.where((c) => c.isCompleted).length;

  String get _adminId => SessionService().userId ?? '';

  Future<void> _adminDeleteCourse(CourseModel course) async {
    final isAr = context.loc.isAr;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isAr ? 'حذف الكورس؟' : 'Delete Course?'),
        content: Text(isAr
            ? 'سيتم حذف الكورس "${course.titleAr}" وكل تقدم المتدربين نهائياً.'
            : 'This will permanently delete "${course.titleEn}" and all learner progress.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(isAr ? 'إلغاء' : 'Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isAr ? 'حذف' : 'Delete', style: const TextStyle(color: Color(0xFFE61717))),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ApiService.adminDeleteCourse(course.courseId, _adminId);
        _loadCourses();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isAr ? 'تم حذف الكورس' : 'Course deleted'), backgroundColor: const Color(0xFF10B981)),
        );
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFE61717)),
        );
      }
    }
  }

  Future<void> _showEditCourseDialog(CourseModel course) async {
    final isAr = context.loc.isAr;
    final titleEnCtrl = TextEditingController(text: course.titleEn);
    final titleArCtrl = TextEditingController(text: course.titleAr);
    final priceCtrl = TextEditingController(text: course.price.toStringAsFixed(0));
    final durationCtrl = TextEditingController(text: course.durationMinutes.toString());
    String difficulty = course.difficulty;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(isAr ? 'تعديل الكورس' : 'Edit Course',
              style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'NotoSansArabic')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleEnCtrl,
                    decoration: InputDecoration(labelText: isAr ? 'الاسم (إنجليزي)' : 'Title (English)'),
                    style: const TextStyle(fontFamily: 'NotoSansArabic')),
                const SizedBox(height: 8),
                TextField(controller: titleArCtrl,
                    decoration: InputDecoration(labelText: isAr ? 'الاسم (عربي)' : 'Title (Arabic)'),
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(fontFamily: 'NotoSansArabic')),
                const SizedBox(height: 8),
                TextField(controller: priceCtrl,
                    decoration: InputDecoration(labelText: isAr ? 'السعر (ج.م)' : 'Price (EGP)'),
                    keyboardType: TextInputType.number),
                const SizedBox(height: 8),
                TextField(controller: durationCtrl,
                    decoration: InputDecoration(labelText: isAr ? 'المدة (دقائق)' : 'Duration (minutes)'),
                    keyboardType: TextInputType.number),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: difficulty,
                  decoration: InputDecoration(labelText: isAr ? 'المستوى' : 'Difficulty'),
                  items: [
                    DropdownMenuItem(value: 'beginner', child: Text(isAr ? 'مبتدئ' : 'Beginner')),
                    DropdownMenuItem(value: 'intermediate', child: Text(isAr ? 'متوسط' : 'Intermediate')),
                    DropdownMenuItem(value: 'advanced', child: Text(isAr ? 'متقدم' : 'Advanced')),
                  ],
                  onChanged: (v) => setS(() => difficulty = v ?? difficulty),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isAr ? 'إلغاء' : 'Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await ApiService.adminEditCourse(
                    course.courseId,
                    {
                      'title_en': titleEnCtrl.text.trim(),
                      'title_ar': titleArCtrl.text.trim(),
                      'price': priceCtrl.text.trim(),
                      'duration_minutes': durationCtrl.text.trim(),
                      'difficulty': difficulty,
                    },
                    _adminId,
                  );
                  _loadCourses();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isAr ? 'تم تعديل الكورس' : 'Course updated'), backgroundColor: const Color(0xFF10B981)),
                  );
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFE61717)),
                  );
                }
              },
              child: Text(isAr ? 'حفظ' : 'Save', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddCourseDialog() async {
    final isAr = context.loc.isAr;
    final titleEnCtrl = TextEditingController();
    final titleArCtrl = TextEditingController();
    final descEnCtrl = TextEditingController();
    final descArCtrl = TextEditingController();
    final catEnCtrl = TextEditingController();
    final catArCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '0');
    final durationCtrl = TextEditingController(text: '60');
    String difficulty = 'beginner';
    bool isIrl = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(isAr ? 'إضافة كورس جديد' : 'Add New Course',
              style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'NotoSansArabic')),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleEnCtrl, decoration: InputDecoration(labelText: isAr ? 'الاسم (إنجليزي)*' : 'Title (EN)*')),
                  const SizedBox(height: 8),
                  TextField(controller: titleArCtrl, decoration: InputDecoration(labelText: isAr ? 'الاسم (عربي)*' : 'Title (AR)*'), textDirection: TextDirection.rtl),
                  const SizedBox(height: 8),
                  TextField(controller: descEnCtrl, decoration: InputDecoration(labelText: isAr ? 'الوصف (إنجليزي)*' : 'Description (EN)*'), maxLines: 2),
                  const SizedBox(height: 8),
                  TextField(controller: descArCtrl, decoration: InputDecoration(labelText: isAr ? 'الوصف (عربي)*' : 'Description (AR)*'), textDirection: TextDirection.rtl, maxLines: 2),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: TextField(controller: catEnCtrl, decoration: InputDecoration(labelText: isAr ? 'الفئة (EN)*' : 'Category (EN)*'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: catArCtrl, decoration: InputDecoration(labelText: isAr ? 'الفئة (AR)*' : 'Category (AR)*'), textDirection: TextDirection.rtl)),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: TextField(controller: priceCtrl, decoration: InputDecoration(labelText: isAr ? 'السعر (ج.م)' : 'Price (EGP)'), keyboardType: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: durationCtrl, decoration: InputDecoration(labelText: isAr ? 'المدة (دقائق)' : 'Duration (min)'), keyboardType: TextInputType.number)),
                  ]),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: difficulty,
                    decoration: InputDecoration(labelText: isAr ? 'المستوى' : 'Difficulty'),
                    items: [
                      DropdownMenuItem(value: 'beginner', child: Text(isAr ? 'مبتدئ' : 'Beginner')),
                      DropdownMenuItem(value: 'intermediate', child: Text(isAr ? 'متوسط' : 'Intermediate')),
                      DropdownMenuItem(value: 'advanced', child: Text(isAr ? 'متقدم' : 'Advanced')),
                    ],
                    onChanged: (v) => setS(() => difficulty = v ?? difficulty),
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Checkbox(value: isIrl, onChanged: (v) => setS(() => isIrl = v ?? false)),
                    Text(isAr ? 'كورس حضوري' : 'In-Person (IRL)', style: const TextStyle(fontFamily: 'NotoSansArabic')),
                  ]),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isAr ? 'إلغاء' : 'Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
              onPressed: () async {
                if (titleEnCtrl.text.trim().isEmpty || titleArCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isAr ? 'الاسم مطلوب' : 'Title is required'), backgroundColor: const Color(0xFFE61717)),
                  );
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await ApiService.adminCreateCourse({
                    'title_en': titleEnCtrl.text.trim(),
                    'title_ar': titleArCtrl.text.trim(),
                    'description_en': descEnCtrl.text.trim().isNotEmpty ? descEnCtrl.text.trim() : titleEnCtrl.text.trim(),
                    'description_ar': descArCtrl.text.trim().isNotEmpty ? descArCtrl.text.trim() : titleArCtrl.text.trim(),
                    'category_en': catEnCtrl.text.trim().isNotEmpty ? catEnCtrl.text.trim() : 'General',
                    'category_ar': catArCtrl.text.trim().isNotEmpty ? catArCtrl.text.trim() : 'عام',
                    'difficulty': difficulty,
                    'duration_minutes': durationCtrl.text.trim(),
                    'price': priceCtrl.text.trim(),
                    'is_irl': isIrl,
                  }, _adminId);
                  _loadCourses();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isAr ? 'تمت إضافة الكورس بنجاح' : 'Course created successfully!'), backgroundColor: const Color(0xFF10B981)),
                  );
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFE61717)),
                  );
                }
              },
              child: Text(isAr ? 'إضافة' : 'Add', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final theme = Theme.of(context);
    final isAr = loc.isAr;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          loc.trainingAcademy,
          style: const TextStyle(fontWeight: FontWeight.w900, fontFamily: 'NotoSansArabic'),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadCourses,
          ),
          if (SessionService().isAdmin)
            IconButton(
              icon: const Icon(Icons.add_circle_rounded),
              color: Theme.of(context).primaryColor,
              tooltip: context.loc.isAr ? 'إضافة كورس' : 'Add Course',
              onPressed: _showAddCourseDialog,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Header Progress Card ---
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: theme.brightness == Brightness.dark
                            ? [const Color(0xFF1E1B4B), const Color(0xFF311042)]
                            : [const Color(0xFF4F46E5), const Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: theme.brightness == Brightness.dark
                              ? Colors.black.withValues(alpha: 0.3)
                              : const Color(0xFF4F46E5).withValues(alpha: 0.25),
                          blurRadius: 16,
                          spreadRadius: 2,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              loc.readinessLevel,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.8),
                                fontWeight: FontWeight.bold,
                                fontFamily: 'NotoSansArabic',
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _completedCount == _courses.length && _courses.isNotEmpty
                                    ? loc.expertReady
                                    : loc.activeVolunteerStatus,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'NotoSansArabic',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          loc.learnToSaveLives,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            fontFamily: 'NotoSansArabic',
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: _courses.isEmpty ? 0.0 : _completedCount / _courses.length,
                                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                                  color: const Color(0xFF10B981),
                                  minHeight: 8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              '$_completedCount/${_courses.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          loc.completeTrainingBadges,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.75),
                            fontFamily: 'NotoSansArabic',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- Description Card ---
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.primaryColor.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.volunteer_activism_rounded,
                                color: theme.primaryColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              loc.trainingPageTitle,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: theme.colorScheme.onSurface,
                                fontFamily: 'NotoSansArabic',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          loc.trainingPageDesc,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.7,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                            fontFamily: 'NotoSansArabic',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Category Filters ---
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _CategoryFilterChip(
                          label: loc.allLabel,
                          isSelected: _selectedCategory == 'all',
                          onTap: () => setState(() => _selectedCategory = 'all'),
                        ),
                        _CategoryFilterChip(
                          label: isAr ? 'إسعافات أولية' : 'First Aid',
                          isSelected: _selectedCategory == 'first_aid',
                          onTap: () => setState(() => _selectedCategory = 'first_aid'),
                        ),
                        _CategoryFilterChip(
                          label: isAr ? 'مكافحة الحرائق' : 'Firefighting',
                          isSelected: _selectedCategory == 'firefighting',
                          onTap: () => setState(() => _selectedCategory = 'firefighting'),
                        ),
                        _CategoryFilterChip(
                          label: isAr ? 'مواجهة الكوارث' : 'Disaster',
                          isSelected: _selectedCategory == 'disaster',
                          onTap: () => setState(() => _selectedCategory = 'disaster'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- Courses List ---
                  if (_filteredCourses.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          loc.noCoursesAvailable,
                          style: const TextStyle(color: Colors.grey, fontFamily: 'NotoSansArabic'),
                        ),
                      ),
                    )
                  else
                    ..._filteredCourses.map((course) => _CourseListItemCard(
                          course: course,
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CourseDetailPage(course: course),
                              ),
                            );
                            _loadCourses();
                          },
                          isAdmin: SessionService().isAdmin,
                          onAdminDelete: () => _adminDeleteCourse(course),
                          onAdminEdit: () => _showEditCourseDialog(course),
                        )),
                ],
              ),
            ),
    );
  }
}

class _CategoryFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = theme.brightness == Brightness.dark
        ? theme.colorScheme.primaryContainer
        : theme.primaryColor;
    final onSelectedColor = theme.brightness == Brightness.dark
        ? theme.colorScheme.onPrimaryContainer
        : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: isSelected ? selectedColor : theme.cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected
                ? Colors.transparent
                : theme.dividerColor.withValues(alpha: 0.1),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? onSelectedColor : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  fontFamily: 'NotoSansArabic',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CourseListItemCard extends StatelessWidget {
  final CourseModel course;
  final VoidCallback onTap;
  final bool isAdmin;
  final VoidCallback? onAdminDelete;
  final VoidCallback? onAdminEdit;

  const _CourseListItemCard({
    required this.course,
    required this.onTap,
    this.isAdmin = false,
    this.onAdminDelete,
    this.onAdminEdit,
  });

  Color _getDifficultyColor(String diff) {
    switch (diff.toLowerCase()) {
      case 'beginner':
        return const Color(0xFF10B981);
      case 'intermediate':
        return const Color(0xFFF59E0B);
      case 'advanced':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = context.loc;
    final isAr = loc.isAr;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(course.difficulty).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            course.difficulty.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: _getDifficultyColor(course.difficulty),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        if (course.isIrl) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              loc.irlClass.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: theme.primaryColor,
                                letterSpacing: 0.5,
                                fontFamily: 'NotoSansArabic',
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (course.isCompleted)
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            loc.completed,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.bold,
                              fontFamily: 'NotoSansArabic',
                            ),
                          ),
                        ],
                      )
                    else if (course.isEnrolled)
                      Row(
                        children: [
                          Icon(Icons.play_circle_fill_rounded, color: theme.primaryColor, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            loc.enrolledStatus,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'NotoSansArabic',
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        '${course.price.toStringAsFixed(0)} ${isAr ? 'ج.م' : 'EGP'}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: theme.primaryColor,
                          fontFamily: 'NotoSansArabic',
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  course.title(isAr),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'NotoSansArabic',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  course.description(isAr),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontFamily: 'NotoSansArabic',
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.menu_book_rounded, color: Colors.grey, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          isAr 
                              ? '${course.lessons.length} دروس' 
                              : '${course.lessons.length} Lessons',
                          style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'NotoSansArabic'),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.access_time_rounded, color: Colors.grey, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          isAr
                              ? '${course.durationMinutes} دقيقة'
                              : '${course.durationMinutes} mins',
                          style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'NotoSansArabic'),
                        ),
                      ],
                    ),
                    Icon(
                      isAr ? Icons.arrow_back_ios_rounded : Icons.arrow_forward_ios_rounded,
                      color: Colors.grey,
                      size: 14,
                    ),
                  ],
                ),
                // ── Admin Actions ───────────────────────────────────────────
                if (isAdmin) ...[ 
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: onAdminEdit,
                        icon: const Icon(Icons.edit_rounded, size: 16, color: Color(0xFF3B82F6)),
                        label: Text(
                          isAr ? 'تعديل' : 'Edit',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF3B82F6), fontFamily: 'NotoSansArabic'),
                        ),
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                      ),
                      const SizedBox(width: 4),
                      TextButton.icon(
                        onPressed: onAdminDelete,
                        icon: const Icon(Icons.delete_rounded, size: 16, color: Color(0xFFE61717)),
                        label: Text(
                          isAr ? 'حذف' : 'Delete',
                          style: const TextStyle(fontSize: 12, color: Color(0xFFE61717), fontFamily: 'NotoSansArabic'),
                        ),
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
