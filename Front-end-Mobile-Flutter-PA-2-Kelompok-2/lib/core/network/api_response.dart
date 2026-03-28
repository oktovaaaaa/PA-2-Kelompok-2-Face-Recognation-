// lib/core/network/api_response.dart
class ApiResponse {
  final bool status;
  final String message;
  final dynamic data;

  ApiResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      status: json['status'] == true,
      message: (json['message'] ?? '').toString(),
      data: json['data'],
    );
  }
}