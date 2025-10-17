import 'package:flutter/material.dart';

class PanelAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Color backgroundColor;
  final Color textColor;
  final bool showBackArrow;

  const PanelAppBar({
    super.key,
    required this.title,
    this.actions,
    this.backgroundColor = const Color(0xFFF97316),
    this.textColor = Colors.white,
    this.showBackArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 1.0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(
            showBackArrow ? Icons.arrow_back : Icons.menu,
            color: textColor,
          ),
          onPressed: () {
            if (showBackArrow) {
              Navigator.of(context).maybePop();
            } else {
              Scaffold.of(context).openDrawer();
            }
          },
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      centerTitle: true,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
