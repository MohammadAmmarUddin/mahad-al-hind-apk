import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class Helpers {
  static String formatDate(DateTime date, {String format = 'dd MMM yyyy'}) {
    return DateFormat(format).format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  static String formatCurrency(double amount) {
    return NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(amount);
  }

  static String formatNumber(int number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toString();
  }

  static String getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isNotEmpty) return parts[0][0].toUpperCase();
    return '';
  }

  static Color getColorFromString(String text) {
    final colors = [
      Colors.teal,
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
      Colors.green,
    ];
    return colors[text.hashCode.abs() % colors.length];
  }

  static Duration parseDuration(String duration) {
    final parts = duration.split(':');
    if (parts.length == 3) {
      return Duration(
        hours: int.parse(parts[0]),
        minutes: int.parse(parts[1]),
        seconds: int.parse(parts[2]),
      );
    } else if (parts.length == 2) {
      return Duration(
        minutes: int.parse(parts[0]),
        seconds: int.parse(parts[1]),
      );
    }
    return Duration.zero;
  }

  static String durationToString(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) return '$hours:$minutes:$seconds';
    return '$minutes:$seconds';
  }

  static Future<void> launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static Future<void> launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  static Future<void> launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  static void showCustomDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool isDismissible = true,
  }) {
    showDialog(
      context: context,
      barrierDismissible: isDismissible,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          if (cancelText != null)
            TextButton(
              onPressed: onCancel ?? () => Navigator.pop(context),
              child: Text(cancelText),
            ),
          if (confirmText != null)
            ElevatedButton(
              onPressed: onConfirm ?? () => Navigator.pop(context),
              child: Text(confirmText),
            ),
        ],
      ),
    );
  }

  static String getEmptyStateMessage(String feature) {
    switch (feature) {
      case 'courses':
        return 'No courses available yet. Check back soon!';
      case 'videos':
        return 'No videos available yet.';
      case 'audio':
        return 'No audio content available yet.';
      case 'gallery':
        return 'Gallery is empty.';
      case 'notifications':
        return 'No notifications yet.';
      case 'certificates':
        return 'No certificates earned yet.';
      default:
        return 'No data available.';
    }
  }
}
