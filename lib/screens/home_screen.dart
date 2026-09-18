import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../providers/database_provider.dart';
import '../providers/record_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/dog_selector.dart';
import '../widgets/empty_state.dart';
import 'dog_form_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dog = ref.watch(selectedDogProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('petlog'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 4),
          DogSelector(
            onAddDog: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DogFormScreen()),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: dog == null
                ? EmptyState(
                    icon: Icons.pets,
                    message: '등록된 반려동물이 없어요.\n먼저 반려동물을 등록해주세요.',
                    actionLabel: '반려동물 등록',
                    onAction: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DogFormScreen()),
                    ),
                  )
                : _HomeBody(dog: dog),
          ),
        ],
      ),
    );
  }
}

class _HomeBody extends ConsumerWidget {
  const _HomeBody({required this.dog});

  final Dog dog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = ref.watch(upcomingSchedulesProvider(dog.id));
    final expenses = ref.watch(expensesForMonthProvider(dog.id));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        _buildProfileCard(context),
        const SizedBox(height: 20),
        const Text('다가오는 일정', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        upcoming.when(
          data: (items) => items.isEmpty
              ? const _MiniEmpty(text: '2주 내 예정된 일정이 없어요')
              : Column(children: [for (final s in items) _ScheduleTile(item: s)]),
          loading: () => const SizedBox(),
          error: (_, __) => const SizedBox(),
        ),
        const SizedBox(height: 20),
        const Text('이번 달 지출', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        expenses.when(
          data: (list) {
            final total = list.fold<double>(0, (sum, e) => sum + e.amount);
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('총 지출', style: TextStyle(color: AppColors.inkLight)),
                    Text(
                      '${NumberFormat('#,###').format(total)}원',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const SizedBox(),
          error: (_, __) => const SizedBox(),
        ),
      ],
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    final age = dog.birthDate != null
        ? (DateTime.now().difference(dog.birthDate!).inDays / 365).floor()
        : null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.coral.withValues(alpha: 0.15),
              backgroundImage:
                  dog.photoPath != null ? FileImage(File(dog.photoPath!)) : null,
              child: dog.photoPath == null
                  ? const Icon(Icons.pets, color: AppColors.coralDark, size: 28)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dog.name,
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (dog.breed != null && dog.breed!.isNotEmpty) dog.breed!,
                      if (age != null) '$age살',
                    ].join(' · '),
                    style: const TextStyle(color: AppColors.inkLight, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({required this.item});

  final ScheduleItem item;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(item.nextDueDate.year, item.nextDueDate.month, item.nextDueDate.day);
    final days = due.difference(today).inDays;
    final dDay = days == 0 ? 'D-Day' : (days > 0 ? 'D-$days' : 'D+${-days}');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.mint.withValues(alpha: 0.18),
          child: Text(dDay,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ink)),
        ),
        title: Text(item.title),
        subtitle: Text(DateFormat('yyyy.MM.dd').format(item.nextDueDate)),
      ),
    );
  }
}

class _MiniEmpty extends StatelessWidget {
  const _MiniEmpty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(text, style: const TextStyle(color: AppColors.inkLight)),
    );
  }
}
