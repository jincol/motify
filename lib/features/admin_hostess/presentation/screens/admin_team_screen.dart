import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motify/core/widgets/team_list_view.dart';
import 'package:motify/features/admin_hostess/application/users_providers.dart';
import '../widgets/hostess_card.dart';

class AdminTeamScreen extends ConsumerWidget {
  const AdminTeamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(anfitrionaUsersProvider);

    return usersAsync.when(
      data: (users) => TeamListView(
        users: users,
        filters: const [],
        itemBuilder: (context, user) => HostessCard(
          user: user,
          onEdit: () {},
          onDelete: () {},
          onView: () {},
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}
