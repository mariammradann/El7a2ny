class CourseModel {
  final String courseId;
  final String titleEn;
  final String titleAr;
  final String descriptionEn;
  final String descriptionAr;
  final String categoryEn;
  final String categoryAr;
  final String difficulty;
  final int durationMinutes;
  final String badgeNameEn;
  final String badgeNameAr;
  final DateTime createdAt;
  final List<LessonModel> lessons;
  final List<QuizQuestionModel> quizQuestions;
  final bool isEnrolled;
  final bool isCompleted;
  final DateTime? completedAt;
  final double price;
  final bool isIrl;
  final String locationInfoEn;
  final String locationInfoAr;
  final String scheduleInfoEn;
  final String scheduleInfoAr;

  CourseModel({
    required this.courseId,
    required this.titleEn,
    required this.titleAr,
    required this.descriptionEn,
    required this.descriptionAr,
    required this.categoryEn,
    required this.categoryAr,
    required this.difficulty,
    required this.durationMinutes,
    required this.badgeNameEn,
    required this.badgeNameAr,
    required this.createdAt,
    required this.lessons,
    required this.quizQuestions,
    required this.isEnrolled,
    required this.isCompleted,
    this.completedAt,
    required this.price,
    required this.isIrl,
    required this.locationInfoEn,
    required this.locationInfoAr,
    required this.scheduleInfoEn,
    required this.scheduleInfoAr,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    var lessonsList = json['lessons'] as List? ?? [];
    List<LessonModel> parsedLessons = lessonsList.map((l) => LessonModel.fromJson(l)).toList();

    var quizList = json['quiz_questions'] as List? ?? [];
    List<QuizQuestionModel> parsedQuiz = quizList.map((q) => QuizQuestionModel.fromJson(q)).toList();

    // Handle price dynamic types (int/double/string)
    double parsedPrice = 0.0;
    if (json['price'] != null) {
      parsedPrice = double.tryParse(json['price'].toString()) ?? 0.0;
    }

    return CourseModel(
      courseId: json['course_id'] ?? '',
      titleEn: json['title_en'] ?? '',
      titleAr: json['title_ar'] ?? '',
      descriptionEn: json['description_en'] ?? '',
      descriptionAr: json['description_ar'] ?? '',
      categoryEn: json['category_en'] ?? '',
      categoryAr: json['category_ar'] ?? '',
      difficulty: json['difficulty'] ?? 'beginner',
      durationMinutes: json['duration_minutes'] ?? 0,
      badgeNameEn: json['badge_name_en'] ?? '',
      badgeNameAr: json['badge_name_ar'] ?? '',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      lessons: parsedLessons,
      quizQuestions: parsedQuiz,
      isEnrolled: json['is_enrolled'] ?? false,
      isCompleted: json['is_completed'] ?? false,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      price: parsedPrice,
      isIrl: json['is_irl'] ?? true,
      locationInfoEn: json['location_info_en'] ?? '',
      locationInfoAr: json['location_info_ar'] ?? '',
      scheduleInfoEn: json['schedule_info_en'] ?? '',
      scheduleInfoAr: json['schedule_info_ar'] ?? '',
    );
  }

  String title(bool isAr) => isAr ? titleAr : titleEn;
  String description(bool isAr) => isAr ? descriptionAr : descriptionEn;
  String category(bool isAr) => isAr ? categoryAr : categoryEn;
  String badgeName(bool isAr) => isAr ? badgeNameAr : badgeNameEn;
  String locationInfo(bool isAr) => isAr ? locationInfoAr : locationInfoEn;
  String scheduleInfo(bool isAr) => isAr ? scheduleInfoAr : scheduleInfoEn;
}

class LessonModel {
  final String lessonId;
  final int orderIndex;
  final String titleEn;
  final String titleAr;
  final String contentEn;
  final String contentAr;
  final int readingTimeMinutes;

  LessonModel({
    required this.lessonId,
    required this.orderIndex,
    required this.titleEn,
    required this.titleAr,
    required this.contentEn,
    required this.contentAr,
    required this.readingTimeMinutes,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      lessonId: json['lesson_id'] ?? '',
      orderIndex: json['order_index'] ?? 0,
      titleEn: json['title_en'] ?? '',
      titleAr: json['title_ar'] ?? '',
      contentEn: json['content_en'] ?? '',
      contentAr: json['content_ar'] ?? '',
      readingTimeMinutes: json['reading_time_minutes'] ?? 0,
    );
  }

  String title(bool isAr) => isAr ? titleAr : titleEn;
  String content(bool isAr) => isAr ? contentAr : contentEn;
}

class QuizQuestionModel {
  final String questionId;
  final String questionTextEn;
  final String questionTextAr;
  final List<String> optionsEn;
  final List<String> optionsAr;
  final int correctOptionIndex;

  QuizQuestionModel({
    required this.questionId,
    required this.questionTextEn,
    required this.questionTextAr,
    required this.optionsEn,
    required this.optionsAr,
    required this.correctOptionIndex,
  });

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) {
    return QuizQuestionModel(
      questionId: json['question_id'] ?? '',
      questionTextEn: json['question_text_en'] ?? '',
      questionTextAr: json['question_text_ar'] ?? '',
      optionsEn: List<String>.from(json['options_en'] ?? []),
      optionsAr: List<String>.from(json['options_ar'] ?? []),
      correctOptionIndex: json['correct_option_index'] ?? 0,
    );
  }

  String questionText(bool isAr) => isAr ? questionTextAr : questionTextEn;
  List<String> options(bool isAr) => isAr ? optionsAr : optionsEn;
}
