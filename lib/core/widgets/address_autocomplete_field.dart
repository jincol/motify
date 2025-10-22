import 'package:flutter/material.dart';
import '../models/place_suggestion.dart';
import '../services/places_service.dart';

/// Widget de autocompletar dirección estilo Google Maps
/// Muestra un TextField con sugerencias mientras el usuario escribe
class AddressAutocompleteField extends StatefulWidget {
  final String? initialValue;
  final String hintText;
  final Function(PlaceSuggestion) onPlaceSelected;
  final bool enabled;

  const AddressAutocompleteField({
    super.key,
    this.initialValue,
    this.hintText = 'Buscar dirección...',
    required this.onPlaceSelected,
    this.enabled = true,
  });

  @override
  State<AddressAutocompleteField> createState() =>
      _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState extends State<AddressAutocompleteField> {
  final TextEditingController _controller = TextEditingController();
  final PlacesService _placesService = PlacesService();
  final FocusNode _focusNode = FocusNode();

  List<PlaceSuggestion> _suggestions = [];
  bool _isLoading = false;
  bool _showSuggestions = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
    }

    // Listener para detectar cambios en el texto
    _controller.addListener(_onTextChanged);

    // Listener para detectar cuando pierde el foco
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        // Esperar un poco antes de ocultar (para permitir selección)
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() {
              _showSuggestions = false;
            });
          }
        });
      }
    });
  }

  void _onTextChanged() {
    final text = _controller.text;

    if (text.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
        _errorMessage = null;
      });
      return;
    }

    if (text.length < 3) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
        _errorMessage = 'Ingresa al menos 3 caracteres';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _showSuggestions = true;
      _errorMessage = null;
    });

    // Buscar con debounce automático del servicio
    _placesService
        .searchPlaces(input: text)
        .then((suggestions) {
          if (mounted) {
            setState(() {
              _suggestions = suggestions;
              _isLoading = false;
              if (suggestions.isEmpty) {
                _errorMessage = 'No se encontraron resultados';
              }
            });
          }
        })
        .catchError((error) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Error al buscar: $error';
            });
          }
        });
  }

  Future<void> _onSuggestionTap(PlaceSuggestion suggestion) async {
    // Ocultar teclado
    _focusNode.unfocus();

    setState(() {
      _controller.text = suggestion.description;
      _showSuggestions = false;
      _isLoading = true;
    });

    try {
      // Obtener coordenadas completas del lugar
      final placeWithCoords = await _placesService.getPlaceDetails(
        suggestion.placeId,
      );

      setState(() {
        _isLoading = false;
      });

      // Notificar al padre
      widget.onPlaceSelected(placeWithCoords);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al obtener detalles: $e';
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _placesService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // TextField principal
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            suffixIcon: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      setState(() {
                        _suggestions = [];
                        _showSuggestions = false;
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
          ),
        ),

        // Mensaje de error
        if (_errorMessage != null && !_isLoading)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),

        // Lista de sugerencias
        if (_showSuggestions && _suggestions.isNotEmpty && !_isLoading)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _suggestions.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.red),
                  title: Text(
                    suggestion.mainText,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: suggestion.secondaryText != null
                      ? Text(
                          suggestion.secondaryText!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        )
                      : null,
                  onTap: () => _onSuggestionTap(suggestion),
                  dense: true,
                );
              },
            ),
          ),
      ],
    );
  }
}
