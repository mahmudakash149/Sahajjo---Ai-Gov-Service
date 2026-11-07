import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  void dispose() {
    for (final c in [_name, _phone, _email, _pw, _pw2]) {
      c.dispose();
    }
    super.dispose();
  }

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
    try {
      await auth.register(
        fullName: _name.text,
        phone: Validators.cleanPhone(_phone.text),
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final s = auth.s;
    const gap = SizedBox(height: 16);
    return Scaffold(
      appBar: AppBar(title: Text(s.createAccount)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(alignment: Alignment.centerRight, child: LanguageToggle()),
                    gap,
                    TextFormField(
                      controller: _name,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(labelText: s.fullName, border: const OutlineInputBorder()),
                      validator: (v) => _withServer('fullName', Validators.name(v, s)),
                    ),
                    gap,
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(labelText: s.phone, border: const OutlineInputBorder()),
                      validator: (v) => _withServer('phone', Validators.phone(v, s)),
                    ),
                    gap,
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(labelText: s.emailOptional, border: const OutlineInputBorder()),
                      validator: (v) => _withServer('email', Validators.emailOptional(v, s)),
                    ),
                    gap,
                    TextFormField(
                      controller: _pw,
                      obscureText: _hide,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: s.password,
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_hide ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _hide = !_hide),
                        ),
                      ),
                      validator: (v) => _withServer('password', Validators.password(v, s)),
                    ),
                    gap,
                    TextFormField(
                      controller: _pw2,
                      obscureText: _hide,
                      decoration: InputDecoration(labelText: s.confirmPassword, border: const OutlineInputBorder()),
                      validator: (v) => _withServer('confirmPassword', Validators.confirm(v, _pw.text, s)),
                    ),
                    gap,
                    CheckboxListTile(
                      value: _consent,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (v) => setState(() {
                        _consent = v ?? false;
                        _consentTouched = true;
                      }),
                      title: Text(s.consent, style: const TextStyle(fontSize: 14)),
                      subtitle: (_consentTouched && !_consent)
                          ? Text(s.reqConsent, style: TextStyle(color: Theme.of(context).colorScheme.error))
                          : null,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Semantics(
                        liveRegion: true,
                        child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                      child: _busy
                          ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(s.register),
                    ),
                    TextButton(
                      onPressed: _busy ? null : () => Navigator.of(context).pop(),
                      child: Text(s.haveAccount),
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
