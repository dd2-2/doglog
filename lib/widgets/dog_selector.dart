import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../providers/database_provider.dart';
import '../theme/app_theme.dart';

/// 상단 반려견 선택/전환 칩 목록. 다견 지원의 핵심 UI.
class DogSelector extends ConsumerWidget {
  const DogSelector({super.key, required this.onAddDog});

  final VoidCallback onAddDog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dogsAsync = ref.watch(dogsStreamProvider);
    final selectedId = ref.watch(selectedDogProvider)?.id;

    return dogsAsync.when(
      data: (dogs) => SizedBox(
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            for (final dog in dogs)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _DogChip(
                  dog: dog,
                  selected: dog.id == selectedId,
                  onTap: () =>
                      ref.read(selectedDogIdProvider.notifier).state = dog.id,
                ),
              ),
            ActionChip(
              avatar: const Icon(Icons.add, size: 18),
              label: const Text('반려동물 추가'),
              onPressed: onAddDog,
              backgroundColor: AppColors.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.divider),
              ),
            ),
          ],
        ),
      ),
      loading: () => const SizedBox(height: 44),
      error: (_, __) => const SizedBox(height: 44),
    );
  }
}

class _DogChip extends StatelessWidget {
  const _DogChip({
    required this.dog,
    required this.selected,
    required this.onTap,
  });

  final Dog dog;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onTap(),
      avatar: CircleAvatar(
        radius: 12,
        backgroundColor: AppColors.coral.withValues(alpha: 0.15),
        backgroundImage:
            dog.photoPath != null ? FileImage(File(dog.photoPath!)) : null,
        child: dog.photoPath == null
            ? const Icon(Icons.pets, size: 14, color: AppColors.coralDark)
            : null,
      ),
      label: Text(dog.name),
      selectedColor: AppColors.coral.withValues(alpha: 0.18),
      backgroundColor: AppColors.cardBg,
      labelStyle: TextStyle(
        color: selected ? AppColors.coralDark : AppColors.ink,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? AppColors.coral : AppColors.divider,
        ),
      ),
    );
  }
}
