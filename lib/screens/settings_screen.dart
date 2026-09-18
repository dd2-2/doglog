import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/database_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import 'dog_form_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dogsAsync = ref.watch(dogsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('반려동물 관리')),
      body: dogsAsync.when(
        data: (dogs) => dogs.isEmpty
            ? const EmptyState(icon: Icons.pets, message: '등록된 반려동물이 없어요')
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: dogs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final dog = dogs[i];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.coral.withValues(alpha: 0.15),
                        child: const Icon(Icons.pets, color: AppColors.coralDark),
                      ),
                      title: Text(dog.name),
                      subtitle: Text(dog.breed?.isNotEmpty == true ? dog.breed! : '품종 미입력'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => DogFormScreen(existing: dog)),
                      ),
                    ),
                  );
                },
              ),
        loading: () => const SizedBox(),
        error: (_, __) => const SizedBox(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DogFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('반려동물 추가'),
      ),
    );
  }
}
