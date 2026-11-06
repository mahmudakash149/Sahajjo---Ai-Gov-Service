import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();
    String rawInput = _phoneController.text.trim();

    // Normalize phone number for the backend (01XXXXXXXXX or email)
    String identifier = rawInput;
    if (RegExp(r'^[1-9]\d{8,9}$').hasMatch(rawInput)) {
      identifier = '0$rawInput';
    } else if (rawInput.startsWith('+880')) {
      identifier = rawInput.replaceFirst('+880', '0');
    }

    try {
      await auth.login(identifier, _passwordController.text);
      // AuthGate automatically transitions to HomeScreen upon success
    } on ApiException catch (e) {
      setState(() {
        if (e.message == 'network') {
          _error = auth.s.networkError;
        } else if (e.message.contains('Invalid phone/email') || e.message.contains('Invalid')) {
          _error = auth.lang == 'bn'
              ? 'মোবাইল নম্বর বা পাসওয়ার্ড সঠিক নয়'
              : 'Invalid phone number or password';
        } else {
          _error = e.message;
        }
      });
    } catch (_) {
      setState(() {
        _error = auth.lang == 'bn'
            ? 'সার্ভারে সংযোগ করা সম্ভব হয়নি'
            : 'Could not connect to the server';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showForgotPasswordDialog() {
    final auth = context.read<AuthProvider>();
    final isBn = auth.lang == 'bn';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isBn ? 'পাসওয়ার্ড পুনরুদ্ধার' : 'Forgot Password'),
        content: Text(
          isBn
              ? 'পাসওয়ার্ড রিসেট করতে অনুগ্রহ করে হেল্পডেস্ক বা অ্যাডমিনের সাথে যোগাযোগ করুন অথবা ওটিপি দিয়ে লগইন করুন।'
              : 'To reset your password, please contact the helpdesk/admin or use Login with OTP.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              isBn ? 'ঠিক আছে' : 'OK',
              style: const TextStyle(color: Color(0xFF006A4E), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showOtpNotice() {
    final auth = context.read<AuthProvider>();
    final isBn = auth.lang == 'bn';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isBn
              ? 'ওটিপি লগইন সুবিধা পরবর্তী আপডেটে সংযুক্ত করা হবে'
              : 'Login with OTP will be available in the next update',
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isBn = auth.lang == 'bn';
    const primaryColor = Color(0xFF006A4E);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Green Curved Header
            Container(
              decoration: const BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(40),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
                  child: Column(
                    children: [
                      // Language Toggle
                      Align(
                        alignment: Alignment.topRight,
                        child: GestureDetector(
                          onTap: () {
                            auth.setLanguage(isBn ? 'en' : 'bn');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.language, size: 16, color: Colors.white),
                                const SizedBox(width: 6),
                                Text(
                                  isBn ? 'English' : 'বাংলা',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Logo Container
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: _SahajjoEmblem(size: 46),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // App Title
                      Text(
                        isBn ? 'সাহায্য' : 'Sahajjo',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Tagline
                      Text(
                        isBn
                            ? 'সরকারি সেবা, সহজ নির্দেশনা'
                            : 'Government services, made simple',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Form Section
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Header
                    Text(
                      isBn ? 'স্বাগতম' : 'Welcome back',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isBn
                          ? 'আপনার সেবা আবেদন চালিয়ে যেতে সাইন ইন করুন'
                          : 'Sign in to continue your service application',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Phone Number Label
                    Text(
                      isBn ? 'মোবাইল নম্বর' : 'Phone number',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Phone Number Input
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      autofillHints: const [AutofillHints.telephoneNumber, AutofillHints.username],
                      textInputAction: TextInputAction.next,
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
                    const SizedBox(height: 18),

                    // Password Label
                    Text(
                      isBn ? 'পাসওয়ার্ড' : 'Password',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Password Input
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      style: const TextStyle(fontSize: 16, color: Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 16, letterSpacing: 2),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        suffixIcon: TextButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          child: Text(
                            _obscurePassword ? (isBn ? 'দেখুন' : 'Show') : (isBn ? 'লুকান' : 'Hide'),
                            style: const TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
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
                        final val = value ?? '';
                        if (val.isEmpty) {
                          return isBn ? 'পাসওয়ার্ড লিখুন' : 'Please enter your password';
                        }
                        return null;
                      },
                    ),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showForgotPasswordDialog,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          isBn ? 'পাসওয়ার্ড ভুলে গেছেন?' : 'Forgot password?',
                          style: const TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Error Box if any
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        margin: const EdgeInsets.only(bottom: 16),
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

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _busy ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          disabledBackgroundColor: primaryColor.withValues(alpha: 0.6),
                          elevation: 3,
                          shadowColor: primaryColor.withValues(alpha: 0.35),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _busy
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                isBn ? 'লগইন' : 'Login',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // OR Divider
                    Row(
                      children: [
                        const Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            isBn ? 'অথবা' : 'or',
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                          ),
                        ),
                        const Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Login with OTP Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: _showOtpNotice,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: primaryColor, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          isBn ? 'ওটিপি দিয়ে লগইন করুন' : 'Login with OTP',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Create Account Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isBn ? 'সাহায্য-এ নতুন? ' : 'New to Sahajjo? ',
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RegisterScreen()),
                            );
                          },
                          child: Text(
                            isBn ? 'নিবন্ধন করুন' : 'Create account',
                            style: const TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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

/// Custom painted logo emblem matching the Sahajjo design
class _SahajjoEmblem extends StatelessWidget {
  final double size;
  const _SahajjoEmblem({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 1.15),
      painter: _SahajjoLogoPainter(),
    );
  }
}

class _SahajjoLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const green = Color(0xFF006A4E);
    const orange = Color(0xFFF59E0B);

    final w = size.width;
    final h = size.height;

    // Outer Document with rounded corners
    final docPaint = Paint()
      ..color = green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final docRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.08, h * 0.05, w * 0.84, h * 0.90),
      const Radius.circular(10),
    );
    canvas.drawRRect(docRRect, docPaint);

    // Inner 'S' circuit curve
    final sPaint = Paint()
      ..color = green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final sPath = Path();
    // Start below dot near upper right
    sPath.moveTo(w * 0.65, h * 0.32);
    // Arc left to upper-left
    sPath.cubicTo(w * 0.55, h * 0.28, w * 0.35, h * 0.28, w * 0.32, h * 0.40);
    // Loop through center to right
    sPath.cubicTo(w * 0.30, h * 0.50, w * 0.68, h * 0.50, w * 0.66, h * 0.62);
    // Loop down to lower left
    sPath.cubicTo(w * 0.64, h * 0.74, w * 0.45, h * 0.75, w * 0.32, h * 0.70);

    canvas.drawPath(sPath, sPaint);

    // Orange indicator dot at top-right of 'S'
    final dotPaint = Paint()..color = orange;
    canvas.drawCircle(Offset(w * 0.66, h * 0.30), 3.2, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
