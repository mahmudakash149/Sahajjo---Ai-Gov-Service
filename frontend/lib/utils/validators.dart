import '../l10n/strings.dart';

/// Client-side validation mirrors the backend rules (backend remains the authority).
class Validators {
  static final _phone = RegExp(r'^(?:\+?88)?0?1[3-9]\d{8}$');
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final _name = RegExp(r"^[\p{L}\p{M}][\p{L}\p{M}\s.'-]*$", unicode: true);
  static final _specialChar = RegExp(r'[^A-Za-z0-9]');

  static String cleanPhone(String v) => v.trim().replaceAll(RegExp(r'[\s-]'), '');

  static String? name(String? v, S s) {
    final t = (v ?? '').trim();
    if (t.length < 2 || t.length > 100 || !_name.hasMatch(t)) return s.reqName;
    return null;
  }

  static String? phone(String? v, S s) =>
      _phone.hasMatch(cleanPhone(v ?? '')) ? null : s.badPhone;

  static String? emailOptional(String? v, S s) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return null;
    return (_email.hasMatch(t) && t.length <= 254) ? null : s.badEmail;
  }

  static String? required(String? v, S s) =>
      (v ?? '').trim().isEmpty ? s.reqField : null;

  static String? password(String? v, S s) {
    final p = v ?? '';
    if (p.length < 8 || p.length > 72) return s.pwLength;
    if (!RegExp(r'[a-z]').hasMatch(p)) return s.pwLower;
    if (!RegExp(r'[A-Z]').hasMatch(p)) return s.pwUpper;
    if (!RegExp(r'\d').hasMatch(p)) return s.pwDigit;
    if (!_specialChar.hasMatch(p)) return s.pwSpecial;
    return null;
  }

  static String? confirm(String? v, String original, S s) =>
      v == original ? null : s.pwMismatch;
}
