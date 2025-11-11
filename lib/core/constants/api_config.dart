class ApiConfig {
  // Detecta el entorno
  static const bool isProduction = bool.fromEnvironment(
    'PRODUCTION',
    defaultValue: false, // Cambia a true cuando compiles para producción
  );
  
  static String get baseUrl {
    if (isProduction) {
      // 🚀 Producción - Render
      return 'https://motify-tahi.onrender.com/api/v1';
    } else {
      // 🏠 Desarrollo local
      return 'http://192.168.1.90:8000/api/v1';
    }
  }

  static String get baseHost {
    const suffix = '/api/v1';
    if (baseUrl.endsWith(suffix)) {
      print('Removing suffix from baseUrl: $baseUrl');
      return baseUrl.substring(0, baseUrl.length - suffix.length);
    }
    return baseUrl;
  }

  static String get baseApiUrl {
    const suffix = '/api/v1';
    if (baseUrl.endsWith(suffix)) return baseUrl;
    if (baseUrl.endsWith('/')) return '${baseUrl}api/v1';
    print('Adding suffix to baseUrl: $baseUrl');
    return '$baseUrl$suffix';
  }
}