import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/course.dart';
import '../../domain/entities/course_category.dart';
import '../../data/datasources/courses_remote_datasource.dart';
import '../../data/repositories/courses_repository_impl.dart';
import '../../../../shared/providers/core_providers.dart';

final coursesDataSourceProvider = Provider<CoursesRemoteDataSource>((ref) {
  return CoursesRemoteDataSourceImpl(dioClient: ref.read(dioClientProvider));
});

final coursesRepositoryProvider = Provider<CoursesRepositoryImpl>((ref) {
  return CoursesRepositoryImpl(remoteDataSource: ref.read(coursesDataSourceProvider));
});

final coursesListProvider = FutureProvider<List<Course>>((ref) async {
  return ref.read(coursesRepositoryProvider).getAllCourses();
});

final courseCategoriesProvider = FutureProvider<List<CourseCategory>>((ref) async {
  return ref.read(coursesRepositoryProvider).getCourseCategories();
});

final courseDetailProvider = FutureProvider.family<Course, String>((ref, id) async {
  return ref.read(coursesRepositoryProvider).getSingleCourse(id);
});

final relatedCoursesProvider = FutureProvider.family<List<Course>, String>((ref, id) async {
  return ref.read(coursesRepositoryProvider).getRelatedCourses(id);
});

final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

final filteredCoursesProvider = FutureProvider<List<Course>>((ref) async {
  final search = ref.watch(searchQueryProvider);
  final category = ref.watch(selectedCategoryProvider);
  final allCourses = await ref.read(coursesRepositoryProvider).getAllCourses();
  var filtered = allCourses;
  if (category != null && category.isNotEmpty) {
    filtered = filtered.where((c) => c.category == category).toList();
  }
  if (search.isNotEmpty) {
    final q = search.toLowerCase();
    filtered = filtered.where((c) =>
      (c.title?.toLowerCase().contains(q) ?? false) ||
      (c.category?.toLowerCase().contains(q) ?? false) ||
      (c.magnetLine?.toLowerCase().contains(q) ?? false)
    ).toList();
  }
  return filtered;
});
