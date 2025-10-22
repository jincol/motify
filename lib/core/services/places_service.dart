import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/place_suggestion.dart';
import '../constants/google_maps_config.dart';

class PlacesService {
  // Usar serverApiKey (sin restricciones) para HTTP requests
  static const String _apiKey = GoogleMapsConfig.serverApiKey;

  // URLs de la API
  static const String _autocompleteUrl =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  static const String _placeDetailsUrl =
      'https://maps.googleapis.com/maps/api/place/details/json';

  // Timer para debounce
  Timer? _debounceTimer;

  // Cache simple para evitar búsquedas duplicadas
  final Map<String, List<PlaceSuggestion>> _cache = {};

  /// Busca lugares con autocompletar
  /// [input] - Texto ingresado por el usuario (mínimo 3 caracteres)
  /// [debounceMs] - Milisegundos de espera antes de hacer la búsqueda (default: 500ms)
  Future<List<PlaceSuggestion>> searchPlaces({
    required String input,
    int debounceMs = 500,
  }) async {
    // No buscar si el input es muy corto
    if (input.length < 3) {
      return [];
    }

    // Cancelar búsqueda anterior si existe
    _debounceTimer?.cancel();

    // Verificar cache
    if (_cache.containsKey(input)) {
      return _cache[input]!;
    }

    // Crear un Completer para manejar el debounce
    final completer = Completer<List<PlaceSuggestion>>();

    _debounceTimer = Timer(Duration(milliseconds: debounceMs), () async {
      try {
        final results = await _fetchAutocomplete(input);
        _cache[input] = results; // Guardar en cache
        completer.complete(results);
      } catch (e) {
        completer.completeError(e);
      }
    });

    return completer.future;
  }

  /// Busca lugares SIN debounce (útil para llamadas directas)
  Future<List<PlaceSuggestion>> searchPlacesImmediate(String input) async {
    if (input.length < 3) {
      return [];
    }

    // Verificar cache
    if (_cache.containsKey(input)) {
      return _cache[input]!;
    }

    final results = await _fetchAutocomplete(input);
    _cache[input] = results;
    return results;
  }

  /// Realiza la petición HTTP a Places API Autocomplete
  Future<List<PlaceSuggestion>> _fetchAutocomplete(String input) async {
    final url = Uri.parse(_autocompleteUrl).replace(
      queryParameters: {
        'input': input,
        'key': _apiKey,
        'components': 'country:pe', // Solo resultados de Perú
        'language': 'es', // Idioma español
        'types': 'geocode|establishment', // Direcciones y establecimientos
      },
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final status = json['status'] as String;

      if (status == 'OK') {
        final predictions = json['predictions'] as List<dynamic>;
        return predictions
            .map(
              (pred) => PlaceSuggestion.fromJson(pred as Map<String, dynamic>),
            )
            .toList();
      } else if (status == 'ZERO_RESULTS') {
        return [];
      } else {
        throw Exception('Places API error: $status');
      }
    } else {
      throw Exception('HTTP error: ${response.statusCode}');
    }
  }

  /// Obtiene los detalles completos de un lugar (incluyendo coordenadas)
  /// [placeId] - ID del lugar obtenido de autocomplete
  Future<PlaceSuggestion> getPlaceDetails(String placeId) async {
    final url = Uri.parse(_placeDetailsUrl).replace(
      queryParameters: {
        'place_id': placeId,
        'key': _apiKey,
        'fields':
            'place_id,formatted_address,name,geometry', // Solo campos necesarios
        'language': 'es',
      },
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final status = json['status'] as String;

      if (status == 'OK') {
        return PlaceSuggestion.fromPlaceDetails(json);
      } else {
        throw Exception('Place Details error: $status');
      }
    } else {
      throw Exception('HTTP error: ${response.statusCode}');
    }
  }

  /// Limpia el cache (útil para liberar memoria)
  void clearCache() {
    _cache.clear();
  }

  /// Cancela el timer de debounce
  void dispose() {
    _debounceTimer?.cancel();
    _cache.clear();
  }
}
