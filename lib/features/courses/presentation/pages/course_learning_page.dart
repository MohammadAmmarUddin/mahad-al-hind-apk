import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/youtube_utils.dart';
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

class _CourseLearningPageState extends ConsumerState<CourseLearningPage> {
  int _currentVideoIndex = 0;
  int _activeTab = 0;
  bool _showCurriculumSheet = false;
  List<bool> _sectionExpanded = [true];
  WebViewController? _videoController;
  bool _videoLoading = false;
  Set<int> _completedLessons = {};
  int _selectedRating = 0;
  final _reviewCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCompletedLessons();
  }

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCompletedLessons() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'course_completed_lessons_${widget.courseId}';
    final data = prefs.getStringList(key);
    if (data != null && mounted) {
      setState(() {
        _completedLessons = data.map((e) => int.parse(e)).toSet();
      });
    }
  }

  Future<void> _saveCompletedLessons() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'course_completed_lessons_${widget.courseId}';
    await prefs.setStringList(key, _completedLessons.map((e) => e.toString()).toList());
  }

  void _initVideoPlayer(String url) {
    final embed = YouTubeUtils.getEmbedUrl(url);
    if (embed == null) return;
    setState(() { _videoLoading = true; });
    _videoController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0F172A))
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() { _videoLoading = false; });
        },
        onWebResourceError: (_) {
          if (mounted) setState(() { _videoLoading = false; });
        },
      ))
      ..loadRequest(Uri.parse(embed));
  }

  void _playVideo(int index, List<Map<String, dynamic>> videos) {
    if (index < 0 || index >= videos.length) return;
    setState(() {
      _currentVideoIndex = index;
      _videoController = null;
    });
    final url = videos[index]['videoLink'];
    if (url != null) _initVideoPlayer(url);
  }

  void _markCompleted(int index) {
    setState(() { _completedLessons.add(index); });
    _saveCompletedLessons();
  }

  Future<void> _unlockNextVideo(String userId, String courseId) async {
    try {
      final dio = ref.read(dioClientProvider);
      await dio.ensureTokenLoaded();
      await dio.patch(
        '${ApiEndpoints.unlockVideo(userId)}',
        data: {'_id': courseId},
      );
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

    setState(() { _isSubmitting = true; });
    try {
      final dio = ref.read(dioClientProvider);
      await dio.ensureTokenLoaded();
      await dio.post(
        '${ApiEndpoints.giveRating(courseId)}',
        data: {
          'reviewerId': user.id,
          'rating': _selectedRating.toString(),
          'comments': _reviewCtrl.text.trim(),
        },
      );
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
      if (mounted) setState(() { _isSubmitting = false; });
    }
  }

  List<Map<String, dynamic>> _chunkList(List<Map<String, dynamic>> list, int size) {
    final chunks = <Map<String, dynamic>>[];
    for (var i = 0; i < list.length; i += size) {
      chunks.add({
        'start': i,
        'end': (i + size > list.length) ? list.length : i + size,
      });
    }
    return chunks;
  }

  @override
  Widget build(BuildContext context) {
    final courseAsync = ref.watch(courseDetailProvider(widget.courseId));
    final userAsync = ref.watch(currentUserProvider);

    return courseAsync.when(
      data: (course) {
        final user = userAsync.valueOrNull;
        final isEnrolled = user != null && course.students.any((s) => s['studentsId'] == user.id);
        final studentData = isEnrolled ? course.students.firstWhere((s) => s['studentsId'] == user.id) : null;
        final unlockedVideos = studentData?['unlockedVideo'] ?? 1;
        final isCourseComplete = studentData?['isCourseComplete'] == true;
        final isQuizComplete = studentData?['isQuizComplete'] == true;
        final certificateId = studentData?['certificateUrl'];
        final videos = course.videos;
        final avgRating = _calculateAverageRating(course.studentsOpinion);

        // Initialize video player if not already
        if (_videoController == null && videos.isNotEmpty) {
          final url = videos[_currentVideoIndex]['videoLink'];
          if (url != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _videoController == null) _initVideoPlayer(url);
            });
          }
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () => context.pop(),
            ),
            title: Text(
              course.title ?? 'Course',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              if (isCourseComplete && isQuizComplete && certificateId != null)
                IconButton(
                  icon: const Icon(Icons.emoji_events, color: AppColors.success),
                  onPressed: () {},
                  tooltip: 'View Certificate',
                ),
            ],
          ),
          body: Column(
            children: [
              // Video Player
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: const Color(0xFF0F172A),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_videoLoading)
                        const CircularProgressIndicator(color: AppColors.primary),
                      if (_videoController != null)
                        WebViewWidget(controller: _videoController!),
                    ],
                  ),
                ),
              ),

              // Lesson Info + Navigation
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: AppColors.surface,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        videos[_currentVideoIndex]['videoTitle'] ?? 'Lesson ${_currentVideoIndex + 1}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _navButton(
                      'Prev',
                      _currentVideoIndex > 0,
                      () => _playVideo(_currentVideoIndex - 1, videos),
                    ),
                    const SizedBox(width: 8),
                    _navButton(
                      'Next',
                      _currentVideoIndex < videos.length - 1,
                      () async {
                        if (_currentVideoIndex + 1 >= unlockedVideos) {
                          await _unlockNextVideo(user!.id, widget.courseId);
                        }
                        _playVideo(_currentVideoIndex + 1, videos);
                      },
                      isPrimary: true,
                    ),
                  ],
                ),
              ),

              // Tab Bar
              Container(
                color: AppColors.surface,
                child: Row(
                  children: [
                    _tab('Overview', 0),
                    _tab('Curriculum', 1),
                    _tab('Reviews', 2),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Tab Content
              Expanded(
                child: _activeTab == 0
                    ? _buildOverview(course, avgRating, user, isCourseComplete, isQuizComplete, certificateId)
                    : _activeTab == 1
                        ? _buildCurriculum(videos, unlockedVideos)
                        : _buildReviews(course.studentsOpinion, user),
              ),
            ],
          ),

          // Bottom Bar
          bottomNavigationBar: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showCurriculumModal(videos, unlockedVideos),
                      icon: const Icon(Icons.menu_book, size: 18),
                      label: const Text('Course Content'),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
                  if (isCourseComplete && isQuizComplete) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.emoji_events, size: 18),
                        label: const Text('Certificate'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
    );
  }

  double _calculateAverageRating(List<dynamic> opinions) {
    if (opinions.isEmpty) return 0;
    double total = 0;
    for (final o in opinions) {
      total += double.tryParse(o['rating'].toString()) ?? 0;
    }
    return total / opinions.length;
  }

  Widget _navButton(String label, bool enabled, VoidCallback onTap, {bool isPrimary = false}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isPrimary
              ? (enabled ? AppColors.primary : AppColors.textHint.withOpacity(0.3))
              : AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isPrimary ? Colors.white : (enabled ? AppColors.textPrimary : AppColors.textHint),
          ),
        ),
      ),
    );
  }

  Widget _tab(String label, int index) {
    final isActive = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() { _activeTab = index; }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
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
  }

  Widget _buildOverview(dynamic course, double avgRating, dynamic user, bool isCourseComplete, bool isQuizComplete, String? certificateId) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Rating
        Row(
          children: [
            Text(avgRating.toStringAsFixed(1), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.warning)),
            const SizedBox(width: 6),
            ...List.generate(5, (i) => Icon(
              i < avgRating.round() ? Icons.star : Icons.star_border,
              color: AppColors.warning,
              size: 18,
            )),
            const SizedBox(width: 6),
            Text('(${course.studentsOpinion.length})', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 12),

        // Description
        if (course.magnetLine != null && course.magnetLine!.isNotEmpty) ...[
          Text(course.magnetLine!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5)),
          const SizedBox(height: 16),
        ],

        // Certificate button
        if (isCourseComplete && certificateId != null) ...[
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.emoji_events),
            label: const Text('View Certificate'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
          ),
          const SizedBox(height: 16),
        ],

        // Course Details
        if (course.details != null && course.details!.isNotEmpty) ...[
          const Text('Course Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(course.details!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),
          const SizedBox(height: 16),
        ],

        // Requirements
        if (course.requirements != null && course.requirements!.isNotEmpty) ...[
          const Text('Requirements', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(course.requirements!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 16),
        ],

        // Leave a Review
        const Text('Leave a Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (i) => GestureDetector(
            onTap: () => setState(() { _selectedRating = i + 1; }),
            child: Icon(
              i < _selectedRating ? Icons.star : Icons.star_border,
              color: AppColors.warning,
              size: 28,
            ),
          )),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _reviewCtrl,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Write your review...', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : () => _submitReview(widget.courseId),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
            child: _isSubmitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Submit Review'),
          ),
        ),
      ],
    );
  }

  Widget _buildCurriculum(List<Map<String, dynamic>> videos, int unlockedVideos) {
    final chunks = <Map<String, dynamic>>[];
    for (var i = 0; i < videos.length; i += 5) {
      chunks.add({'start': i, 'end': (i + 5 > videos.length) ? videos.length : i + 5});
    }
    // Ensure sectionExpanded has enough entries
    while (_sectionExpanded.length < chunks.length) {
      _sectionExpanded.add(false);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: chunks.length + 1, // +1 for quiz
      itemBuilder: (context, sIdx) {
        if (sIdx == chunks.length) {
          // Quiz entry
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.quiz, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                const Expanded(child: Text('Quiz', style: TextStyle(fontWeight: FontWeight.w600))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('After Videos', style: TextStyle(fontSize: 11, color: AppColors.primary)),
                ),
              ],
            ),
          );
        }

        final chunk = chunks[sIdx];
        final isExpanded = _sectionExpanded[sIdx];
        final start = chunk['start'] as int;
        final end = chunk['end'] as int;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            GestureDetector(
              onTap: () => setState(() { _sectionExpanded[sIdx] = !isExpanded; }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: AppColors.surface,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Section ${sIdx + 1}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          Text('${end - start} lectures', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ),
                    Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),

            // Lessons
            if (isExpanded)
              ...List.generate(end - start, (i) {
                final globalIdx = start + i;
                final video = videos[globalIdx];
                final isLocked = globalIdx >= unlockedVideos;
                final isActive = globalIdx == _currentVideoIndex;
                final isCompleted = _completedLessons.contains(globalIdx);

                return GestureDetector(
                  onTap: isLocked
                      ? () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Complete previous lessons first')),
                        )
                      : () {
                          _playVideo(globalIdx, videos);
                          Navigator.pop(context); // Close bottom sheet
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary.withOpacity(0.05) : null,
                      border: Border(
                        left: BorderSide(
                          color: isActive ? AppColors.primary : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        isLocked
                            ? const Icon(Icons.lock_outline, size: 16, color: AppColors.textHint)
                            : isCompleted
                                ? const Icon(Icons.check_circle, size: 16, color: AppColors.success)
                                : Icon(
                                    isActive ? Icons.play_circle_filled : Icons.play_circle_outline,
                                    size: 16,
                                    color: isActive ? AppColors.primary : AppColors.textSecondary,
                                  ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            video['videoTitle'] ?? 'Lesson ${globalIdx + 1}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                              color: isLocked ? AppColors.textHint : (isActive ? AppColors.primary : AppColors.textPrimary),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  Widget _buildReviews(List<dynamic> opinions, dynamic user) {
    if (opinions.isEmpty) {
      return const Center(
        child: Text('No reviews yet', style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: opinions.length,
      itemBuilder: (context, i) {
        final opinion = opinions[i];
        final rating = double.tryParse(opinion['rating'].toString()) ?? 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ...List.generate(5, (j) => Icon(
                    j < rating ? Icons.star : Icons.star_border,
                    color: AppColors.warning,
                    size: 14,
                  )),
                  const SizedBox(width: 8),
                  Text(opinion['comments'] ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCurriculumModal(List<Map<String, dynamic>> videos, int unlockedVideos) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.textHint.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Course Content', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    Text('${videos.length} lectures', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: _buildCurriculum(videos, unlockedVideos),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
