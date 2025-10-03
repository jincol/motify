import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motify/core/widgets/team_list_view.dart';
// import 'package:motify/features/admin_hostess/application/users_providers.dart';
import 'package:motify/core/providers/admin_users_notifier.dart';
import '../widgets/hostess_card.dart';
import 'anfitriona_detail_page.dart';

class AdminTeamScreen extends ConsumerWidget {
  const AdminTeamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminHostessUsersProvider);

    return usersAsync.when(
      data: (users) => TeamListView(
        users: users,
        filters: const [],
        itemBuilder: (context, user) => GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AnfitrionaDetailPage(user: user),
              ),
            );
          },
          child: HostessCard(
            user: user,
            onEdit: () {},
            onDelete: () {},
            onView: () {},
          ),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}
