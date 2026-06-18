import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/youtube_player_widget.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../shared/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/courses_provider.dart';

class CourseLearningPage extends ConsumerStatefulWidget {
  final String courseId;
  const CourseLearningPage({super.key, required this.courseId});

  @override
  ConsumerState<CourseLearningPage> createState() => _CourseLearningPageState();
}

class _CourseLearningPageState extends ConsumerState<CourseLearningPage>
    with SingleTickerProviderStateMixin {
  int _currentVideoIndex = 0;
  int _activeTab = 0;
  List<bool> _sectionExpanded = [true];
  Set<int> _completedLessons = {};
  int _selectedRating = 0;
  final _reviewCtrl = TextEditingController();
  bool _isSubmitting = false;
  bool _videoInitialized = false;
  bool _courseLoaded = false;
  late AnimationController _tabAnimController;

  @override
  void initState() {
    super.initState();
    _tabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _loadCompletedLessons();
  }

  @override
  void dispose() {
    _reviewCtrl.dispose();
    _tabAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadCompletedLessons() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('course_completed_lessons_${widget.courseId}');
    if (data != null && mounted) {
      setState(() {
        _completedLessons = data.map((e) => int.parse(e)).toSet();
      });
    }
  }

  Future<void> _saveCompletedLessons() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'course_completed_lessons_${widget.courseId}',
      _completedLessons.map((e) => e.toString()).toList(),
    );
  }

  void _markCompleted(int index) {
    if (!_completedLessons.contains(index)) {
      setState(() => _completedLessons.add(index));
      _saveCompletedLessons();
    }
  }

  Future<void> _unlockNextVideo(String userId, String courseId) async {
    try {
      final dio = ref.read(dioClientProvider);
      await dio.ensureTokenLoaded();
      await dio.patch(ApiEndpoints.unlockVideo(userId), data: {'_id': courseId});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to unlock: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _submitReview(String courseId) async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating'), backgroundColor: AppColors.error),
      );
      return;
    }
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isSubmitting = true);
    try {
      final dio = ref.read(dioClientProvider);
      await dio.ensureTokenLoaded();
      await dio.post(ApiEndpoints.giveRating(courseId), data: {
        'reviewerId': user.id,
        'rating': _selectedRating.toString(),
        'comments': _reviewCtrl.text.trim(),
      });
      _reviewCtrl.clear();
      _selectedRating = 0;
      ref.invalidate(courseDetailProvider(widget.courseId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  double _calcAvgRating(List<dynamic> opinions) {
    if (opinions.isEmpty) return 0;
    double total = 0;
    for (final o in opinions) {
      total += double.tryParse(o['rating'].toString()) ?? 0;
    }
    return total / opinions.length;
  }

  String _stripHtml(String? html) => (html ?? '').replaceAll(RegExp(r'<[^>]*>'), '').trim();

  void _switchTab(int index) {
    if (_activeTab == index) return;
    HapticFeedback.lightImpact();
    setState(() => _activeTab = index);
  }

  @override
  Widget build(BuildContext context) {
    final courseAsync = ref.watch(courseDetailProvider(widget.courseId));
    final userAsync = ref.watch(currentUserProvider);

    return courseAsync.when(
      data: (course) {
        if (course.videos.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text(course.title ?? 'Course')),
            body: const Center(child: Text('No videos available')),
          );
        }

        final user = userAsync.valueOrNull;
        final isEnrolled = user != null &&
            course.students.any((s) => s['studentsId'] == user.id);
        final studentData = isEnrolled
            ? course.students.firstWhere((s) => s['studentsId'] == user.id)
            : null;
        final unlockedVideos = (studentData?['unlockedVideo'] as int?) ?? 1;
        final isCourseComplete = studentData?['isCourseComplete'] == true;
        final isQuizComplete = studentData?['isQuizComplete'] == true;
        final certificateId = studentData?['certificateUrl'] as String?;
        final videos = course.videos;
        final avgRating = _calcAvgRating(course.studentsOpinion);

        if (_currentVideoIndex >= videos.length) _currentVideoIndex = 0;

        if (!_courseLoaded) {
          _courseLoaded = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_videoInitialized) {
              final url = (videos[0]['videoLink'] as String?) ?? '';
              if (url.isNotEmpty) {
                setState(() {
                  _currentVideoIndex = 0;
                  _videoInitialized = true;
                });
              }
            }
          });
        }

        final currentVideo = videos[_currentVideoIndex];
        final videoUrl = (currentVideo['videoLink'] as String?) ?? '';
        final videoTitle = (currentVideo['videoTitle'] as String?) ??
            'Lesson ${_currentVideoIndex + 1}';

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
          ),
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              top: false,
              child: Column(
                children: [
                  _buildTopBar(context, course.title ?? 'Course',
                      isCourseComplete, isQuizComplete, certificateId),
                  _VideoPlayerWidget(
                    key: ValueKey('video_$_currentVideoIndex'),
                    url: videoUrl,
                  ),
                  _buildLessonBar(
                      videoTitle, videos.length, _currentVideoIndex, videos, user, unlockedVideos),
                  _buildTabBar(),
                  Expanded(
                    child: _activeTab == 0
                        ? _buildOverview(course, avgRating, user, isCourseComplete,
                            isQuizComplete, certificateId)
                        : _activeTab == 1
                            ? _buildCurriculum(videos, unlockedVideos)
                            : _buildReviews(course.studentsOpinion),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: _buildBottomBar(videos, user, unlockedVideos),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Course')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              const Text('Error loading course',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(courseDetailProvider(widget.courseId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(
      BuildContext context, String title, bool isComplete, bool isQuizComplete, String? certId) {
    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                onPressed: () => context.pop(),
              ),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isComplete && isQuizComplete && certId != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: const Icon(Icons.emoji_events_rounded,
                        color: AppColors.warning, size: 24),
                    onPressed: () {},
                  ),
                ),
            ],
          ),
          const Divider(height: 0.5, thickness: 0.5),
        ],
      ),
    );
  }

  Widget _buildLessonBar(String title, int total, int current, List<dynamic> videos,
      dynamic user, int unlockedVideos) {
    final progress = total > 0 ? (current + 1) / total : 0.0;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      color: AppColors.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lesson ${current + 1} of $total',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _pillButton('Prev', current > 0, Icons.chevron_left_rounded, () {
                _markCompleted(current);
                setState(() {
                  _currentVideoIndex = current - 1;
                  _videoInitialized = true;
                });
              }),
              const SizedBox(width: 8),
              _pillButton('Next', current < videos.length - 1,
                  Icons.chevron_right_rounded, () async {
                _markCompleted(current);
                final nextIdx = current + 1;
                if (nextIdx >= unlockedVideos && user != null) {
                  await _unlockNextVideo(user.id, widget.courseId);
                  ref.invalidate(courseDetailProvider(widget.courseId));
                }
                setState(() {
                  _currentVideoIndex = nextIdx;
                  _videoInitialized = true;
                });
              }, isPrimary: true),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillButton(String label, bool enabled, IconData icon, VoidCallback onTap,
      {bool isPrimary = false}) {
    return GestureDetector(
      onTap: enabled
          ? () {
              HapticFeedback.lightImpact();
              onTap();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isPrimary
              ? (enabled ? AppColors.primary : AppColors.textHint.withOpacity(0.3))
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: isPrimary
                    ? Colors.white
                    : (enabled ? AppColors.textPrimary : AppColors.textHint)),
            const SizedBox(width: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isPrimary
                    ? Colors.white
                    : (enabled ? AppColors.textPrimary : AppColors.textHint),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final tabs = ['Overview', 'Curriculum', 'Reviews'];
    return Container(
      color: AppColors.surface,
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isActive = _activeTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => _switchTab(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive ? AppColors.primary : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Text(
                  tabs[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isActive ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildOverview(dynamic course, double avgRating, dynamic user,
      bool isCourseComplete, bool isQuizComplete, String? certificateId) {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 18, color: AppColors.warning),
                        const SizedBox(width: 4),
                        Text(avgRating.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('(${course.studentsOpinion.length} ratings)',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.school_rounded,
                        size: 20, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  const Text('What you\'ll learn',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 12),
              _learnItem('${course.videos.length} HD video lectures'),
              _learnItem('Interactive quiz after completion'),
              _learnItem('Certificate of completion'),
              _learnItem('Lifetime access'),
            ],
          ),
        ),
        if (course.magnetLine != null && course.magnetLine!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _card(
            child: Text(course.magnetLine!,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14, height: 1.6)),
          ),
        ],
        if (course.details != null && course.details!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Course Details',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(_stripHtml(course.details),
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.6)),
              ],
            ),
          ),
        ],
        if (course.requirements != null && course.requirements!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Requirements',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(course.requirements!,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 14)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        _buildReviewInput(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildReviewInput() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Leave a Review',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: List.generate(5, (i) => GestureDetector(
                  onTap: () => setState(() => _selectedRating = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        i < _selectedRating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        key: ValueKey(i < _selectedRating),
                        color: AppColors.warning,
                        size: 34,
                      ),
                    ),
                  ),
                )),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reviewCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Write your review...',
              hintStyle: const TextStyle(color: AppColors.textHint),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.surfaceVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.surfaceVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed:
                  _isSubmitting ? null : () => _submitReview(widget.courseId),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Submit Review',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _learnItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary))),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: child,
    );
  }

  Widget _buildCurriculum(List<dynamic> videos, int unlockedVideos) {
    final sections = <Map<String, dynamic>>[];
    for (var i = 0; i < videos.length; i += 5) {
      sections.add({
        'start': i,
        'end': (i + 5 > videos.length) ? videos.length : i + 5,
      });
    }
    while (_sectionExpanded.length < sections.length) {
      _sectionExpanded.add(false);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      physics: const BouncingScrollPhysics(),
      itemCount: sections.length + 1,
      itemBuilder: (context, sIdx) {
        if (sIdx == sections.length) {
          return _buildQuizCard(videos.length);
        }

        final section = sections[sIdx];
        final isExpanded = _sectionExpanded[sIdx];
        final start = section['start'] as int;
        final end = section['end'] as int;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () =>
                      setState(() => _sectionExpanded[sIdx] = !isExpanded),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text('${sIdx + 1}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Section ${sIdx + 1}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600, fontSize: 13)),
                              Text('${end - start} lectures',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary, fontSize: 11)),
                            ],
                          ),
                        ),
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(Icons.keyboard_arrow_down,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Column(
                  children: List.generate(end - start, (i) {
                    final globalIdx = start + i;
                    final video = videos[globalIdx];
                    final isLocked = globalIdx >= unlockedVideos;
                    final isActive = globalIdx == _currentVideoIndex;
                    final isCompleted = _completedLessons.contains(globalIdx);

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isLocked
                            ? () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Complete previous lessons first')))
                            : () {
                                setState(() {
                                  _activeTab = 0;
                                  _currentVideoIndex = globalIdx;
                                  _videoInitialized = true;
                                });
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.primary.withOpacity(0.05)
                                : null,
                            border: Border(
                              left: BorderSide(
                                color: isActive
                                    ? AppColors.primary
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              _lessonIcon(isLocked, isCompleted, isActive),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  (video['videoTitle'] as String?) ??
                                      'Lesson ${globalIdx + 1}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isActive
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: isLocked
                                        ? AppColors.textHint
                                        : (isActive
                                            ? AppColors.primary
                                            : AppColors.textPrimary),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (!isLocked && !isCompleted && !isActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('Play',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600)),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _lessonIcon(bool isLocked, bool isCompleted, bool isActive) {
    if (isLocked) {
      return const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.textHint);
    }
    if (isCompleted) {
      return Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(
          color: AppColors.success,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
      );
    }
    return Icon(
      isActive ? Icons.play_circle_filled_rounded : Icons.play_circle_outline_rounded,
      size: 20,
      color: isActive ? AppColors.primary : AppColors.textSecondary,
    );
  }

  Widget _buildQuizCard(int totalVideos) {
    final allComplete = _completedLessons.length >= totalVideos;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: allComplete
                  ? AppColors.primary.withOpacity(0.1)
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.quiz_rounded,
                size: 20,
                color: allComplete ? AppColors.primary : AppColors.textHint),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Quiz',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: allComplete
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              allComplete ? 'Available' : 'Locked',
              style: TextStyle(
                fontSize: 11,
                color:
                    allComplete ? AppColors.success : AppColors.textHint,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviews(List<dynamic> opinions) {
    if (opinions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.rate_review_rounded, size: 56, color: AppColors.textHint),
            SizedBox(height: 16),
            Text('No reviews yet',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: opinions.length,
      itemBuilder: (context, i) {
        final opinion = opinions[i];
        final rating = double.tryParse(opinion['rating'].toString()) ?? 0;
        final comment = (opinion['comments'] as String?) ?? '';
        return _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primarySurface,
                    child: Text(
                      comment.isNotEmpty ? comment[0].toUpperCase() : '?',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Row(
                      children: List.generate(
                          5,
                          (j) => Icon(
                                j < rating
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: AppColors.warning,
                                size: 16,
                              )),
                    ),
                  ),
                ],
              ),
              if (comment.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(comment,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(List<dynamic> videos, dynamic user, int unlockedVideos) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showCurriculumModal(videos, unlockedVideos),
                icon: const Icon(Icons.menu_book_rounded, size: 18),
                label: const Text('Content', style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: AppColors.surfaceVariant),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _markCompleted(_currentVideoIndex);
                  if (_currentVideoIndex < videos.length - 1) {
                    setState(() {
                      _currentVideoIndex++;
                      _videoInitialized = true;
                    });
                  }
                },
                icon: const Icon(Icons.skip_next_rounded, size: 20),
                label: Text(
                  _currentVideoIndex < videos.length - 1
                      ? 'Next Lesson'
                      : 'Complete',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCurriculumModal(List<dynamic> videos, int unlockedVideos) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textHint.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Course Content',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold)),
                    ),
                    Text('${videos.length} lectures',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 0.5),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  children: _buildModalCurriculumList(videos, unlockedVideos),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildModalCurriculumList(
      List<dynamic> videos, int unlockedVideos) {
    final sections = <Map<String, dynamic>>[];
    for (var i = 0; i < videos.length; i += 5) {
      sections.add({
        'start': i,
        'end': (i + 5 > videos.length) ? videos.length : i + 5,
      });
    }

    final widgets = <Widget>[];
    for (var sIdx = 0; sIdx < sections.length; sIdx++) {
      final section = sections[sIdx];
      final isExpanded =
          sIdx < _sectionExpanded.length ? _sectionExpanded[sIdx] : false;
      final start = section['start'] as int;
      final end = section['end'] as int;

      widgets.add(
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _sectionExpanded[sIdx] = !isExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              color: AppColors.surface,
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Center(
                      child: Text('${sIdx + 1}',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Section ${sIdx + 1}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                        Text('${end - start} lectures',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 11)),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down,
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      if (isExpanded) {
        for (var i = 0; i < end - start; i++) {
          final globalIdx = start + i;
          final video = videos[globalIdx];
          final isLocked = globalIdx >= unlockedVideos;
          final isActive = globalIdx == _currentVideoIndex;
          final isCompleted = _completedLessons.contains(globalIdx);

          widgets.add(
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isLocked
                    ? () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Complete previous lessons first')))
                    : () {
                        Navigator.pop(context);
                        setState(() {
                          _activeTab = 0;
                          _currentVideoIndex = globalIdx;
                          _videoInitialized = true;
                        });
                      },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary.withOpacity(0.05)
                        : null,
                    border: Border(
                      left: BorderSide(
                        color: isActive
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      _lessonIcon(isLocked, isCompleted, isActive),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          (video['videoTitle'] as String?) ??
                              'Lesson ${globalIdx + 1}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isLocked
                                ? AppColors.textHint
                                : (isActive
                                    ? AppColors.primary
                                    : AppColors.textPrimary),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      }
    }
    return widgets;
  }
}

// ─── VIDEO PLAYER WIDGET (isolated to prevent parent rebuilds) ──────
class _VideoPlayerWidget extends StatelessWidget {
  final String url;
  const _VideoPlayerWidget({required this.url, super.key});

  @override
  Widget build(BuildContext context) {
    final isYoutube = isYouTubeUrl(url);

    if (isYoutube) {
      return YoutubePlayerWidget(
        videoUrl: url,
        autoPlay: true,
      );
    }

    // Non-YouTube: HTML5 video player via WebView (non-YouTube videos are direct links)
    if (url.isEmpty) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(
          color: Color(0xFF0F172A),
          child: Center(
            child: Text('No video', style: TextStyle(color: Colors.white38, fontSize: 13)),
          ),
        ),
      );
    }

    // For non-YouTube videos, show a tap-to-play card (direct video links)
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ColoredBox(
        color: const Color(0xFF0F172A),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.play_circle_outline_rounded, color: Colors.white54, size: 56),
              const SizedBox(height: 8),
              const Text('Tap to play video', style: TextStyle(color: Colors.white54, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
