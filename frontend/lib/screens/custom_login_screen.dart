import 'package:flutter/material.dart';

class CustomLoginScreen extends StatefulWidget {
  const CustomLoginScreen({super.key});

  @override
  State<CustomLoginScreen> createState() => _CustomLoginScreenState();
}

class _CustomLoginScreenState extends State<CustomLoginScreen> {
  bool isEnglish = true;
  bool _obscurePassword = true;

  // Localization dictionaries
  final Map<String, String> en = {
    'appName': 'Sahajjo',
    'subtitle': 'Government services, made simple',
    'welcome': 'Welcome back',
    'instruction': 'Sign in to continue your service application',
    'phoneLabel': 'Phone number',
    'phoneHint': '1XXXXXXXXX',
    'passwordLabel': 'Password',
    'show': 'Show',
    'hide': 'Hide',
    'forgotPassword': 'Forgot password?',
    'login': 'Login',
    'or': 'or',
    'loginOtp': 'Login with OTP',
    'newAccount': 'New to Sahajjo? ',
    'createAccount': 'Create account',
  };

  final Map<String, String> bn = {
    'appName': 'সাহায্য',
    'subtitle': 'সরকারি সেবা, সহজ নির্দেশনা',
    'welcome': 'স্বাগতম',
    'instruction': 'আপনার সেবা আবেদন চালিয়ে যেতে সাইন ইন করুন',
    'phoneLabel': 'মোবাইল নম্বর',
    'phoneHint': '১XXXXXXXXX',
    'passwordLabel': 'পাসওয়ার্ড',
    'show': 'দেখুন',
    'hide': 'লুকান',
    'forgotPassword': 'পাসওয়ার্ড ভুলে গেছেন?',
    'login': 'লগইন',
    'or': 'অথবা',
    'loginOtp': 'ওটিপি দিয়ে লগইন করুন',
    'newAccount': 'সাহায্য-এ নতুন? ',
    'createAccount': 'নিবন্ধন করুন',
  };

  @override
  Widget build(BuildContext context) {
    final t = isEnglish ? en : bn;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Green Curved Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 50, bottom: 40),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(40),
                ),
              ),
              child: Column(
                children: [
                  // Language Toggle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            isEnglish = !isEnglish;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isEnglish ? 'বাংলা' : 'English',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // App Logo Placeholder
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.description, 
                        color: primaryColor,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  // App Title
                  Text(
                    t['appName']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  // App Subtitle
                  Text(
                    t['subtitle']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Form Section
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t['welcome']!,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2B21),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t['instruction']!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Phone Number Input
                  Text(
                    t['phoneLabel']!,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF33413B)),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: t['phoneHint'],
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '+880',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              height: 20,
                              width: 1,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFA),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Password Input
                  Text(
                    t['passwordLabel']!,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF33413B)),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      suffixIcon: TextButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        child: Text(
                          _obscurePassword ? t['show']! : t['hide']!,
                          style: TextStyle(color: primaryColor),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFA),
                    ),
                  ),
                  
                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: Text(
                        t['forgotPassword']!,
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        // Call AuthProvider login method here
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: primaryColor.withValues(alpha: 0.4),
                      ),
                      child: Text(
                        t['login']!,
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
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          t['or']!,
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Login with OTP Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: OutlinedButton(
                      onPressed: () {
                        // Add OTP navigation or logic here
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        t['loginOtp']!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        t['newAccount']!,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Navigate to Registration Screen
                        },
                        child: Text(
                          t['createAccount']!,
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
