import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/auth_notifier.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authNotifier = ref.read(authNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Motify - Home'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authNotifier.logout(),
          ),
        ],
      ),
      body: const Center(
        child: Text('Bienvenido al Home!', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
