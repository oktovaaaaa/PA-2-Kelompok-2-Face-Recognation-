import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../storage/session_storage.dart';
import 'api_response.dart';

class ApiClient {
  static Future<ApiResponse> get(String path) async {
    final token = await SessionStorage.getToken();

    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );

    final decoded = jsonDecode(response.body);
    return ApiResponse.fromJson(decoded);
  }

  static Future<ApiResponse> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final token = await SessionStorage.getToken();

    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    final decoded = jsonDecode(response.body);
    return ApiResponse.fromJson(decoded);
  }

  static Future<ApiResponse> put(
    String path,
    Map<String, dynamic> body,
  ) async {
    final token = await SessionStorage.getToken();

    final response = await http.put(
      Uri.parse('${AppConstants.baseUrl}$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    final decoded = jsonDecode(response.body);
    return ApiResponse.fromJson(decoded);
  }
}