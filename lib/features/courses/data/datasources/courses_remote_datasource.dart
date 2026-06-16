import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/course.dart';
import '../../domain/entities/course_category.dart';

abstract class CoursesRemoteDataSource {
  Future<List<Course>> getAllCourses({int page = 1, String? category, String? search});
  Future<Course> getSingleCourse(String id);
  Future<List<Course>> getRelatedCourses(String courseId);
  Future<List<CourseCategory>> getCourseCategories();
}

class CoursesRemoteDataSourceImpl implements CoursesRemoteDataSource {
  final DioClient _dioClient;
  CoursesRemoteDataSourceImpl({required DioClient dioClient}) : _dioClient = dioClient;

  List<dynamic> _extractList(dynamic response) {
    if (response is List) return response;
    if (response is Map) {
      if (response['data'] is List) return response['data'] as List;
    }
    return [];
  }

  @override
  Future<List<Course>> getAllCourses({int page = 1, String? category, String? search}) async {
    final queryParams = <String, dynamic>{};
    if (category != null) queryParams['category'] = category;
    if (search != null) queryParams['search'] = search;
    final response = await _dioClient.get(ApiEndpoints.getAllCourses, queryParameters: queryParams);
    final data = _extractList(response.data);
    return data.map((e) => Course.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  @override
  Future<Course> getSingleCourse(String id) async {
    final response = await _dioClient.get(ApiEndpoints.singleCourse(id));
    final data = response.data;
    if (data is Map && data['data'] is Map) {
      return Course.fromJson(Map<String, dynamic>.from(data['data']));
    }
    if (data is Map && data['_id'] != null) {
      return Course.fromJson(Map<String, dynamic>.from(data));
    }
    throw Exception('Failed to parse course');
  }

  @override
  Future<List<Course>> getRelatedCourses(String courseId) async {
    final response = await _dioClient.get(ApiEndpoints.relatedCourses, queryParameters: {'courseId': courseId});
    final data = _extractList(response.data);
    return data.map((e) => Course.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  @override
  Future<List<CourseCategory>> getCourseCategories() async {
    final response = await _dioClient.get(ApiEndpoints.courseCategories);
    final data = _extractList(response.data);
    return data.map((e) => CourseCategory.fromJson(Map<String, dynamic>.from(e))).toList();
  }
}
