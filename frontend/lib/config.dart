import 'package:flutter/foundation.dart';

class AppConfig {
  // Android emulator reaches host machine at 10.0.2.2.
  // Chrome, Edge, and Windows desktop connect directly via localhost.
  static String get apiBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;

    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return 'http://localhost:4000/api';
    }

    // Default for Android Emulator
    return 'http://10.0.2.2:4000/api';
  }
}
