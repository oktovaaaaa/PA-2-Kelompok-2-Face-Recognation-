import 'dart:convert';
import 'dart:io';
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

  static Future<ApiResponse> delete(String path) async {
    final token = await SessionStorage.getToken();

    final response = await http.delete(
      Uri.parse('${AppConstants.baseUrl}$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );

    final decoded = jsonDecode(response.body);
    return ApiResponse.fromJson(decoded);
  }

  /// Upload file (foto izin/profil/logo) ke backend.
  /// Returns ApiResponse dengan data.url = path file di server.
  static Future<ApiResponse> uploadFile(File file) async {
    final token = await SessionStorage.getToken();

    final uri = Uri.parse('${AppConstants.baseUrl}/upload');
    final request = http.MultipartRequest('POST', uri);

    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    final decoded = jsonDecode(response.body);
    return ApiResponse.fromJson(decoded);
  }
}