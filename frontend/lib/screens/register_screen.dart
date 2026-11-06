import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/strings.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';
import '../widgets/language_toggle.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _pw = TextEditingController();
  final _pw2 = TextEditingController();

  bool _consent = false;
  bool _consentTouched = false;
  bool _busy = false;
  bool _hide = true;
  String? _error;
  Map<String, String> _serverErrors = {};

  @override
  void initState() {
    super.initState();
    _pw.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _pw, _pw2]) {
      c.dispose();
    }
    super.dispose();
  }

  // Password requirement check getters
  bool get _hasMinLength => _pw.text.length >= 8 && _pw.text.length <= 72;
  bool get _hasUpper => RegExp(r'[A-Z]').hasMatch(_pw.text);
  bool get _hasLower => RegExp(r'[a-z]').hasMatch(_pw.text);
  bool get _hasDigit => RegExp(r'\d').hasMatch(_pw.text);
  bool get _hasSpecial => RegExp(r'[^A-Za-z0-9]').hasMatch(_pw.text);

  String? _withServer(String field, String? local) => local ?? _serverErrors[field];

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    setState(() {
      _serverErrors = {};
      _consentTouched = true;
    });
    if (!_form.currentState!.validate() || !_consent) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    final rawPhone = Validators.cleanPhone(_phone.text);
    final normalizedPhone = rawPhone.startsWith('0') ? rawPhone : '0$rawPhone';

    try {
      await auth.register(
        fullName: _name.text,
        phone: normalizedPhone,
        email: _email.text,
        password: _pw.text,
        confirmPassword: _pw2.text,
        consent: _consent,
      );
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } on ApiException catch (e) {
      setState(() {
        if (e.message == 'network') {
          _error = auth.s.networkError;
        } else {
          _serverErrors = e.fieldErrors;
          _error = e.fieldErrors.isEmpty ? e.message : null;
        }
      });
      _form.currentState!.validate(); // re-run to display server field errors
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _buildPasswordChecklist(S s) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.pwReqTitle,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 6),
          _RequirementItem(label: s.pwReqLength, isMet: _hasMinLength),
          _RequirementItem(label: s.pwReqUpper, isMet: _hasUpper),
          _RequirementItem(label: s.pwReqLower, isMet: _hasLower),
          _RequirementItem(label: s.pwReqDigit, isMet: _hasDigit),
          _RequirementItem(label: s.pwReqSpecial, isMet: _hasSpecial),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final s = auth.s;
    const primaryColor = Color(0xFF006A4E);
    const gap = SizedBox(height: 16);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.createAccount),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(alignment: Alignment.centerRight, child: LanguageToggle()),
                    gap,

                    // Full Name
                    TextFormField(
                      controller: _name,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: s.fullName,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => _withServer('fullName', Validators.name(v, s)),
                    ),
                    gap,

                    // Phone Number with +880 Prefix
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        _LeadingZeroStripperFormatter(),
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: InputDecoration(
                        labelText: s.phone,
                        hintText: '1XXXXXXXXX',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 14, right: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                '+880',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(height: 20, width: 1.2, color: const Color(0xFFCBD5E1)),
                            ],
                          ),
                        ),
                      ),
                      validator: (v) => _withServer('phone', Validators.phone(v, s)),
                    ),
                    gap,

                    // Email (Optional)
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: s.emailOptional,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => _withServer('email', Validators.emailOptional(v, s)),
                    ),
                    gap,

                    // Password
                    TextFormField(
                      controller: _pw,
                      obscureText: _hide,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: s.password,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        suffixIcon: IconButton(
                          icon: Icon(_hide ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _hide = !_hide),
                        ),
                      ),
                      validator: (v) => _withServer('password', Validators.password(v, s)),
                    ),

                    // Password Requirements Checklist
                    _buildPasswordChecklist(s),
                    gap,

                    // Confirm Password
                    TextFormField(
                      controller: _pw2,
                      obscureText: _hide,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: s.confirmPassword,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => _withServer('confirmPassword', Validators.confirm(v, _pw.text, s)),
                    ),
                    gap,

                    // Consent Checkbox
                    CheckboxListTile(
                      value: _consent,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: primaryColor,
                      onChanged: (v) => setState(() {
                        _consent = v ?? false;
                        _consentTouched = true;
                      }),
                      title: Text(s.consent, style: const TextStyle(fontSize: 13, height: 1.4)),
                      subtitle: (_consentTouched && !_consent)
                          ? Text(s.reqConsent, style: TextStyle(color: Theme.of(context).colorScheme.error))
                          : null,
                    ),

                    // Error Banner
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _busy ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      child: _busy
                          ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(s.register, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),

                    // Already have account button
                    TextButton(
                      onPressed: _busy ? null : () => Navigator.of(context).pop(),
                      child: Text(
                        s.haveAccount,
                        style: const TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dynamic requirement item showing green check or grey circle
class _RequirementItem extends StatelessWidget {
  final String label;
  final bool isMet;

  const _RequirementItem({required this.label, required this.isMet});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF006A4E);
    const grey = Color(0xFF94A3B8);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 15,
            color: isMet ? green : grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isMet ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                fontWeight: isMet ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Automatically strips leading zeros when users paste or type numbers after +880
class _LeadingZeroStripperFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;
    if (text.startsWith('0')) {
      text = text.replaceFirst(RegExp(r'^0+'), '');
      return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
    return newValue;
  }
}
