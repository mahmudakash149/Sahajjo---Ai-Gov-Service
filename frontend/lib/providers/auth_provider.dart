import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../l10n/strings.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;
  // Token lives in Android Keystore-backed encrypted storage, not plain prefs.
  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'sahajjo_token';

  String? _token;
  Map<String, dynamic>? _user;
  String _lang = 'bn';
  bool _initialising = true;

  bool get initialising => _initialising;
  bool get isAuthenticated => _token != null && _user != null;
  Map<String, dynamic>? get user => _user;
  String get lang => _lang;
  S get s => S(_lang);

  void setLanguage(String lang) {
    _lang = lang;
    notifyListeners();
  }

  /// Restore session on app start.
  Future<void> init() async {
    try {
      final saved = await _storage.read(key: _tokenKey);
      if (saved != null) {
        final res = await _api.me(saved);
        _token = saved;
        _user = Map<String, dynamic>.from(res['user']);
        _lang = _user!['preferredLanguage'] ?? _lang;
      }
    } catch (_) {
      await _storage.delete(key: _tokenKey);
      _token = null;
      _user = null;
    }
    _initialising = false;
    notifyListeners();
  }

  Future<void> _startSession(Map<String, dynamic> res) async {
    _token = res['token'] as String;
    _user = Map<String, dynamic>.from(res['user']);
    _lang = _user!['preferredLanguage'] ?? _lang;
    await _storage.write(key: _tokenKey, value: _token);
    notifyListeners();
  }

  Future<void> login(String identifier, String password) async =>
      _startSession(await _api.login(identifier.trim(), password));

  Future<Map<String, dynamic>> sendOtp(String phone) async =>
      await _api.sendOtp(phone.trim());

  Future<void> loginWithOtp(String phone, String otp) async =>
      _startSession(await _api.verifyOtp(phone.trim(), otp.trim()));

  // Password Reset / Change Password flow
  Future<Map<String, dynamic>> verifyResetOtp(String phone, String otp) async =>
      await _api.verifyResetOtp(phone.trim(), otp.trim());

  Future<Map<String, dynamic>> resetPassword({
    required String phone,
    String? resetToken,
    String? otp,
    required String newPassword,
    required String confirmPassword,
  }) async =>
      await _api.resetPassword(
        phone: phone.trim(),
        resetToken: resetToken,
        otp: otp?.trim(),
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

  Future<void> register({
    required String fullName,
    required String phone,
    String? email,
    required String password,
    required String confirmPassword,
    required bool consent,
  }) async =>
      _startSession(await _api.register(
        fullName: fullName.trim(),
        phone: phone,
        email: email?.trim(),
        password: password,
        confirmPassword: confirmPassword,
        preferredLanguage: _lang,
        consent: consent,
      ));

  /// FR3: load the service catalog (optionally filtered by a search text).
  Future<List<Map<String, dynamic>>> fetchServices(String query) async {
    if (_token == null) return [];
    final res = await _api.services(_token!, query);
    return (res['services'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// FR4: Citizen Service Request submission
  Future<Map<String, dynamic>> submitServiceRequest(String text) async {
    if (_token == null) throw ApiException('Not authenticated');
    return await _api.submitServiceRequest(_token!, text, language: _lang);
  }

  /// FR6: Submit follow-up answers to refine guidance
  Future<Map<String, dynamic>> submitFollowUpAnswer(dynamic requestId, dynamic answers) async {
    if (_token == null) throw ApiException('Not authenticated');
    return await _api.submitFollowUpAnswer(_token!, requestId, answers);
  }

  /// FR4: Load citizen's submitted requests
  Future<List<Map<String, dynamic>>> fetchMyRequests() async {
    if (_token == null) return [];
    return await _api.getMyServiceRequests(_token!);
  }

  /// FR11-FR15: Document upload, OCR & readiness check
  Future<List<Map<String, dynamic>>> fetchRequestDocuments(String requestId) async {
    if (_token == null) return [];
    return await _api.getRequestDocuments(_token!, requestId);
  }

  Future<Map<String, dynamic>> uploadDocument({
    required String requestId,
    required String docType,
    required String fileName,
    required List<int> bytes,
    required String mimeType,
  }) async {
    if (_token == null) throw ApiException('Not authenticated');
    return await _api.uploadDocument(
      _token!,
      requestId: requestId,
      docType: docType,
      fileName: fileName,
      bytes: bytes,
      mimeType: mimeType,
      language: _lang,
    );
  }

  Future<void> deleteDocument(dynamic docId) async {
    if (_token == null) throw ApiException('Not authenticated');
    await _api.deleteDocument(_token!, docId);
  }

  Future<Map<String, dynamic>> generateReadinessReport({
    required String requestId,
    required List<String> requiredDocuments,
  }) async {
    if (_token == null) throw ApiException('Not authenticated');
    return await _api.getReadinessReport(
      _token!,
      requestId,
      requiredDocuments: requiredDocuments,
    );
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    _token = null;
    _user = null;
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    if (_token == null) return;
    await _api.deleteAccount(_token!);
    await logout();
  }
}
