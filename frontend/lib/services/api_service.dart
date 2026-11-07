import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../config.dart';

class ApiException implements Exception {
  final int? status;
  final String message;
  final Map<String, String> fieldErrors;
  ApiException(this.message, {this.status, this.fieldErrors = const {}});
  @override
  String toString() => message;
}

class ApiService {
  static const _timeout = Duration(seconds: 15);
  static const _json = {'Content-Type': 'application/json'};

  Uri _u(String path) => Uri.parse('${AppConfig.apiBaseUrl}$path');

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String phone,
    String? email,
    required String password,
    required String confirmPassword,
    required String preferredLanguage,
    required bool consent,
  }) =>
      _send(() => http.post(
            _u('/auth/register'),
            headers: _json,
            body: jsonEncode({
              'fullName': fullName,
              'phone': phone,
              if (email != null && email.isNotEmpty) 'email': email,
              'password': password,
              'confirmPassword': confirmPassword,
              'preferredLanguage': preferredLanguage,
              'consent': consent,
            }),
          ));

  Future<Map<String, dynamic>> login(String identifier, String password) =>
      _send(() => http.post(
            _u('/auth/login'),
            headers: _json,
            body: jsonEncode({'identifier': identifier, 'password': password}),
          ));

  Future<Map<String, dynamic>> me(String token) =>
      _send(() => http.get(_u('/auth/me'), headers: {'Authorization': 'Bearer $token'}));

  Future<void> deleteAccount(String token) async {
    await _send(() => http.delete(_u('/auth/me'), headers: {'Authorization': 'Bearer $token'}));
  }

  Future<Map<String, dynamic>> _send(Future<http.Response> Function() call) async {
    try {
      final res = await call().timeout(_timeout);
      final body = res.body.isEmpty ? <String, dynamic>{} : jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode >= 200 && res.statusCode < 300) return body;
      final errs = <String, String>{};
      if (body['errors'] is Map) {
        (body['errors'] as Map).forEach((k, v) => errs[k.toString()] = v.toString());
      }
      throw ApiException(body['message']?.toString() ?? 'Request failed',
          status: res.statusCode, fieldErrors: errs);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('network');
    } on http.ClientException {
      throw ApiException('network');
    } on FormatException {
      throw ApiException('Unexpected server response');
    }
  }
}
