import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motify/core/widgets/team_list_view.dart';
// import 'package:motify/features/admin_hostess/application/users_providers.dart';
import 'package:motify/core/providers/admin_users_notifier.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../widgets/hostess_card.dart';
import 'anfitriona_detail_page.dart';

typedef OnUserDeleted = void Function();

class AdminTeamScreen extends ConsumerStatefulWidget {
  final OnUserDeleted? onUserDeleted;
  const AdminTeamScreen({super.key, this.onUserDeleted});

  @override
  ConsumerState<AdminTeamScreen> createState() => _AdminTeamScreenState();
}

class _AdminTeamScreenState extends ConsumerState<AdminTeamScreen> {
  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminHostessUsersProvider);

    return usersAsync.when(
      data: (users) => TeamListView(
        users: users,
        filters: const [],
        itemBuilder: (context, user) => Slidable(
          key: ValueKey(user.id),
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            children: [
              SlidableAction(
                flex: 2,
                onPressed: (context) async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirmar eliminación'),
                      content: const Text(
                        '¿Estás seguro de que deseas eliminar esta anfitriona?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text(
                            'Eliminar',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    try {
                      await ref
                          .read(adminHostessUsersProvider.notifier)
                          .deleteUser(user.id);
                      if (widget.onUserDeleted != null) {
                        widget.onUserDeleted!();
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error al eliminar anfitriona: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                icon: Icons.delete,
                label: 'Eliminar',
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
            ],
          ),
          child: GestureDetector(
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
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}
