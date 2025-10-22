/// Modelo para manejar sugerencias de Google Places API
class PlaceSuggestion {
  final String placeId;
  final String description;
  final String mainText;
  final String? secondaryText;
  double? latitude;
  double? longitude;

  PlaceSuggestion({
    required this.placeId,
    required this.description,
    required this.mainText,
    this.secondaryText,
    this.latitude,
    this.longitude,
  });

  /// Constructor desde JSON de Places API Autocomplete
  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    final structuredFormatting =
        json['structured_formatting'] as Map<String, dynamic>?;

    return PlaceSuggestion(
      placeId: json['place_id'] as String,
      description: json['description'] as String,
      mainText:
          structuredFormatting?['main_text'] as String? ??
          json['description'] as String,
      secondaryText: structuredFormatting?['secondary_text'] as String?,
    );
  }

  /// Constructor desde Place Details (con coordenadas)
  factory PlaceSuggestion.fromPlaceDetails(Map<String, dynamic> json) {
    final result = json['result'] as Map<String, dynamic>;
    final geometry = result['geometry'] as Map<String, dynamic>;
    final location = geometry['location'] as Map<String, dynamic>;

    return PlaceSuggestion(
      placeId: result['place_id'] as String,
      description: result['formatted_address'] as String,
      mainText:
          result['name'] as String? ?? result['formatted_address'] as String,
      secondaryText: result['formatted_address'] as String,
      latitude: location['lat'] as double,
      longitude: location['lng'] as double,
    );
  }

  /// Copia con coordenadas actualizadas
  PlaceSuggestion copyWith({
    String? placeId,
    String? description,
    String? mainText,
    String? secondaryText,
    double? latitude,
    double? longitude,
  }) {
    return PlaceSuggestion(
      placeId: placeId ?? this.placeId,
      description: description ?? this.description,
      mainText: mainText ?? this.mainText,
      secondaryText: secondaryText ?? this.secondaryText,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  /// Convierte a JSON para guardar en base de datos
  Map<String, dynamic> toJson() {
    return {
      'place_id': placeId,
      'description': description,
      'main_text': mainText,
      'secondary_text': secondaryText,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  @override
  String toString() {
    return 'PlaceSuggestion(placeId: $placeId, description: $description, lat: $latitude, lng: $longitude)';
  }
}
