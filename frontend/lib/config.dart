class AppConfig {
  // Android emulator reaches the host machine at 10.0.2.2.
  // For a physical device use your computer's LAN IP, or pass at build time:
  //   flutter run --dart-define=API_BASE_URL=http://192.168.0.10:4000/api
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:4000/api',
  );
}
