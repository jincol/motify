class ApiConfig {
  // Default targets Android emulator mapping to host machine.
  // For emulator: http://10.0.2.2:8000
  // For a physical device on the same LAN: http://192.168.31.166:8000 (example)
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.31.166:8000/api/v1',
  );
}
