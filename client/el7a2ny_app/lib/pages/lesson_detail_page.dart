import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../core/localization/app_strings.dart';
import 'course_quiz_page.dart';

class LessonDetailPage extends StatefulWidget {
  final LessonModel lesson;
  final CourseModel course;
  final List<LessonModel> allLessons;
  final int currentLessonIndex;

  const LessonDetailPage({
    super.key,
    required this.lesson,
    required this.course,
    required this.allLessons,
    required this.currentLessonIndex,
  });

  @override
  State<LessonDetailPage> createState() => _LessonDetailPageState();
}

class _LessonDetailPageState extends State<LessonDetailPage> {
  final ScrollController _scrollController = ScrollController();
  double _readProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateReadProgress);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateReadProgress);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateReadProgress() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll <= 0) return;
    setState(() {
      _readProgress = (currentScroll / maxScroll).clamp(0.0, 1.0);
    });
  }

  // A lightweight parser to render standard Markdown content cleanly
  List<Widget> _parseContent(String text, ThemeData theme, bool isAr) {
    final List<Widget> widgets = [];
    final lines = text.split('\n');

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 12));
        continue;
      }

      // Headers ###
      if (trimmed.startsWith('###')) {
        final headerText = trimmed.replaceFirst('###', '').trim();
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              headerText,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: theme.primaryColor,
                fontFamily: 'NotoSansArabic',
              ),
            ),
          ),
        );
        continue;
      }

      // Ordered / Unordered lists
      if (trimmed.startsWith('-') || trimmed.startsWith('*') || RegExp(r'^\d+\.').hasMatch(trimmed)) {
        final isOrdered = RegExp(r'^\d+\.').hasMatch(trimmed);
        final listText = isOrdered 
            ? trimmed.replaceFirst(RegExp(r'^\d+\.'), '').trim()
            : trimmed.substring(1).trim();

        // Extract bold parts inside the list item: **bold text**
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOrdered ? trimmed.split('.').first + '. ' : '• ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
                Expanded(
                  child: _renderFormattedText(listText, theme),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // Normal paragraph
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: _renderFormattedText(trimmed, theme),
        ),
      );
    }

    return widgets;
  }

  // Helper to parse basic bold markdown **text** inline
  Widget _renderFormattedText(String text, ThemeData theme) {
    final parts = text.split('**');
    if (parts.length <= 1) {
      return Text(
        text,
        style: TextStyle(
          fontSize: 14,
          height: 1.6,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          fontFamily: 'NotoSansArabic',
        ),
      );
    }

    final List<TextSpan> spans = [];
    for (int i = 0; i < parts.length; i++) {
      final isBold = i % 2 == 1;
      spans.add(
        TextSpan(
          text: parts[i],
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold 
                ? theme.primaryColor 
                : theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
      );
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 14,
          height: 1.6,
          fontFamily: 'NotoSansArabic',
        ),
        children: spans,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = context.loc;
    final isAr = loc.isAr;

    final isLastLesson = widget.currentLessonIndex == widget.allLessons.length - 1;
    final progressLabel = loc.lessonProgress(widget.currentLessonIndex + 1, widget.allLessons.length);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.course.title(isAr),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey, fontFamily: 'NotoSansArabic'),
            ),
            const SizedBox(height: 2),
            Text(
              progressLabel,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, fontFamily: 'NotoSansArabic'),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: _readProgress,
            backgroundColor: theme.dividerColor.withValues(alpha: 0.05),
            color: theme.primaryColor,
            minHeight: 4,
          ),
        ),
      ),
      body: Stack(
        children: [
          Scrollbar(
            controller: _scrollController,
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Lesson Title ---
                  Text(
                    widget.lesson.title(isAr),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'NotoSansArabic',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, color: Colors.grey, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        isAr 
                            ? '${widget.lesson.readingTimeMinutes} دقائق قراءة'
                            : '${widget.lesson.readingTimeMinutes} mins read',
                        style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'NotoSansArabic'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),

                  // --- Rendered Content ---
                  ..._parseContent(widget.lesson.content(isAr), theme, isAr),
                  
                  const SizedBox(height: 40),
                  
                  // Clean Info Banner at the end
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.primaryColor.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: theme.primaryColor, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            loc.lessonCompleteTip,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'NotoSansArabic'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- Bottom Action Navigation Bar ---
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
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLastLesson ? const Color(0xFF10B981) : theme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                onPressed: () {
                  if (isLastLesson) {
                    // Navigate to Quiz page
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => CourseQuizPage(course: widget.course),
                      ),
                    );
                  } else {
                    // Navigate to next lesson
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => LessonDetailPage(
                          lesson: widget.allLessons[widget.currentLessonIndex + 1],
                          course: widget.course,
                          allLessons: widget.allLessons,
                          currentLessonIndex: widget.currentLessonIndex + 1,
                        ),
                      ),
                    );
                  }
                },
                child: Text(
                  isLastLesson ? loc.startCourseQuiz : loc.nextLesson,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'NotoSansArabic'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
