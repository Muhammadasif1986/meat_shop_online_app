class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;

  ApiResponse({required this.success, this.data, this.message});

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic)? fromData) {
    return ApiResponse(
      success: json['success'] as bool? ?? false,
      data: json['data'] != null && fromData != null ? fromData(json['data']) : null,
      message: json['message'] as String?,
    );
  }
}

class PaginatedResponse<T> {
  final List<T> items;
  final int total;
  final int page;
  final int perPage;

  PaginatedResponse({required this.items, required this.total, required this.page, required this.perPage});

  factory PaginatedResponse.fromJson(Map<String, dynamic> json, T Function(dynamic) fromItem) {
    return PaginatedResponse(
      items: (json['items'] as List?)?.map((e) => fromItem(e)).toList() ?? [],
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      perPage: json['per_page'] as int? ?? 20,
    );
  }
}
