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
  try {
    return await ref.read(coursesRepositoryProvider).getAllCourses();
  } catch (_) {
    return [];
  }
});

final courseCategoriesProvider = FutureProvider<List<CourseCategory>>((ref) async {
  try {
    return await ref.read(coursesRepositoryProvider).getCourseCategories();
  } catch (_) {
    return [];
  }
});

final courseDetailProvider = FutureProvider.family<Course, String>((ref, id) async {
  try {
    return await ref.read(coursesRepositoryProvider).getSingleCourse(id);
  } catch (_) {
    return Course(id: id);
  }
});

final relatedCoursesProvider = FutureProvider.family<List<Course>, String>((ref, id) async {
  try {
    return await ref.read(coursesRepositoryProvider).getRelatedCourses(id);
  } catch (_) {
    return [];
  }
});

final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

final filteredCoursesProvider = FutureProvider<List<Course>>((ref) async {
  try {
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
  } catch (_) {
    return [];
  }
});
