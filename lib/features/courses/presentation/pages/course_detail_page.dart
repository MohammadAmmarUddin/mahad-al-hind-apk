import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/youtube_utils.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/entities/user.dart';
import '../providers/courses_provider.dart';
import '../../../../shared/providers/core_providers.dart';

class CourseDetailPage extends ConsumerStatefulWidget {
  final String courseId;
  const CourseDetailPage({super.key, required this.courseId});

  @override
  ConsumerState<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends ConsumerState<CourseDetailPage> {
  int _activeTab = 0;
  int _currentVideoIndex = 0;
  bool _showCurriculum = false;
  bool _showPaymentModal = false;
  String _paymentMethod = 'bKash';
  final _transactionIdCtrl = TextEditingController();
  final _reviewCtrl = TextEditingController();
  int _selectedRating = 0;
  bool _isSubmitting = false;
  List<bool> _sectionExpanded = [true];
  WebViewController? _videoController;
  bool _videoLoading = false;
  bool _hasRedirected = false;

  String? _normalizeYoutube(String? url) {
    if (url == null || url.isEmpty) return null;
    final patterns = [
      RegExp(r'youtube\.com/embed/([a-zA-Z0-9_-]+)'),
      RegExp(r'youtube\.com/watch\?v=([a-zA-Z0-9_-]+)'),
      RegExp(r'youtu\.be/([a-zA-Z0-9_-]+)'),
      RegExp(r'youtube\.com/shorts/([a-zA-Z0-9_-]+)'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(url);
      if (m != null) return 'https://www.youtube.com/embed/${m.group(1)}?autoplay=0&rel=0&modestbranding=1&playsinline=1';
    }
    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(url.trim())) {
      return 'https://www.youtube.com/embed/${url.trim()}?autoplay=0&rel=0&modestbranding=1&playsinline=1';
    }
    return null;
  }

  String? _extractYoutubeId(String? url) {
    if (url == null || url.isEmpty) return null;
    final patterns = [
      RegExp(r'youtube\.com/embed/([a-zA-Z0-9_-]+)'),
      RegExp(r'youtube\.com/watch\?v=([a-zA-Z0-9_-]+)'),
      RegExp(r'youtu\.be/([a-zA-Z0-9_-]+)'),
      RegExp(r'youtube\.com/shorts/([a-zA-Z0-9_-]+)'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(url);
      if (m != null) return m.group(1);
    }
    return null;
  }

  void _initVideoPlayer(String url) {
    final embed = _normalizeYoutube(url);
    if (embed == null) return;
    setState(() { _videoLoading = true; });
    _videoController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36')
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) { if (mounted) setState(() { _videoLoading = false; }); },
      ))
      ..loadRequest(Uri.parse(embed));
  }

  @override
  void dispose() {
    _transactionIdCtrl.dispose();
    _reviewCtrl.dispose();
    super.dispose();
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
        final paymentComplete = studentData?['paymentComplete'] == true;
        final unlockedVideos = studentData?['unlockedVideo'] ?? 1;
        final isCourseComplete = studentData?['isCourseComplete'] == true;
        final isQuizComplete = studentData?['isQuizComplete'] == true;
        final isAdmin = user?.role == 'admin';
        final finalPrice = _calcPrice(course);
        final avgRating = _avgRating(course);
        final videos = course.videos;

        if (isEnrolled && paymentComplete && !_hasRedirected) {
          _hasRedirected = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.pushReplacement('/course/${widget.courseId}/learn');
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
        }
        if (_hasRedirected) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
        }
        return _buildVisitorView(course, user, finalPrice, avgRating, isEnrolled);
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary))),
      error: (_, __) => Scaffold(
        appBar: AppBar(title: const Text('Course')),
        body: Center(child: TextButton(onPressed: () => ref.invalidate(courseDetailProvider(widget.courseId)), child: const Text('Retry'))),
      ),
    );
  }

  double _calcPrice(dynamic course) {
    final price = int.tryParse(course.price ?? '0') ?? 0;
    final discount = int.tryParse(course.discount ?? '0') ?? 0;
    return (price - (price * discount / 100)).toDouble();
  }

  double _avgRating(dynamic course) {
    if (course.studentsOpinion.isEmpty) return 0;
    final total = course.studentsOpinion.fold<int>(0, (a, b) => a + (int.tryParse(b['rating']?.toString() ?? '0') ?? 0));
    return total / course.studentsOpinion.length;
  }

  String _stripHtml(String? html) => (html ?? '').replaceAll(RegExp(r'<[^>]*>'), '').trim();

  Future<void> _enroll(dynamic course, double finalPrice, User? user) async {
    if (user == null) { context.push('/login'); return; }
    _showPaymentDialog(course, finalPrice, user);
  }

  void _showPaymentDialog(dynamic course, double finalPrice, User? user) {
    _transactionIdCtrl.clear();
    _paymentMethod = 'bKash';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: AppColors.textHint, borderRadius: BorderRadius.circular(2)))),
                const Text('Complete Enrollment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(course.title ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Amount:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      Text('\u20B9${finalPrice.round()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Payment Method', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['bKash', 'Nagad', 'Bank', 'Cash'].map((m) {
                    final selected = _paymentMethod == m;
                    return ChoiceChip(
                      label: Text(m, style: TextStyle(color: selected ? Colors.white : AppColors.textPrimary, fontSize: 13)),
                      selected: selected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surfaceVariant,
                      onSelected: (_) => setModalState(() => _paymentMethod = m),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _transactionIdCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Transaction ID *',
                    hintText: 'Enter payment transaction ID',
                    prefixIcon: Icon(Icons.receipt_long, size: 20),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : () async {
                      Navigator.pop(ctx);
                      await _submitEnrollment(course, finalPrice, user);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: _isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text('Submit Enrollment - \u20B9${finalPrice.round()}', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitEnrollment(dynamic course, double finalPrice, User? user) async {
    if (_transactionIdCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter transaction ID'), backgroundColor: AppColors.error));
      return;
    }
    setState(() { _isSubmitting = true; });
    try {
      await ref.read(dioClientProvider).post('/api/course/manual-enroll', data: {
        'courseId': course.id,
        'studentsId': user!.id,
        'payment': finalPrice.round(),
        'paymentMethod': _paymentMethod,
        'transactionId': _transactionIdCtrl.text.trim(),
      });
      setState(() { _showPaymentModal = false; _isSubmitting = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enrollment request submitted!'), backgroundColor: AppColors.success));
        ref.invalidate(courseDetailProvider(widget.courseId));
      }
    } catch (e) {
      setState(() { _isSubmitting = false; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _unlockNextVideo(String userId, dynamic course) async {
    try {
      await ref.read(dioClientProvider).patch('/api/course/unlockVideo/$userId', data: {'_id': course.id});
      ref.invalidate(courseDetailProvider(widget.courseId));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _submitReview(String courseId, String userId) async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a rating'), backgroundColor: AppColors.error));
      return;
    }
    setState(() { _isSubmitting = true; });
    try {
      await ref.read(dioClientProvider).post('/api/course/giveRating/$courseId', data: {
        'reviewerId': userId,
        'rating': _selectedRating.toString(),
        'comments': _reviewCtrl.text.trim(),
      });
      setState(() { _isSubmitting = false; _selectedRating = 0; _reviewCtrl.clear(); });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review submitted!'), backgroundColor: AppColors.success));
        ref.invalidate(courseDetailProvider(widget.courseId));
      }
    } catch (e) {
      setState(() { _isSubmitting = false; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    }
  }

  // ─── VISITOR VIEW ────────────────────────────────────────────
  Widget _buildVisitorView(dynamic course, User? user, double finalPrice, double avgRating, bool isEnrolled) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(course.title ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              background: _bannerImage(course.banner),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPriceSection(course, finalPrice, avgRating, user),
                _buildTabBar(),
                _activeTab == 0 ? _buildOverviewTab(course) : _activeTab == 1 ? _buildCurriculumTab(course, 1, false) : _buildReviewsTab(course),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
      bottomSheet: _buildEnrollBottomBar(course, finalPrice, user, isEnrolled),
    );
  }

  // ─── ENROLLED VIEW ───────────────────────────────────────────
  Widget _buildEnrolledView(dynamic course, User? user, List videos, int unlockedVideos, bool isCourseComplete, bool isQuizComplete, bool isAdmin, double avgRating) {
    final selectedVideo = _currentVideoIndex < videos.length ? videos[_currentVideoIndex] : null;
    final isYoutube = _normalizeYoutube(selectedVideo?['videoLink']) != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(course.title ?? '', style: const TextStyle(fontSize: 14)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        actions: [
          if (course.whatsappGroupLink != null && course.whatsappGroupLink!.isNotEmpty)
            IconButton(icon: const Icon(Icons.chat, color: Color(0xFF25D366)), onPressed: () => _launchUrl(course.whatsappGroupLink!)),
          if (course.syllabus != null && course.syllabus!.isNotEmpty)
            IconButton(icon: const Icon(Icons.download_outlined), onPressed: () => _launchUrl(course.syllabus!)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (selectedVideo != null)
                    _buildVideoPlayer(selectedVideo, isYoutube),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(child: Text(selectedVideo?['videoTitle'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
                        _navButton('Prev', _currentVideoIndex > 0, () {
                          setState(() { _currentVideoIndex--; });
                          _refreshVideo();
                        }),
                        const SizedBox(width: 6),
                        _navButton('Next', _currentVideoIndex < videos.length - 1, () {
                          if (_currentVideoIndex + 1 >= unlockedVideos) {
                            _unlockNextVideo(user!.id, course).then((_) {
                              setState(() { _currentVideoIndex++; });
                              _refreshVideo();
                            });
                          } else {
                            setState(() { _currentVideoIndex++; });
                            _refreshVideo();
                          }
                        }, primary: true),
                      ],
                    ),
                  ),
                  _buildTabBar(),
                  _activeTab == 0
                      ? _buildEnrolledOverviewTab(course, user, isCourseComplete, isQuizComplete)
                      : _activeTab == 1
                          ? _buildQuizSection(course, user, isCourseComplete, isQuizComplete)
                          : _buildReviewsTab(course),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          _buildCurriculumDrawer(course, videos, unlockedVideos, user),
        ],
      ),
    );
  }

  void _refreshVideo() {
    final courseAsync = ref.read(courseDetailProvider(widget.courseId));
    courseAsync.whenData((course) {
      if (_currentVideoIndex < course.videos.length) {
        final v = course.videos[_currentVideoIndex];
        if (_normalizeYoutube(v['videoLink']) != null) {
          _initVideoPlayer(v['videoLink']);
        } else {
          final url = v['videoLink'] ?? '';
          if (url.isNotEmpty) {
            setState(() { _videoLoading = true; });
            _videoController = WebViewController()
              ..setJavaScriptMode(JavaScriptMode.unrestricted)
              ..setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36')
              ..setNavigationDelegate(NavigationDelegate(
                onPageFinished: (_) { if (mounted) setState(() { _videoLoading = false; }); },
              ))
              ..loadHtmlString('''
                <!DOCTYPE html>
                <html><head>
                <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
                <style>*{margin:0;padding:0;box-sizing:border-box;}body{background:#000;display:flex;justify-content:center;align-items:center;height:100vh;overflow:hidden;}
                video{width:100%;height:100%;object-fit:contain;position:absolute;top:0;left:0;}</style>
                </head><body>
                <video src="$url" controls playsinline></video>
                </body></html>
              ''');
          }
        }
      }
    });
  }

  Widget _bannerImage(String? url) {
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(imageUrl: url, fit: BoxFit.cover,
        errorWidget: (_, __, ___) => Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient), child: const Icon(Icons.play_circle, color: Colors.white, size: 48)),
      );
    }
    return Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient), child: const Icon(Icons.play_circle, color: Colors.white, size: 48));
  }

  Widget _buildPriceSection(dynamic course, double finalPrice, double avgRating, User? user) {
    final price = int.tryParse(course.price ?? '0') ?? 0;
    final discount = int.tryParse(course.discount ?? '0') ?? 0;
    final isFree = price == 0;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(isFree ? 'Free' : '\u20B9${finalPrice.round()}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary)),
              if (!isFree && discount > 0) ...[
                const SizedBox(width: 8),
                Text('\u20B9$price', style: const TextStyle(fontSize: 16, decoration: TextDecoration.lineThrough, color: AppColors.textHint)),
                const SizedBox(width: 8),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text('$discount% OFF', style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.bold))),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(children: [
            _ratingStars(avgRating),
            const SizedBox(width: 4),
            Text('(${course.studentsOpinion.length})', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ]),
          const SizedBox(height: 8),
          Text(course.magnetLine ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 6, children: [
            _infoChip(Icons.play_circle_outline, '${course.totalLessons} lectures'),
            if (course.category != null && course.category!.isNotEmpty) _infoChip(Icons.category_outlined, course.category!),
            _infoChip(Icons.people_outline, '${course.totalStudents} students'),
            if (course.syllabus != null && course.syllabus!.isNotEmpty) _infoChip(Icons.picture_as_pdf, 'Syllabus'),
          ]),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _ratingStars(double rating) {
    return Row(mainAxisSize: MainAxisSize.min, children: List.generate(5, (i) {
      if (i < rating.floor()) return const Icon(Icons.star, size: 16, color: Colors.amber);
      if (i < rating) return const Icon(Icons.star_half, size: 16, color: Colors.amber);
      return const Icon(Icons.star_border, size: 16, color: Colors.amber);
    }));
  }

  Widget _buildTabBar() {
    final tabs = ['Overview', 'Curriculum', 'Reviews'];
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, border: Border(bottom: BorderSide(color: AppColors.textHint.withOpacity(0.2)))),
      child: Row(children: List.generate(tabs.length, (i) => Expanded(
        child: GestureDetector(
          onTap: () => setState(() { _activeTab = i; }),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _activeTab == i ? AppColors.primary : Colors.transparent, width: 2.5))),
            child: Text(tabs[i], textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _activeTab == i ? AppColors.primary : AppColors.textSecondary)),
          ),
        ),
      ))),
    );
  }

  Widget _buildOverviewTab(dynamic course) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("What you'll learn", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _learnItem('${course.totalLessons} video lectures'),
          _learnItem('Quiz after completing all lectures'),
          _learnItem('Certificate on completion'),
          const SizedBox(height: 20),
          const Text('Course Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_stripHtml(course.details), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.6)),
          if (course.requirements != null && course.requirements!.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Requirements', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(course.requirements!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.6)),
          ],
          if (course.videos.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Curriculum', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...List.generate(course.videos.length, (i) {
              final v = course.videos[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  CircleAvatar(radius: 14, backgroundColor: AppColors.primarySurface, child: Text('${i + 1}', style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold))),
                  const SizedBox(width: 10),
                  Expanded(child: Text(v['videoTitle'] ?? 'Lesson ${i + 1}', style: const TextStyle(fontSize: 13))),
                  const Icon(Icons.play_circle_outline, size: 18, color: AppColors.primary),
                ]),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _learnItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        const Icon(Icons.check_circle, size: 16, color: AppColors.success),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
      ]),
    );
  }

  // ─── ENROLLED OVERVIEW ──────────────────────────────────────
  Widget _buildEnrolledOverviewTab(dynamic course, User? user, bool isCourseComplete, bool isQuizComplete) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _ratingStars(_avgRating(course)),
            const SizedBox(width: 4),
            Text('${_avgRating(course).toStringAsFixed(1)} (${course.studentsOpinion.length} ratings)', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ]),
          const SizedBox(height: 12),
          Text(_stripHtml(course.details), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.6)),
          if (course.requirements != null && course.requirements!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Requirements', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(course.requirements!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 20),
          _buildRatingInput(course.id, user?.id),
        ],
      ),
    );
  }

  Widget _buildRatingInput(String courseId, String? userId) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Leave a Review', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(children: List.generate(5, (i) => GestureDetector(
          onTap: () => setState(() { _selectedRating = i + 1; }),
          child: Icon(i < _selectedRating ? Icons.star : Icons.star_border, size: 28, color: Colors.amber),
        ))),
        const SizedBox(height: 8),
        TextField(controller: _reviewCtrl, maxLines: 3, decoration: InputDecoration(hintText: 'Write your review...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : () => _submitReview(courseId, userId!),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: _isSubmitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Submit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ]),
    );
  }

  // ─── CURRICULUM TAB ─────────────────────────────────────────
  Widget _buildCurriculumTab(dynamic course, int unlockedVideos, bool isEnrolled) {
    final videos = course.videos;
    if (videos.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('No lessons yet'));
    final sections = _chunkList(videos, 5);

    if (_sectionExpanded.length < sections.length) {
      _sectionExpanded = List.generate(sections.length, (i) => i == 0);
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${videos.length} lectures', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          ...List.generate(sections.length, (sIdx) {
            final section = sections[sIdx];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(border: Border.all(color: AppColors.textHint.withOpacity(0.15)), borderRadius: BorderRadius.circular(10)),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => setState(() { _sectionExpanded[sIdx] = !_sectionExpanded[sIdx]; }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Section ${sIdx + 1}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          Text('${section.length} lectures', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                        ])),
                        Icon(_sectionExpanded[sIdx] ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppColors.textHint),
                      ]),
                    ),
                  ),
                  if (_sectionExpanded[sIdx])
                    ...List.generate(section.length, (vIdx) {
                      final globalIdx = sIdx * 5 + vIdx;
                      final v = section[vIdx];
                      final locked = isEnrolled && globalIdx >= unlockedVideos;
                      final isYoutube = _normalizeYoutube(v['videoLink']) != null;
                      return GestureDetector(
                        onTap: locked ? null : () => _showVideoModal(v, isYoutube),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.textHint.withOpacity(0.1)))),
                          child: Row(children: [
                            Icon(locked ? Icons.lock_outline : Icons.play_circle_outline, size: 16, color: locked ? AppColors.textHint : AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(child: Text(v['videoTitle'] ?? 'Lesson ${globalIdx + 1}', style: TextStyle(fontSize: 12, color: locked ? AppColors.textHint : AppColors.textPrimary, decoration: locked ? null : TextDecoration.underline))),
                          ]),
                        ),
                      );
                    }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── REVIEWS TAB ────────────────────────────────────────────
  Widget _buildReviewsTab(dynamic course) {
    if (course.studentsOpinion.isEmpty) {
      return const Padding(padding: EdgeInsets.all(16), child: Center(child: Text('No reviews yet', style: TextStyle(color: AppColors.textSecondary))));
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _ratingStars(_avgRating(course)),
            const SizedBox(width: 6),
            Text('${_avgRating(course).toStringAsFixed(1)} average', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 14),
          ...course.studentsOpinion.map<Widget>((op) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(10)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CircleAvatar(radius: 16, backgroundColor: AppColors.primarySurface, child: Text((op['reviewerId'] ?? '?')[0].toString().toUpperCase(), style: const TextStyle(fontSize: 12, color: AppColors.primary))),
                const SizedBox(width: 8),
                Expanded(child: Text(op['reviewerId'] ?? 'Student', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                _ratingStars(double.tryParse(op['rating']?.toString() ?? '0') ?? 0),
              ]),
              if (op['comments'] != null && (op['comments'] as String).isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(op['comments'], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ]),
          )),
        ],
      ),
    );
  }

  // ─── QUIZ SECTION ───────────────────────────────────────────
  Widget _buildQuizSection(dynamic course, User? user, bool isCourseComplete, bool isQuizComplete) {
    if (!isCourseComplete) {
      return const Padding(padding: EdgeInsets.all(24), child: Center(child: Column(children: [
        Icon(Icons.lock_outline, size: 48, color: AppColors.textHint),
        SizedBox(height: 12),
        Text('Complete all lectures to unlock the quiz', style: TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
      ])));
    }
    if (course.quiz.isEmpty) {
      return const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No quiz available')));
    }
    return _QuizWidget(course: course, userId: user?.id ?? '');
  }

  // ─── VIDEO PLAYER (Tappable Thumbnail) ──────────────────────
  Widget _buildVideoPlayer(dynamic video, bool isYoutube) {
    final url = video['videoLink'] ?? '';
    if (isYoutube) {
      final id = _extractYoutubeId(url);
      if (id == null) return const SizedBox(height: 200, child: Center(child: Text('Invalid video URL')));
      return GestureDetector(
        onTap: () => _showVideoModal(video, true),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.network(
                'https://img.youtube.com/vi/$id/maxresdefault.jpg',
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.black,
                  child: const Icon(Icons.play_circle_outline, color: Colors.white54, size: 64),
                ),
              ),
              Container(color: Colors.black26),
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 36),
              ),
            ],
          ),
        ),
      );
    }
    final videoHtml = '''
      <!DOCTYPE html>
      <html><head>
      <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
      <style>*{margin:0;padding:0;box-sizing:border-box;}body{background:#000;display:flex;justify-content:center;align-items:center;height:100vh;overflow:hidden;}
      video{width:100%;height:100%;object-fit:contain;position:absolute;top:0;left:0;}</style>
      </head><body>
      <video src="$url" controls playsinline></video>
      </body></html>''';
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        children: [
          Positioned.fill(
            child: WebViewWidget(controller: WebViewController()
              ..setJavaScriptMode(JavaScriptMode.unrestricted)
              ..setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36')
              ..setNavigationDelegate(NavigationDelegate(
                onNavigationRequest: (req) => NavigationDecision.navigate,
              ))
              ..loadHtmlString(videoHtml)),
          ),
        ],
      ),
    );
  }

  // ─── VIDEO MODAL (Full-screen direct play) ──────────────────
  void _showVideoModal(dynamic video, bool isYoutube) {
    final url = video['videoLink'] ?? '';
    final title = video['videoTitle'] ?? '';

    if (isYoutube) {
      final id = _extractYoutubeId(url);
      if (id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid video URL'), backgroundColor: AppColors.error),
        );
        return;
      }
      final html = '''
        <!DOCTYPE html>
        <html><head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <style>*{margin:0;padding:0;box-sizing:border-box;}body{background:#0F172A;display:flex;justify-content:center;align-items:center;height:100vh;overflow:hidden;}
        iframe{width:100%;height:100%;border:none;position:absolute;top:0;left:0;}</style>
        </head><body>
        <iframe src="https://www.youtube.com/embed/$id?autoplay=1&rel=0&modestbranding=1&playsinline=1&enablejsapi=1"
          allow="accelerometer;autoplay;clipboard-write;encrypted-media;gyroscope;picture-in-picture;web-share"
          allowfullscreen></iframe>
        </body></html>''';
      Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => Scaffold(
            backgroundColor: const Color(0xFF0F172A),
            appBar: AppBar(
              backgroundColor: const Color(0xFF0F172A),
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 24),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            body: WebViewWidget(controller: WebViewController()
              ..setJavaScriptMode(JavaScriptMode.unrestricted)
              ..setUserAgent(YouTubeUtils.webUserAgent)
              ..setBackgroundColor(const Color(0xFF0F172A))
              ..setNavigationDelegate(NavigationDelegate(
                onNavigationRequest: (req) {
                  final u = req.url;
                  if (u.contains('youtube.com/embed') || u.startsWith('data:')) return NavigationDecision.navigate;
                  return NavigationDecision.prevent;
                },
              ))
              ..loadHtmlString(html)),
          ),
        ),
      );
      return;
    }

    // Non-YouTube: use WebView
    final videoHtml = '''
      <!DOCTYPE html>
      <html><head>
      <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
      <style>*{margin:0;padding:0;box-sizing:border-box;}body{background:#000;display:flex;justify-content:center;align-items:center;height:100vh;overflow:hidden;}
      video{width:100%;height:100%;object-fit:contain;position:absolute;top:0;left:0;}</style>
      </head><body>
      <video src="$url" controls autoplay playsinline></video>
      </body></html>''';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(),
      builder: (ctx) {
        return SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              Positioned.fill(
                child: WebViewWidget(controller: WebViewController()
                  ..setJavaScriptMode(JavaScriptMode.unrestricted)
                  ..setUserAgent(YouTubeUtils.webUserAgent)
                  ..setBackgroundColor(const Color(0xFF0F172A))
                  ..loadHtmlString(videoHtml)),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                child: SafeArea(
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
              ),
              if (title.isNotEmpty)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 56,
                  right: 56,
                  child: SafeArea(
                    child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ─── NAV BUTTONS ────────────────────────────────────────────
  Widget _navButton(String label, bool enabled, VoidCallback onTap, {bool primary = false}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: primary ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: primary ? null : Border.all(color: AppColors.textHint.withOpacity(0.2)),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primary ? Colors.white : (enabled ? AppColors.textPrimary : AppColors.textHint))),
      ),
    );
  }

  // ─── ENROLL BOTTOM BAR ──────────────────────────────────────
  Widget _buildEnrollBottomBar(dynamic course, double finalPrice, User? user, bool isEnrolled) {
    final price = int.tryParse(course.price ?? '0') ?? 0;
    final isFree = price == 0;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: isEnrolled
            ? Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.hourglass_top, size: 18, color: AppColors.warning),
                  SizedBox(width: 8),
                  Text('Enrollment pending approval', style: TextStyle(fontSize: 14, color: AppColors.warning, fontWeight: FontWeight.w600)),
                ]),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => _enroll(course, finalPrice, user),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 4,
                        shadowColor: AppColors.primary.withOpacity(0.4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.school, color: Colors.white, size: 22),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              isFree ? 'Enroll Now (Free)' : 'Enroll Now — \u20B9${finalPrice.round()}',
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  // ─── CURRICULUM BOTTOM SHEET ────────────────────────────────
  Widget _buildCurriculumDrawer(dynamic course, List videos, int unlockedVideos, User? user) {
    return GestureDetector(
      onTap: () => setState(() { _showCurriculum = !_showCurriculum; }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.textHint.withOpacity(0.15)))),
        child: SafeArea(
          top: false,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(_showCurriculum ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up, size: 20, color: AppColors.primary),
              const SizedBox(width: 4),
              Text('Course Content (${videos.length} lectures)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
            ]),
          ]),
        ),
      ),
    );
  }

  List<List<T>> _chunkList<T>(List<T> list, int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += size) {
      chunks.add(list.sublist(i, i + size > list.length ? list.length : i + size));
    }
    return chunks;
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

