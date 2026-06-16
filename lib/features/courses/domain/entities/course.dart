class Course {
  final String id;
  final String? userId;
  final String? title;
  final String? magnetLine;
  final String? details;
  final String? requirements;
  final String? whatsappGroupLink;
  final List<String> instructorsId;
  final String? banner;
  final String? category;
  final String? subCategory;
  final String? syllabus;
  final List<String> keywords;
  final String? price;
  final String? discount;
  final List<Map<String, dynamic>> videos;
  final List<Map<String, dynamic>> quiz;
  final List<Map<String, dynamic>> students;
  final List<Map<String, dynamic>> studentsOpinion;
  final String? createdAt;
  final String? updatedAt;

  const Course({
    required this.id,
    this.userId,
    this.title,
    this.magnetLine,
    this.details,
    this.requirements,
    this.whatsappGroupLink,
    this.instructorsId = const [],
    this.banner,
    this.category,
    this.subCategory,
    this.syllabus,
    this.keywords = const [],
    this.price,
    this.discount,
    this.videos = const [],
    this.quiz = const [],
    this.students = const [],
    this.studentsOpinion = const [],
    this.createdAt,
    this.updatedAt,
  });

  int get totalStudents => students.length;
  int get totalLessons => videos.length;

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['_id']?.toString() ?? '',
      userId: json['userId']?.toString(),
      title: json['title'] as String?,
      magnetLine: json['magnetLine'] as String?,
      details: json['details'] as String?,
      requirements: json['requirements'] as String?,
      whatsappGroupLink: json['whatsappGroupLink'] as String?,
      instructorsId: (json['instructorsId'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      banner: json['banner'] as String?,
      category: json['category'] as String?,
      subCategory: json['subCategory'] as String?,
      syllabus: json['syllabus'] as String?,
      keywords: (json['keywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      price: json['price']?.toString(),
      discount: json['discount']?.toString(),
      videos: (json['videos'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      quiz: (json['quiz'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      students: (json['students'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      studentsOpinion: (json['studentsOpinion'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'title': title,
      'magnetLine': magnetLine,
      'details': details,
      'requirements': requirements,
      'whatsappGroupLink': whatsappGroupLink,
      'instructorsId': instructorsId,
      'banner': banner,
      'category': category,
      'subCategory': subCategory,
      'syllabus': syllabus,
      'keywords': keywords,
      'price': price,
      'discount': discount,
      'videos': videos,
      'quiz': quiz,
      'students': students,
      'studentsOpinion': studentsOpinion,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
