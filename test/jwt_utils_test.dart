import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:motify/core/utils/jwt_utils.dart';

// Nota: este test crea un JWT falso con payload solo para test (sin firma real)
// Estructura: header.payload.signature (payload base64url)
String _makeTokenWithExp(int exp) {
  final header = base64Url.encode(utf8.encode('{"alg":"none"}'));
  final payload = base64Url.encode(utf8.encode('{"exp":$exp}'));
  return '$header.$payload.';
}

void main() {
  test('expiresSoon returns true for token expiring in 10s', () {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    final token = _makeTokenWithExp(now + 10);
    final result = expiresSoon(token, thresholdSeconds: 60);
    expect(result, isTrue);
  });

  test('expiresSoon returns false for token expiring later', () {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    final token = _makeTokenWithExp(now + 3600);
    final result = expiresSoon(token, thresholdSeconds: 60);
    expect(result, isFalse);
  });
}