// ─── QUIZ WIDGET ────────────────────────────────────────────────
class _QuizWidget extends StatefulWidget {
  final dynamic course;
  final String userId;
  const _QuizWidget({required this.course, required this.userId});

  @override
  State<_QuizWidget> createState() => _QuizWidgetState();
}

class _QuizWidgetState extends State<_QuizWidget> {
  late List<Map<String, dynamic>> _quizzes;
  bool _submitted = false;
  int _score = 0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _quizzes = widget.course.quiz.map<Map<String, dynamic>>((q) => {...q, 'selectedAnswer': null}).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quiz', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          ...List.generate(_quizzes.length, (qi) {
            final quiz = _quizzes[qi];
            final options = List<String>.from(quiz['options'] ?? []);
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(border: Border.all(color: AppColors.textHint.withOpacity(0.15)), borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${qi + 1}. ${quiz['ques'] ?? ''}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                ...List.generate(options.length, (oi) {
                  final isSelected = quiz['selectedAnswer'] == oi.toString();
                  final isCorrect = oi.toString() == quiz['ans']?.toString();
                  Color bgColor = AppColors.surface;
                  Color borderColor = AppColors.textHint.withOpacity(0.2);
                  if (_submitted && isCorrect) { bgColor = AppColors.success.withOpacity(0.1); borderColor = AppColors.success; }
                  else if (_submitted && isSelected && !isCorrect) { bgColor = AppColors.error.withOpacity(0.1); borderColor = AppColors.error; }
                  else if (isSelected) { bgColor = AppColors.primary.withOpacity(0.05); borderColor = AppColors.primary; }

                  return GestureDetector(
                    onTap: _submitted ? null : () => setState(() { _quizzes[qi]['selectedAnswer'] = oi.toString(); }),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: bgColor, border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(8)),
                      child: Row(children: [
                        Icon(_submitted && isCorrect ? Icons.check_circle : isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                          size: 18, color: _submitted && isCorrect ? AppColors.success : isSelected ? AppColors.primary : AppColors.textHint),
                        const SizedBox(width: 8),
                        Expanded(child: Text(options[oi], style: const TextStyle(fontSize: 13))),
                      ]),
                    ),
                  );
                }),
              ]),
            );
          }),
          if (!_submitted)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Submit Quiz', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          if (_submitted) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(10)),
              child: Text('Score: $_score/${_quizzes.length} (${((_score * 100) / _quizzes.length).round()}%)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary), textAlign: TextAlign.center),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _submit() async {
    int score = 0;
    for (final q in _quizzes) {
      if (q['selectedAnswer'] == q['ans']?.toString()) score++;
    }
    final pct = (score * 100) / _quizzes.length;
    if (pct < 40) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('You need at least 40%. You got ${pct.round()}%'), backgroundColor: AppColors.error));
      return;
    }
    setState(() { _loading = true; });
    try {
      final dio = ProviderContainer().read(dioClientProvider);
      await dio.patch('/api/course/completeQuiz/${widget.userId}', data: {
        '_id': widget.course.id,
        'quizMarks': score,
        'quizMarksPercentage': pct,
      });
      setState(() { _submitted = true; _score = score; _loading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Quiz completed! Score: ${pct.round()}%'), backgroundColor: AppColors.success));
        ProviderContainer().read(courseDetailProvider(widget.course.id));
      }
    } catch (e) {
      setState(() { _loading = false; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    }
  }
}

// ─── SIMPLE VIDEO PLAYER WIDGET ─────────────────────────────────
class VideoPlayerWidget extends StatelessWidget {
  final String url;
  const VideoPlayerWidget({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.play_circle_outline, size: 64, color: Colors.white54),
          const SizedBox(height: 12),
          Text('Video: ${url.split('/').last}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ]),
      ),
    );
  }
}
