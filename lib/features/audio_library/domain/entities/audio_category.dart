import 'package:flutter/material.dart';

class AudioCategory {
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final int? trackCount;

  const AudioCategory({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.trackCount,
  });

  factory AudioCategory.fromJson(Map<String, dynamic> json) {
    return AudioCategory(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      trackCount: json['trackCount'] as int?,
    );
  }

  IconData get iconData {
    switch (name.toLowerCase()) {
      case 'tilawah': return Icons.menu_book;
      case 'azaan': return Icons.volume_up;
      case 'bayan': return Icons.mic;
      case 'nasheed': return Icons.music_note;
      case 'dars': return Icons.school;
      case 'lectures': return Icons.record_voice_over;
      default: return Icons.headphones;
    }
  }
}
