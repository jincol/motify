import 'package:flutter/material.dart';

class TeamListView<T> extends StatelessWidget {
  final List<T> users;
  final List<Widget> filters;
  final Widget Function(BuildContext, T) itemBuilder;

  const TeamListView({
    super.key,
    required this.users,
    required this.filters,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Wrap(spacing: 8.0, children: filters),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            itemCount: users.length,
            itemBuilder: (context, index) => itemBuilder(context, users[index]),
          ),
        ),
      ],
    );
  }
}
