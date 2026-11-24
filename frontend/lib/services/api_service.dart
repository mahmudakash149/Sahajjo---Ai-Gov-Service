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

  Future<Map<String, dynamic>> sendOtp(String phone) =>
      _send(() => http.post(
            _u('/auth/otp/send'),
            headers: _json,
            body: jsonEncode({'phone': phone}),
          ));

  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) =>
      _send(() => http.post(
            _u('/auth/otp/verify'),
            headers: _json,
            body: jsonEncode({'phone': phone, 'otp': otp}),
          ));

  // Password Reset / Change Password APIs
  Future<Map<String, dynamic>> verifyResetOtp(String phone, String otp) =>
      _send(() => http.post(
            _u('/auth/reset-password/verify-otp'),
            headers: _json,
            body: jsonEncode({'phone': phone, 'otp': otp}),
          ));

  Future<Map<String, dynamic>> resetPassword({
    required String phone,
    String? resetToken,
    String? otp,
    required String newPassword,
    required String confirmPassword,
  }) =>
      _send(() => http.post(
            _u('/auth/reset-password'),
            headers: _json,
            body: jsonEncode({
              'phone': phone,
              if (resetToken != null) 'resetToken': resetToken,
              if (otp != null) 'otp': otp,
              'newPassword': newPassword,
              'confirmPassword': confirmPassword,
            }),
          ));

  Future<Map<String, dynamic>> me(String token) =>
      _send(() => http.get(_u('/auth/me'), headers: {'Authorization': 'Bearer $token'}));

  Future<Map<String, dynamic>> services(String token, String query) => _send(() => http.get(
        _u('/services').replace(queryParameters: {if (query.isNotEmpty) 'q': query}),
        headers: {'Authorization': 'Bearer $token'},
      ));

  // FR4: Citizen Service Request
  Future<Map<String, dynamic>> submitServiceRequest(String token, String requestText, {String? language}) =>
      _send(() => http.post(
            _u('/requests'),
            headers: {..._json, 'Authorization': 'Bearer $token'},
            body: jsonEncode({
              'requestText': requestText,
              if (language != null) 'language': language,
            }),
          ));

  Future<List<Map<String, dynamic>>> getMyServiceRequests(String token) async {
    final res = await _send(() => http.get(
          _u('/requests/my'),
          headers: {'Authorization': 'Bearer $token'},
        ));
    return (res['requests'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> deleteAccount(String token) async {
    await _send(() => http.delete(_u('/auth/me'), headers: {'Authorization': 'Bearer $token'}));
  }

  // FR11-FR15: Document Upload, S3 Presigned URLs, OCR & Readiness
  Future<Map<String, dynamic>> presignDocumentUpload(
    String token, {
    required String requestId,
    required String docType,
    required String fileName,
    required String mimeType,
  }) =>
      _send(() => http.post(
            _u('/documents/presign'),
            headers: {..._json, 'Authorization': 'Bearer $token'},
            body: jsonEncode({
              'requestId': requestId,
              'docType': docType,
              'fileName': fileName,
              'mimeType': mimeType,
            }),
          ));

  Future<Map<String, dynamic>> confirmDocumentUpload(
    String token, {
    required String requestId,
    required String docType,
    required String objectKey,
    required String fileName,
    required int fileSize,
    required String mimeType,
    String? language,
  }) =>
      _send(() => http.post(
            _u('/documents/confirm'),
            headers: {..._json, 'Authorization': 'Bearer $token'},
            body: jsonEncode({
              'requestId': requestId,
              'docType': docType,
              'objectKey': objectKey,
              'fileName': fileName,
              'fileSize': fileSize,
              'mimeType': mimeType,
              if (language != null) 'language': language,
            }),
          ));

  Future<Map<String, dynamic>> uploadDocumentMultipart(
    String token, {
    required String requestId,
    required String docType,
    required String fileName,
    required List<int> bytes,
    required String mimeType,
    String? language,
  }) async {
    try {
      final req = http.MultipartRequest('POST', _u('/documents/upload'))
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['requestId'] = requestId
        ..fields['docType'] = docType
        ..fields['mimeType'] = mimeType;
      if (language != null) req.fields['language'] = language;
      req.files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));

      final streamed = await req.send().timeout(const Duration(seconds: 45));
      final res = await http.Response.fromStream(streamed);
      final body = res.body.isEmpty ? <String, dynamic>{} : jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode >= 200 && res.statusCode < 300) return body;
      final msg = (body['message'] ?? 'Upload failed (${res.statusCode})').toString();
      throw ApiException(msg, status: res.statusCode);
    } on TimeoutException {
      throw ApiException('network');
    } on http.ClientException {
      throw ApiException('network');
    }
  }

  /// Uploads via S3 presigned URL first; falls back to backend multipart upload if direct S3 PUT fails.
  Future<Map<String, dynamic>> uploadDocument(
    String token, {
    required String requestId,
    required String docType,
    required String fileName,
    required List<int> bytes,
    required String mimeType,
    String? language,
  }) async {
    try {
      final presign = await presignDocumentUpload(
        token,
        requestId: requestId,
        docType: docType,
        fileName: fileName,
        mimeType: mimeType,
      );
      final uploadUrl = presign['uploadUrl']?.toString() ?? '';
      final objectKey = presign['objectKey']?.toString() ?? '';
      if (uploadUrl.isNotEmpty && objectKey.isNotEmpty) {
        final s3Res = await http
            .put(
              Uri.parse(uploadUrl),
              headers: {'Content-Type': mimeType},
              body: bytes,
            )
            .timeout(const Duration(seconds: 30));
        if (s3Res.statusCode >= 200 && s3Res.statusCode < 300) {
          return confirmDocumentUpload(
            token,
            requestId: requestId,
            docType: docType,
            objectKey: objectKey,
            fileName: fileName,
            fileSize: bytes.length,
            mimeType: mimeType,
            language: language,
          );
        }
      }
    } catch (_) {
      // Fall back to backend multipart S3 upload
    }

    return uploadDocumentMultipart(
      token,
      requestId: requestId,
      docType: docType,
      fileName: fileName,
      bytes: bytes,
      mimeType: mimeType,
      language: language,
    );
  }

  Future<List<Map<String, dynamic>>> getRequestDocuments(String token, String requestId) async {
    final res = await _send(() => http.get(
          _u('/documents/request/$requestId'),
          headers: {'Authorization': 'Bearer $token'},
        ));
    return (res['documents'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> getReadinessReport(
    String token,
    String requestId, {
    required List<String> requiredDocuments,
  }) async {
    final res = await _send(() => http.post(
          _u('/documents/request/$requestId/readiness'),
          headers: {..._json, 'Authorization': 'Bearer $token'},
          body: jsonEncode({'requiredDocuments': requiredDocuments}),
        ));
    return Map<String, dynamic>.from(res['report'] ?? {});
  }

  Future<void> deleteDocument(String token, dynamic docId) async {
    await _send(() => http.delete(
          _u('/documents/$docId'),
          headers: {'Authorization': 'Bearer $token'},
        ));
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
      final msg = (body['message'] ?? 'Request failed (${res.statusCode})').toString();
      throw ApiException(msg, status: res.statusCode, fieldErrors: errs);
    } on TimeoutException {
      throw ApiException('network');
    } on http.ClientException {
      throw ApiException('network');
    }
  }
}
