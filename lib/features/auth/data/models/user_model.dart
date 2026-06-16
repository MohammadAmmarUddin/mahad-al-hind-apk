import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    super.firstname,
    super.lastname,
    super.email,
    super.phone,
    super.photo,
    super.role,
    super.batch,
    super.address,
    super.city,
    super.country,
    super.gender,
    super.birthday,
    super.location,
    super.isActive,
    super.createdAt,
    super.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
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
    return UserModel(
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

  factory UserModel.fromEntity(User user) => UserModel(
    id: user.id,
    firstname: user.firstname,
    lastname: user.lastname,
    email: user.email,
    phone: user.phone,
    photo: user.photo,
    role: user.role,
    batch: user.batch,
    address: user.address,
    city: user.city,
    country: user.country,
    gender: user.gender,
    birthday: user.birthday,
    location: user.location,
    isActive: user.isActive,
    createdAt: user.createdAt,
    updatedAt: user.updatedAt,
  );
}
