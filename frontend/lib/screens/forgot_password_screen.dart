import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/language_toggle.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String? initialPhone;
  const ForgotPasswordScreen({super.key, this.initialPhone});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _formKeyPhone = GlobalKey<FormState>();
  final _formKeyPassword = GlobalKey<FormState>();

  int _currentStep = 1; // 1: Phone, 2: OTP, 3: New Password
  bool _busy = false;
  String? _error;
  String? _devCode;
  String? _resetToken;

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  Timer? _timer;
  int _secondsRemaining = 60;

  @override
  void initState() {
    super.initState();
    if (widget.initialPhone != null && widget.initialPhone!.isNotEmpty) {
      String clean = widget.initialPhone!.trim();
      if (clean.startsWith('+880')) clean = clean.substring(4);
      if (clean.startsWith('0')) clean = clean.substring(1);
      _phoneController.text = clean;
    }
    _newPasswordController.addListener(() => setState(() {}));
    _confirmPasswordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsRemaining = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        t.cancel();
      }
    });
  }

  String get _normalizedPhone {
    final raw = _phoneController.text.trim();
    return raw.startsWith('0') ? raw : '0$raw';
  }

  // Password requirements getters
  bool get _hasMinLength =>
      _newPasswordController.text.length >= 8 && _newPasswordController.text.length <= 72;
  bool get _hasUpper => RegExp(r'[A-Z]').hasMatch(_newPasswordController.text);
  bool get _hasLower => RegExp(r'[a-z]').hasMatch(_newPasswordController.text);
  bool get _hasDigit => RegExp(r'\d').hasMatch(_newPasswordController.text);
  bool get _hasSpecial => RegExp(r'[^A-Za-z0-9]').hasMatch(_newPasswordController.text);
  bool get _passwordsMatch =>
      _newPasswordController.text.isNotEmpty &&
      _newPasswordController.text == _confirmPasswordController.text;

  // STEP 1: Send OTP to Phone
  Future<void> _handleSendOtp() async {
    if (!_formKeyPhone.currentState!.validate()) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();

    try {
      final res = await auth.sendOtp(_normalizedPhone);
      setState(() {
        _currentStep = 2;
        _devCode = res['devCode']?.toString();
      });
      _startTimer();
    } on ApiException catch (e) {
      setState(() {
        if (e.message == 'network') {
          _error = auth.s.networkError;
        } else if (e.status == 404 && e.message.contains('No account')) {
          _error = auth.lang == 'bn'
              ? 'এই মোবাইল নম্বরে কোনো অ্যাকাউন্ট পাওয়া যায়নি।'
              : 'No account registered with this phone number.';
        } else {
          _error = e.message;
        }
      });
    } catch (_) {
      setState(() {
        _error = auth.lang == 'bn' ? 'সার্ভারে সংযোগ করা যায়নি' : 'Could not reach server';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // STEP 2: Verify OTP
  Future<void> _handleVerifyOtp() async {
    final otp = _otpController.text.trim();
    final auth = context.read<AuthProvider>();

    if (otp.length != 6) {
      setState(() {
        _error = auth.lang == 'bn' ? '৬-সংখ্যার সঠিক ওটিপি লিখুন' : 'Enter the complete 6-digit OTP';
      });
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final res = await auth.verifyResetOtp(_normalizedPhone, otp);
      setState(() {
        _resetToken = res['resetToken'] as String?;
        _currentStep = 3;
      });
    } on ApiException catch (e) {
      setState(() {
        if (e.message == 'network') {
          _error = auth.s.networkError;
        } else if (e.message.contains('Invalid OTP')) {
          _error = auth.lang == 'bn' ? 'ভুল ওটিপি কোড। পুনরায় চেষ্টা করুন।' : 'Invalid OTP code. Please try again.';
        } else {
          _error = e.message;
        }
      });
    } catch (_) {
      setState(() {
        _error = auth.lang == 'bn' ? 'সার্ভারে সংযোগ করা যায়নি' : 'Could not reach server';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // STEP 3: Submit New Password & Update Database
  Future<void> _handleResetPassword() async {
    if (!_formKeyPassword.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final isBn = auth.lang == 'bn';

    if (!_hasMinLength || !_hasUpper || !_hasLower || !_hasDigit || !_hasSpecial) {
      setState(() {
        _error = isBn
            ? 'পাসওয়ার্ডের সব শর্ত পূরণ করা আবশ্যক।'
            : 'All password requirements must be met.';
      });
      return;
    }

    if (!_passwordsMatch) {
      setState(() {
        _error = isBn ? 'উভয় পাসওয়ার্ড এক হতে হবে।' : 'Passwords do not match.';
      });
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await auth.resetPassword(
        phone: _normalizedPhone,
        resetToken: _resetToken,
        otp: _otpController.text.trim(),
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      if (!mounted) return;

      // Show Success Dialog and navigate back to Login
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF006A4E),
                  size: 44,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                isBn ? 'পাসওয়ার্ড সফলভাবে পরিবর্তন হয়েছে!' : 'Password Changed Successfully!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isBn
                    ? 'আপনার অ্যাকাউন্টের পাসওয়ার্ড সফলভাবে ডাটাবেজে আপডেট করা হয়েছে। এখন নতুন পাসওয়ার্ড দিয়ে লগইন করুন।'
                    : 'Your new password has been updated in the database. Please log in with your new credentials.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13.5, color: Color(0xFF475569), height: 1.4),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx); // Close dialog
                    Navigator.pop(context, _normalizedPhone); // Return phone to LoginScreen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006A4E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(
                    isBn ? 'লগইনে ফিরে যান' : 'Back to Login',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } on ApiException catch (e) {
      setState(() {
        if (e.message == 'network') {
          _error = auth.s.networkError;
        } else {
          _error = e.message;
        }
      });
    } catch (_) {
      setState(() {
        _error = isBn ? 'সার্ভারে সংযোগ করা যায়নি' : 'Could not reach server';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isBn = auth.lang == 'bn';
    const primaryColor = Color(0xFF006A4E);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isBn ? 'পাসওয়ার্ড পরিবর্তন (Change Password)' : 'Change Password',
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: LanguageToggle(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top Banner with curved aesthetic
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                decoration: const BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      auth.s.resetPasswordHeader,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      auth.s.resetPasswordSubheader,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Visual Step Indicator (1 - 2 - 3)
                    _buildStepIndicator(isBn),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Main Form Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Error Banner if present
                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Current Step Form View
                      if (_currentStep == 1) _buildStep1Phone(isBn),
                      if (_currentStep == 2) _buildStep2Otp(isBn),
                      if (_currentStep == 3) _buildStep3NewPassword(isBn),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // Visual Step Indicator
  Widget _buildStepIndicator(bool isBn) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _stepCircle(1, isBn ? 'নম্বর' : 'Phone', _currentStep >= 1),
        _stepLine(_currentStep >= 2),
        _stepCircle(2, isBn ? 'ওটিপি' : 'OTP', _currentStep >= 2),
        _stepLine(_currentStep >= 3),
        _stepCircle(3, isBn ? 'পাসওয়ার্ড' : 'Password', _currentStep >= 3),
      ],
    );
  }

  Widget _stepCircle(int step, String label, bool active) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white.withOpacity(0.25),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(
                color: active ? const Color(0xFF006A4E) : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.white.withOpacity(0.65),
            fontSize: 11,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _stepLine(bool active) {
    return Container(
      width: 44,
      height: 2,
      margin: const EdgeInsets.only(bottom: 16),
      color: active ? Colors.white : Colors.white.withOpacity(0.3),
    );
  }

  // STEP 1 WIDGET: Phone Input
  Widget _buildStep1Phone(bool isBn) {
    const primaryColor = Color(0xFF006A4E);

    return Form(
      key: _formKeyPhone,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.phone_android_rounded, color: primaryColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isBn ? '১. নিবন্ধিত মোবাইল নম্বর দিন' : '1. Enter Registered Phone Number',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isBn
                ? 'আপনার একাউন্টের ১১-সংখ্যার নম্বরটি দিন। আমরা একটি ওটিপি পাঠাব।'
                : 'Enter your 11-digit mobile number. We will send a verification code.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 18),

          // Phone Number Input
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleSendOtp(),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _LeadingZeroStripper(),
              LengthLimitingTextInputFormatter(10),
            ],
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 1),
            decoration: InputDecoration(
              prefixIcon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                margin: const EdgeInsets.only(right: 8),
                decoration: const BoxDecoration(
                  border: Border(right: BorderSide(color: Color(0xFFE2E8F0), width: 1.2)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🇧🇩', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 6),
                    Text(
                      '+880',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
              hintText: '1XXXXXXXXX',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), letterSpacing: 1),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: primaryColor, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
              ),
            ),
            validator: (value) {
              final val = value?.trim() ?? '';
              if (val.isEmpty) {
                return isBn ? 'মোবাইল নম্বর লিখুন' : 'Enter mobile number';
              }
              if (val.length != 10 || !RegExp(r'^1[3-9]\d{8}$').hasMatch(val)) {
                return isBn
                    ? 'সঠিক ১০-সংখ্যার নম্বর দিন (১XXXXXXXXX)'
                    : 'Enter valid 10-digit number (1XXXXXXXXX)';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Send OTP Button
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _busy ? null : _handleSendOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.send_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          isBn ? 'ওটিপি কোড পাঠান' : 'Send OTP Code',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // STEP 2 WIDGET: OTP Entry
  Widget _buildStep2Otp(bool isBn) {
    const primaryColor = Color(0xFF006A4E);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.mark_email_read_rounded, color: primaryColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isBn ? '২. ওটিপি যাচাইকরণ' : '2. Verify OTP Code',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Sent to banner with Change number action
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${isBn ? 'কোড পাঠানো হয়েছে: ' : 'Sent to: '} +880 ${_phoneController.text}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _currentStep = 1),
                child: Text(
                  isBn ? 'পরিবর্তন' : 'Change',
                  style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Demo banner if available in development
        if (_devCode != null) ...[
          GestureDetector(
            onTap: () {
              _otpController.text = _devCode!;
              setState(() {});
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFD97706), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${isBn ? 'ডেমো ওটিপি (ট্যাপ করে পূরণ করুন): ' : 'Demo OTP (Tap to autofill): '} $_devCode',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 6-digit OTP Field
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: 10,
            color: Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '••••••',
            hintStyle: const TextStyle(color: Color(0xFFCBD5E1), letterSpacing: 8),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: primaryColor, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Resend Timer
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_secondsRemaining > 0)
              Text(
                '${isBn ? 'পুনরায় পাঠানো যাবে: ' : 'Resend in: '} $_secondsRemaining s',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              )
            else
              TextButton(
                onPressed: _busy ? null : _handleSendOtp,
                child: Text(
                  isBn ? 'পুনরায় কোড পাঠান' : 'Resend Code',
                  style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),

        // Verify OTP Button
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _busy ? null : _handleVerifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Text(
                    isBn ? 'ওটিপি যাচাই করুন ও এগিয়ে যান' : 'Verify OTP & Continue',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }

  // STEP 3 WIDGET: New Password Entry & Checklist
  Widget _buildStep3NewPassword(bool isBn) {
    const primaryColor = Color(0xFF006A4E);
    final s = context.read<AuthProvider>().s;

    return Form(
      key: _formKeyPassword,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.lock_reset_rounded, color: primaryColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isBn ? '৩. নতুন পাসওয়ার্ড নির্ধারণ' : '3. Set New Password',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isBn
                ? 'আপনার অ্যাকাউন্টের জন্য একটি নতুন শক্তিশালী পাসওয়ার্ড দিন।'
                : 'Create a new secure password for your account.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),

          // New Password Field
          Text(
            isBn ? 'নতুন পাসওয়ার্ড' : 'New Password',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _newPasswordController,
            obscureText: _obscureNewPassword,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: '••••••••',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNewPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: const Color(0xFF64748B),
                  size: 20,
                ),
                onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryColor, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Confirm New Password Field
          Text(
            isBn ? 'পাসওয়ার্ড নিশ্চিত করুন' : 'Confirm New Password',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: '••••••••',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: const Color(0xFF64748B),
                  size: 20,
                ),
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryColor, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Live Password Requirements Checklist
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.pwReqTitle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 8),
                _requirementRow(s.pwReqLength, _hasMinLength),
                _requirementRow(s.pwReqUpper, _hasUpper),
                _requirementRow(s.pwReqLower, _hasLower),
                _requirementRow(s.pwReqDigit, _hasDigit),
                _requirementRow(s.pwReqSpecial, _hasSpecial),
                _requirementRow(
                  isBn ? 'উভয় পাসওয়ার্ড মিলেছে' : 'Passwords match',
                  _passwordsMatch,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Submit & Save Button
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _busy ? null : _handleResetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          isBn ? 'পাসওয়ার্ড সংরক্ষণ করুন' : 'Save New Password',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _requirementRow(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 15,
            color: met ? const Color(0xFF006A4E) : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: met ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                fontWeight: met ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Automatically strips leading 0 when typing so +880 1XXXXXXXXX formats seamlessly
class _LeadingZeroStripper extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.startsWith('0')) {
      final stripped = newValue.text.replaceFirst(RegExp(r'^0+'), '');
      return TextEditingValue(
        text: stripped,
        selection: TextSelection.collapsed(offset: stripped.length),
      );
    }
    return newValue;
  }
}
