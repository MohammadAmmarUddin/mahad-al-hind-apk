import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/constants/app_colors.dart';

class MediaPlayerPage extends StatelessWidget {
  const MediaPlayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Media Player', style: TextStyle(color: Colors.white)),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_outline, color: Colors.white54, size: 80),
            SizedBox(height: 16),
            Text('No media selected', style: TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}
