import '../../domain/entities/course.dart';
import '../../domain/entities/course_category.dart';
import '../datasources/courses_remote_datasource.dart';
import '../../../../core/storage/hive_storage.dart';

class CoursesRepositoryImpl {
  final CoursesRemoteDataSource _remoteDataSource;
  CoursesRepositoryImpl({required CoursesRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  Future<List<Course>> getAllCourses({int page = 1, String? category, String? search}) async {
    try {
      final courses = await _remoteDataSource.getAllCourses(page: page, category: category, search: search);
      await HiveStorage.cacheData('courses_all', courses.map((c) => c.toJson()).toList(), expiry: const Duration(hours: 2));
      return courses;
    } catch (e) {
      final cached = HiveStorage.getCachedData('courses_all');
      if (cached != null) {
        return (cached as List).map((e) => Course.fromJson(Map<String, dynamic>.from(e))).toList();
      }
      rethrow;
    }
  }

  Future<Course> getSingleCourse(String id) async {
    try {
      final course = await _remoteDataSource.getSingleCourse(id);
      await HiveStorage.cacheData('course_$id', course.toJson(), expiry: const Duration(hours: 2));
      return course;
    } catch (e) {
      final cached = HiveStorage.getCachedData('course_$id');
      if (cached != null) return Course.fromJson(Map<String, dynamic>.from(cached));
      rethrow;
    }
  }

  Future<List<Course>> getRelatedCourses(String courseId) async {
    try {
      return await _remoteDataSource.getRelatedCourses(courseId);
    } catch (_) {
      return [];
    }
  }

  Future<List<CourseCategory>> getCourseCategories() async {
    try {
      final categories = await _remoteDataSource.getCourseCategories();
      await HiveStorage.cacheData('course_categories', categories.map((c) => {'_id': c.id, 'name': c.name}).toList(), expiry: const Duration(hours: 6));
      return categories;
    } catch (e) {
      final cached = HiveStorage.getCachedData('course_categories');
      if (cached != null) {
        return (cached as List).map((e) => CourseCategory.fromJson(Map<String, dynamic>.from(e))).toList();
      }
      rethrow;
    }
  }
}
