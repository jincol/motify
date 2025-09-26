import 'package:flutter/material.dart';

class MapPlaceholder extends StatelessWidget {
  const MapPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
              'https://placehold.co/600x300/E2E8F0/4A5568?text=Mapa+en+Vivo',
            ),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
