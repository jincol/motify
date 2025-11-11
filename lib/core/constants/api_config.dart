class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    //Cable
    // defaultValue: 'http://192.168.1.90:8000/api/v1',
    // #Wifi
    defaultValue: 'http://192.168.1.90:8000/api/v1',
  );

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
    if (baseUrl.endsWith('/')) return baseUrl + 'api/v1';
    print('Removing suffix from baseUrl: $baseUrl');
    return baseUrl + suffix;
  }
}
