class HomeData {
  final List<dynamic> topCourses;
  final List<dynamic> reviews;
  final List<dynamic> videos;
  final List<dynamic> gallery;
  final Map<String, dynamic>? siteContent;
  final Map<String, dynamic>? siteSettings;
  final List<dynamic> shayekhs;
  final List<dynamic> categories;

  const HomeData({
    this.topCourses = const [],
    this.reviews = const [],
    this.videos = const [],
    this.gallery = const [],
    this.siteContent,
    this.siteSettings,
    this.shayekhs = const [],
    this.categories = const [],
  });
}
