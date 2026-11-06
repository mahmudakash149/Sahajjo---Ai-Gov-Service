import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class OtpLoginScreen extends StatefulWidget {
  const OtpLoginScreen({super.key});

  @override
  State<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends State<OtpLoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _step = 1; // 1: Enter Phone, 2: Enter OTP
  bool _busy = false;
  String? _error;
  String? _devCode;

  Timer? _timer;
  int _secondsRemaining = 60;

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
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

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();

    try {
      final res = await auth.sendOtp(_normalizedPhone);
      setState(() {
        _step = 2;
        _devCode = res['devCode']?.toString();
      });
      _startTimer();
    } on ApiException catch (e) {
      setState(() {
        if (e.message == 'network') {
          _error = auth.s.networkError;
        } else if (e.status == 404) {
          _error = auth.lang == 'bn'
              ? 'এই নম্বরে কোনো অ্যাকাউন্ট নেই। অনুগ্রহ করে প্রথমে নিবন্ধন করুন।'
              : 'No account registered with this phone number. Please register first.';
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

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    final auth = context.read<AuthProvider>();

    if (otp.length != 6) {
      setState(() {
        _error = auth.lang == 'bn' ? '৬-সংখ্যার সঠিক কোড লিখুন' : 'Enter the complete 6-digit code';
      });
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await auth.loginWithOtp(_normalizedPhone, otp);
      if (mounted) {
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final s = auth.s;
    final isBn = auth.lang == 'bn';
    const primaryColor = Color(0xFF006A4E);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(s.otpTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              decoration: const BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.sms_outlined, color: Colors.white, size: 32),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    s.otpSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Form Area
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_step == 1) ...[
                      // STEP 1: Enter Phone Number
                      Text(
                        isBn ? 'মোবাইল নম্বর' : 'Phone number',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        style: const TextStyle(fontSize: 16, color: Color(0xFF0F172A)),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          _LeadingZeroStripperFormatter(),
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: InputDecoration(
                          hintText: isBn ? '১XXXXXXXXX' : '1XXXXXXXXX',
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 14, right: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  '+880',
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  height: 22,
                                  width: 1.2,
                                  color: const Color(0xFFCBD5E1),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
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
                            return isBn ? 'মোবাইল নম্বর লিখুন' : 'Please enter your phone number';
                          }
                          if (val.length != 10 || !RegExp(r'^1[3-9]\d{8}$').hasMatch(val)) {
                            return isBn
                                ? 'সঠিক ১০-সংখ্যার নম্বর দিন (১XXXXXXXXX)'
                                : 'Enter a valid 10-digit number (1XXXXXXXXX)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Send OTP Button
                      ElevatedButton(
                        onPressed: _busy ? null : _sendOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          disabledBackgroundColor: primaryColor.withValues(alpha: 0.6),
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                        child: _busy
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                              )
                            : Text(
                                s.sendOtp,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                      ),
                    ] else ...[
                      // STEP 2: Enter Verification Code
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.otpSentTo,
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '+880 ${_phoneController.text}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _busy
                                ? null
                                : () {
                                    _timer?.cancel();
                                    setState(() {
                                      _step = 1;
                                      _otpController.clear();
                                      _error = null;
                                    });
                                  },
                            icon: const Icon(Icons.edit, size: 14, color: primaryColor),
                            label: Text(
                              s.changePhone,
                              style: const TextStyle(color: primaryColor, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Demo OTP Banner (For Testing & Evaluators)
                      if (_devCode != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          margin: const EdgeInsets.only(bottom: 18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _otpController.text = _devCode!;
                              });
                            },
                            child: Row(
                              children: [
                                const Icon(Icons.touch_app_rounded, color: Color(0xFF2563EB), size: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.demoNotice,
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF1E40AF)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _devCode!,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF1D4ED8),
                                          letterSpacing: 4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.copy_rounded, color: Color(0xFF3B82F6), size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // 6-Digit OTP Field
                      Text(
                        s.enterOtp,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 14,
                          color: primaryColor,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        decoration: InputDecoration(
                          hintText: '••••••',
                          hintStyle: const TextStyle(letterSpacing: 14, color: Color(0xFFCBD5E1)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: primaryColor, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Countdown & Resend Option
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_secondsRemaining > 0) ...[
                            Text(
                              '${s.resendIn} 0:${_secondsRemaining.toString().padLeft(2, '0')}',
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                            ),
                          ] else ...[
                            TextButton.icon(
                              onPressed: _busy ? null : _sendOtp,
                              icon: const Icon(Icons.refresh, size: 16, color: primaryColor),
                              label: Text(
                                s.resendOtp,
                                style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Verify & Login Button
                      ElevatedButton(
                        onPressed: _busy ? null : _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          disabledBackgroundColor: primaryColor.withValues(alpha: 0.6),
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                        child: _busy
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                              )
                            : Text(
                                s.verifyAndLogin,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                      ),
                    ],

                    // Error Message
                    if (_error != null) ...[
                      const SizedBox(height: 18),
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
