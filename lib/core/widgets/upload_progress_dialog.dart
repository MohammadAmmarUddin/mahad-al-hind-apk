import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/providers/core_providers.dart';

class UploadProgressDialog extends ConsumerStatefulWidget {
  final File file;
  final String folder;
  final void Function(String url) onSuccess;
  final void Function(String error) onError;

  const UploadProgressDialog({
    super.key,
    required this.file,
    required this.folder,
    required this.onSuccess,
    required this.onError,
  });

  static Future<void> show(
    BuildContext context, {
    required File file,
    required String folder,
    required void Function(String url) onSuccess,
    required void Function(String error) onError,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => UploadProgressDialog(
        file: file,
        folder: folder,
        onSuccess: onSuccess,
        onError: onError,
      ),
    );
  }

  @override
  ConsumerState<UploadProgressDialog> createState() => _UploadProgressDialogState();
}

class _UploadProgressDialogState extends ConsumerState<UploadProgressDialog>
    with SingleTickerProviderStateMixin {
  double _progress = 0;
  bool _uploading = true;
  bool _done = false;
  String? _error;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _startUpload();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startUpload() async {
    try {
      final result = await ref.read(fileUploadServiceProvider).uploadToCloudinary(
        widget.file,
        folder: widget.folder,
        onProgress: (sent, total) {
          if (total > 0 && mounted) {
            setState(() { _progress = sent / total; });
          }
        },
      );
      if (result != null && mounted) {
        setState(() { _done = true; _uploading = false; });
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          Navigator.of(context).pop();
          widget.onSuccess(result.url);
        }
      } else if (mounted) {
        setState(() { _error = 'Upload failed'; _uploading = false; });
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().contains('Exception:')
            ? e.toString().replaceFirst('Exception: ', '')
            : 'Upload failed';
        setState(() { _error = msg; _uploading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final percent = (_progress * 100).toInt();
    final fileName = widget.file.path.split(Platform.pathSeparator).last;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_uploading) ...[
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (_, __) {
                        return Container(
                          width: 120 + (_pulseController.value * 8),
                          height: 120 + (_pulseController.value * 8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withOpacity(0.05 + _pulseController.value * 0.05),
                          ),
                        );
                      },
                    ),
                    SizedBox(
                      width: 110,
                      height: 110,
                      child: CircularProgressIndicator(
                        value: _progress > 0 ? _progress : null,
                        strokeWidth: 6,
                        backgroundColor: AppColors.primary.withOpacity(0.12),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                  ],
                  if (_done) ...[
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.success.withOpacity(0.1),
                      ),
                      child: const Icon(Icons.check_rounded, color: AppColors.success, size: 56),
                    ),
                  ],
                  if (_error != null) ...[
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.error.withOpacity(0.1),
                      ),
                      child: const Icon(Icons.close_rounded, color: AppColors.error, size: 56),
                    ),
                  ],
                  if (_uploading && _progress > 0)
                    Text(
                      '$percent%',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  if (_uploading && _progress == 0)
                    Text(
                      '...',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_uploading) ...[
              Text(
                _progress > 0 ? 'Uploading...' : 'Preparing...',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                fileName,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
            if (_done) ...[
              const Text(
                'Upload Complete!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.success),
              ),
              const SizedBox(height: 6),
              Text(
                fileName,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
            if (_error != null) ...[
              Text(
                'Upload Failed',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.error),
              ),
              const SizedBox(height: 6),
              Text(
                _error!,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      setState(() { _error = null; _uploading = true; _progress = 0; });
                      _startUpload();
                    },
                    style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
