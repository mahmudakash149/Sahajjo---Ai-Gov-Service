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
