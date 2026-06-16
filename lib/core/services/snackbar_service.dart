import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class SnackbarService {
  static final SnackbarService _instance = SnackbarService._internal();
  factory SnackbarService() => _instance;
  SnackbarService._internal();

  GlobalKey<ScaffoldMessengerState>? _scaffoldKey;

  void init(GlobalKey<ScaffoldMessengerState> key) {
    _scaffoldKey = key;
  }

  void showSuccess(String message) {
    _show(message, AppColors.success, Icons.check_circle);
  }

  void showError(String message) {
    _show(message, AppColors.error, Icons.error_outline);
  }

  void showInfo(String message) {
    _show(message, AppColors.info, Icons.info_outline);
  }

  void showWarning(String message) {
    _show(message, AppColors.warning, Icons.warning_amber);
  }

  void _show(String message, Color color, IconData icon) {
    if (_scaffoldKey?.currentState == null) return;
    _scaffoldKey!.currentState!.hideCurrentSnackBar();
    _scaffoldKey!.currentState!.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
