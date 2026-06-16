import 'package:flutter/material.dart';

extension StringExtension on String {
  String get capitalize => '${this[0].toUpperCase()}${substring(1)}';

  String get capitalizeWords => split(' ').map((e) => e.capitalize).join(' ');

  bool get isValidEmail =>
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);

  bool get isValidPassword =>
      length >= 8 && contains(RegExp(r'[A-Z]')) && contains(RegExp(r'[0-9]'));

  String truncate(int maxLength) =>
      length > maxLength ? '${substring(0, maxLength)}...' : this;

  String get toTitleCase => split(' ').map((e) => e.capitalize).join(' ');

  String formatDuration() {
    final parts = split(':');
    if (parts.length == 2) {
      final minutes = int.tryParse(parts[0]) ?? 0;
      final seconds = int.tryParse(parts[1]) ?? 0;
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return this;
  }
}

extension DateTimeExtension on DateTime {
  String get timeAgo {
    final diff = DateTime.now().difference(this);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 7) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  String get toFormattedDate => '$day/$month/$year';

  String get toFormattedDateTime =>
      '$day/$month/$year ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  bool get isToday =>
      year == DateTime.now().year &&
      month == DateTime.now().month &&
      day == DateTime.now().day;
}

extension BuildContextExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  double get screenHeight => mediaQuery.size.height;
  double get screenWidth => mediaQuery.size.width;
  bool get isDarkMode => theme.brightness == Brightness.dark;

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void hideKeyboard() => FocusScope.of(this).unfocus();
}

extension DoubleExtension on double {
  String get toFixed2 => toStringAsFixed(2);

  String get toCurrency => '\$$toStringAsFixed(2)';
}

extension ListExtension<T> on List<T> {
  List<T> separate(T separator) {
    final list = <T>[];
    for (var i = 0; i < length; i++) {
      list.add(this[i]);
      if (i < length - 1) list.add(separator);
    }
    return list;
  }
}
