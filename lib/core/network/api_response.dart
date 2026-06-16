class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;

  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic) fromJsonT) {
    return ApiResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] != null ? fromJsonT(json['data']) : null,
    );
  }
}

class PaginatedResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final int? total;
  final int? page;
  final int? limit;
  final bool? hasMore;

  const PaginatedResponse({
    required this.success,
    required this.message,
    this.data,
    this.total,
    this.page,
    this.limit,
    this.hasMore,
  });

  factory PaginatedResponse.fromJson(Map<String, dynamic> json, T Function(dynamic) fromJsonT) {
    return PaginatedResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      total: json['total'] as int?,
      page: json['page'] as int?,
      limit: json['limit'] as int?,
      hasMore: json['hasMore'] as bool?,
    );
  }
}
