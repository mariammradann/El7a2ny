import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/course_model.dart';
import '../core/localization/app_strings.dart';
import '../core/auth/auth_token_store.dart';
import 'badge_celebration_page.dart';

class CourseQuizPage extends StatefulWidget {
  final CourseModel course;
  const CourseQuizPage({super.key, required this.course});

  @override
  State<CourseQuizPage> createState() => _CourseQuizPageState();
}

class _CourseQuizPageState extends State<CourseQuizPage> {
  int _currentQuestionIndex = 0;
  int? _selectedOptionIndex;
  int _score = 0;
  bool _submitting = false;
  bool _quizFinished = false;

  final List<int> _userAnswers = [];

  void _selectOption(int index) {
    if (_quizFinished) return;
    setState(() {
      _selectedOptionIndex = index;
    });
  }

  void _nextQuestion() {
    if (_selectedOptionIndex == null) return;

    _userAnswers.add(_selectedOptionIndex!);
    
    // Check if correct
    final correctIdx = widget.course.quizQuestions[_currentQuestionIndex].correctOptionIndex;
    if (_selectedOptionIndex == correctIdx) {
      _score++;
    }

    if (_currentQuestionIndex < widget.course.quizQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedOptionIndex = null;
      });
    } else {
      _finishQuiz();
    }
  }

  Future<void> _finishQuiz() async {
    setState(() {
      _quizFinished = true;
      _submitting = true;
    });

    final totalQuestions = widget.course.quizQuestions.length;
    final passThreshold = 0.7; // 70% passing grade
    final percentScore = _score / totalQuestions;
    final passed = percentScore >= passThreshold;

    if (passed) {
      try {
        final userId = AuthTokenStore.userId;
        if (userId != null) {
          await ApiService.completeCourse(widget.course.courseId, userId);
        }
      } catch (e) {
        debugPrint("Error updating course completion on server: $e");
      }
    }

    setState(() => _submitting = false);
  }

  void _restartQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _selectedOptionIndex = null;
      _score = 0;
      _quizFinished = false;
      _userAnswers.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = context.loc;
    final isAr = loc.isAr;

    if (_submitting) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_quizFinished) {
      return _buildQuizResultView(context);
    }

    final questions = widget.course.quizQuestions;
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(loc.courseQuiz),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Text(
            loc.noQuizAvailable,
            style: const TextStyle(fontFamily: 'NotoSansArabic'),
          ),
        ),
      );
    }

    final currentQuestion = questions[_currentQuestionIndex];
    final progressVal = (_currentQuestionIndex + 1) / questions.length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          loc.courseQuiz,
          style: const TextStyle(fontWeight: FontWeight.w900, fontFamily: 'NotoSansArabic'),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: progressVal,
            backgroundColor: theme.dividerColor.withValues(alpha: 0.05),
            color: const Color(0xFF10B981),
            minHeight: 6,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Question Counter
            Text(
              loc.questionProgress(_currentQuestionIndex + 1, questions.length),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
                fontFamily: 'NotoSansArabic',
              ),
            ),
            const SizedBox(height: 12),

            // Question Text
            Text(
              currentQuestion.questionText(isAr),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                fontFamily: 'NotoSansArabic',
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),

            // Options List
            Expanded(
              child: ListView.builder(
                itemCount: currentQuestion.options(isAr).length,
                itemBuilder: (context, idx) {
                  final optionText = currentQuestion.options(isAr)[idx];
                  final isSelected = _selectedOptionIndex == idx;

                  return _OptionSelectionTile(
                    optionText: optionText,
                    isSelected: isSelected,
                    onTap: () => _selectOption(idx),
                  );
                },
              ),
            ),

            // Next Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedOptionIndex != null ? theme.primaryColor : Colors.grey.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 1,
              ),
              onPressed: _selectedOptionIndex != null ? _nextQuestion : null,
              child: Text(
                _currentQuestionIndex == questions.length - 1
                    ? loc.finishQuizSubmit
                    : loc.nextQuestion,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'NotoSansArabic'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizResultView(BuildContext context) {
    final theme = Theme.of(context);
    final loc = context.loc;

    final totalQuestions = widget.course.quizQuestions.length;
    final percentScore = _score / totalQuestions;
    final passed = percentScore >= 0.7;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Icon Result
              Icon(
                passed ? Icons.verified_user_rounded : Icons.cancel_rounded,
                size: 96,
                color: passed ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              ),
              const SizedBox(height: 24),

              // Title result
              Text(
                passed
                    ? loc.quizPassedTitle
                    : loc.quizFailedTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'NotoSansArabic',
                ),
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                passed
                    ? loc.quizPassedDesc(_score, totalQuestions)
                    : loc.quizFailedDesc(_score, totalQuestions),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontFamily: 'NotoSansArabic',
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // Score Circle Indicator
              Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: passed ? const Color(0xFF10B981).withValues(alpha: 0.1) : const Color(0xFFEF4444).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: passed ? const Color(0xFF10B981).withValues(alpha: 0.3) : const Color(0xFFEF4444).withValues(alpha: 0.3),
                      width: 4,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(percentScore * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: passed ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          ),
                        ),
                        Text(
                          loc.quizScoreLabel,
                          style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'NotoSansArabic'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Action buttons
              if (passed)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                  onPressed: () {
                    // Navigate to Badge Celebration Page
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => BadgeCelebrationPage(course: widget.course),
                      ),
                    );
                  },
                  child: Text(
                    loc.claimBadge,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'NotoSansArabic'),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh_rounded),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 1,
                      ),
                      onPressed: _restartQuiz,
                      label: Text(
                        loc.retakeQuiz,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'NotoSansArabic'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        loc.returnToCourse,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'NotoSansArabic'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionSelectionTile extends StatelessWidget {
  final String optionText;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionSelectionTile({
    required this.optionText,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isSelected 
            ? theme.primaryColor.withValues(alpha: 0.08) 
            : theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected 
              ? theme.primaryColor 
              : theme.dividerColor.withValues(alpha: 0.08),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Icon(
          isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
          color: isSelected ? theme.primaryColor : Colors.grey,
        ),
        title: Text(
          optionText,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontFamily: 'NotoSansArabic',
          ),
        ),
      ),
    );
  }
}
