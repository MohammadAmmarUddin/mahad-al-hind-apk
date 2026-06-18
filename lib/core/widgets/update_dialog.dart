import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/app_colors.dart';
import '../models/app_update_config.dart';
import '../services/update_service.dart';

class UpdateDialog extends StatefulWidget {
  final AppUpdateConfig config;
  final VoidCallback? onLater;

  const UpdateDialog({super.key, required this.config, this.onLater});

  static Future<void> show(BuildContext context, AppUpdateConfig config,
      {VoidCallback? onLater}) {
    return showDialog(
      context: context,
      barrierDismissible: !config.forceUpdate,
      builder: (_) => PopScope(
        canPop: !config.forceUpdate,
        child: UpdateDialog(config: config, onLater: onLater),
      ),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  double _progress = 0;
  bool _downloading = false;
  bool _downloadComplete = false;
  String? _error;
  CancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim =
        Tween<double>(begin: 1, end: 1.05).animate(_pulseController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _cancelToken?.cancel();
    super.dispose();
  }

  void _dismiss() {
    Navigator.of(context).pop();
    widget.onLater?.call();
  }

  Future<void> _downloadAndInstall() async {
    if (_downloading || widget.config.apkUrl.isEmpty) return;

    setState(() {
      _downloading = true;
      _progress = 0;
      _error = null;
    });

    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/app-update.apk';
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
      }

      _cancelToken = CancelToken();
      final dio = Dio();
      await dio.download(
        widget.config.apkUrl,
        filePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() => _progress = received / total);
          }
        },
      );

      if (!mounted) return;

      setState(() {
        _downloading = false;
        _downloadComplete = true;
        _progress = 1;
      });

      final result = await OpenFilex.open(filePath,
          type: 'application/vnd.android.package-archive');

      if (result.type == ResultType.done) {
        // Record that update was successfully initiated — next launch will be post-update
        await UpdateService.recordUpdateCompleted();
      }

      if (result.type != ResultType.done && mounted) {
        setState(() {
          _error = 'Could not open installer: ${result.message}';
          _downloadComplete = false;
        });
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) return;
      if (mounted) {
        setState(() {
          _error = 'Download failed: ${e.message}';
          _downloading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error: $e';
          _downloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final notes = config.releaseNotes
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B7A3D), Color(0xFF0E5C28)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (!config.forceUpdate)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: _dismiss,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white.withOpacity(0.8),
                      size: 20,
                    ),
                  ),
                ),
              ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 140,
                      decoration: const BoxDecoration(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(24)),
                        color: Colors.white10,
                      ),
                    ),
                    Positioned(
                      top: -10,
                      child: AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, child) => Transform.scale(
                            scale: _pulseAnim.value, child: child),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFD4AF37), Color(0xFFE8C84A)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFD4AF37).withOpacity(0.4),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: _downloading
                              ? Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: CircularProgressIndicator(
                                    value: _progress,
                                    strokeWidth: 4,
                                    color: Colors.white,
                                    backgroundColor:
                                        Colors.white.withOpacity(0.2),
                                  ),
                                )
                              : _downloadComplete
                                  ? const Icon(Icons.check_rounded,
                                      color: Colors.white, size: 40)
                                  : const Icon(Icons.system_update_rounded,
                                      color: Colors.white, size: 40),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: config.forceUpdate
                              ? AppColors.error.withOpacity(0.9)
                              : const Color(0xFFD4AF37).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              config.forceUpdate
                                  ? Icons.warning_amber_rounded
                                  : Icons.new_releases_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              config.forceUpdate
                                  ? 'REQUIRED UPDATE'
                                  : 'NEW VERSION',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        _downloadComplete
                            ? 'Download Complete'
                            : 'Update Available',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'v${config.latestVersion}',
                          style: const TextStyle(
                              color: Color(0xFFD4AF37),
                              fontSize: 13,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (_downloading) ...[
                        const SizedBox(height: 16),
                        Text(
                          '${(_progress * 100).toInt()}%',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: _progress,
                              minHeight: 6,
                              backgroundColor: Colors.transparent,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFFD4AF37)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Downloading update...',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _error!,
                            style: const TextStyle(
                                color: Colors.redAccent, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                      if (!_downloading &&
                          !_downloadComplete &&
                          notes.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "What's New",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              ...notes.map((n) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('• ',
                                            style: TextStyle(
                                                color: Color(0xFFD4AF37),
                                                fontSize: 12)),
                                        Expanded(
                                          child: Text(
                                            n,
                                            style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _downloading
                              ? null
                              : _downloadComplete
                                  ? null
                                  : _downloadAndInstall,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _downloadComplete
                                ? Colors.green
                                : const Color(0xFFD4AF37),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 4,
                            disabledBackgroundColor:
                                _downloadComplete ? Colors.green : Colors.white24,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _downloadComplete
                                    ? Icons.check_circle_rounded
                                    : Icons.download_rounded,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _downloadComplete
                                    ? 'Installed! Open from installer'
                                    : 'Update Now',
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
