class User {
  final String id;
  final String? firstname;
  final String? lastname;
  final String? email;
  final String? phone;
  final String? photo;
  final String? role;
  final String? batch;
  final String? address;
  final String? city;
  final String? country;
  final String? gender;
  final String? birthday;
  final String? location;
  final bool? isActive;
  final String? createdAt;
  final String? updatedAt;

  String get name => '${firstname ?? ''} ${lastname ?? ''}'.trim();
  String get displayName => name.isNotEmpty ? name : (email ?? '');
  bool get hasStudentAccess => role == 'admin' || role == 'student';

  const User({
    required this.id,
    this.firstname,
    this.lastname,
    this.email,
    this.phone,
    this.photo,
    this.role,
    this.batch,
    this.address,
    this.city,
    this.country,
    this.gender,
    this.birthday,
    this.location,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final rawRole = json['role'] as String? ?? 'user';
    String normalizedRole;
    final lower = rawRole.toLowerCase();
    if (lower == 'admin' || lower == 'administrator') {
      normalizedRole = 'admin';
    } else if (lower == 'teacher') {
      normalizedRole = 'teacher';
    } else if (lower == 'student') {
      normalizedRole = 'student';
    } else {
      normalizedRole = 'user';
    }
    return User(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      firstname: json['firstname'] as String?,
      lastname: json['lastname'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      photo: json['img'] as String? ?? json['photo'] as String?,
      role: normalizedRole,
      batch: json['batch'] as String?,
      address: json['address'] as String? ?? json['location'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      gender: json['gender'] as String?,
      birthday: json['birthday'] as String?,
      location: json['location'] as String?,
      isActive: json['isSuspended'] != null ? !(json['isSuspended'] as bool) : json['isActive'] as bool?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id, 'firstname': firstname, 'lastname': lastname,
    'email': email, 'phone': phone, 'img': photo, 'role': role, 'batch': batch,
    'location': address, 'city': city, 'country': country,
    'gender': gender, 'birthday': birthday,
    'isSuspended': isActive != null ? !isActive! : null,
    'createdAt': createdAt, 'updatedAt': updatedAt,
  };
}
