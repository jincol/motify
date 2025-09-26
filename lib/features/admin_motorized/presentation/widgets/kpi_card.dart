import 'package:flutter/material.dart';

class KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final bool isFullWidth;
  final bool compact;

  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.isFullWidth = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: compact
            ? const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0)
            : const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.black54,
                fontSize: compact ? 12 : 14,
              ),
            ),
            SizedBox(height: compact ? 4 : 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: compact ? 20 : 28,
                    color: Colors.black87,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: compact ? 14 : 18,
                      color: Colors.black54,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
