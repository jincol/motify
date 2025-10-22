import 'dart:convert';

/// Decodifica el payload de un JWT (sin verificar) y devuelve el mapa.
Map<String, dynamic>? decodeJwtPayload(String token) {
  try {
    String _normalize(String str) {
      final mod = str.length % 4;
      if (mod == 2) return str + '==';
      if (mod == 3) return str + '=';
      if (mod == 1) return str + '===';
      return str;
    }

    final parts = token.split('.');
    if (parts.length < 2) return null;
    final payload = parts[1];
    final normalized = _normalize(
      payload.replaceAll('-', '+').replaceAll('_', '/'),
    );
    final decoded = jsonDecode(String.fromCharCodes(base64.decode(normalized)));
    return Map<String, dynamic>.from(decoded);
  } catch (_) {
    return null;
  }
}

/// Retorna true si el token expira en menos de [thresholdSeconds] segundos.
bool expiresSoon(String token, {int thresholdSeconds = 60}) {
  final payload = decodeJwtPayload(token);
  if (payload == null) return false;
  final exp = payload['exp'];
  if (exp is int) {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    return exp < (now + thresholdSeconds);
  }
  return false;
}
