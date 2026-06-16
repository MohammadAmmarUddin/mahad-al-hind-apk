class Shayekh {
  final String id;
  final String? name;
  final String? photo;
  final String? bio;
  final String? country;
  final String? specialization;
  final int? totalCourses;
  final int? totalTilawah;
  final int? followers;
  final bool? isFollowing;
  final String? facebook;
  final String? twitter;
  final String? youtube;
  final String? instagram;

  const Shayekh({
    required this.id,
    this.name,
    this.photo,
    this.bio,
    this.country,
    this.specialization,
    this.totalCourses,
    this.totalTilawah,
    this.followers,
    this.isFollowing = false,
    this.facebook,
    this.twitter,
    this.youtube,
    this.instagram,
  });

  factory Shayekh.fromJson(Map<String, dynamic> json) {
    return Shayekh(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] as String?,
      photo: json['photo'] as String?,
      bio: json['bio'] as String?,
      country: json['country'] as String?,
      specialization: json['specialization'] as String?,
      totalCourses: json['totalCourses'] as int?,
      totalTilawah: json['totalTilawah'] as int?,
      followers: json['followers'] as int?,
      isFollowing: json['isFollowing'] as bool? ?? false,
      facebook: json['facebook'] as String?,
      twitter: json['twitter'] as String?,
      youtube: json['youtube'] as String?,
      instagram: json['instagram'] as String?,
    );
  }
}
