import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../data/database.dart';
import '../providers/database_provider.dart';
import '../providers/record_providers.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/soft_card.dart';
import 'schedule_form_screen.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final dog = ref.watch(selectedDogProvider);

    if (dog == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('일정')),
        body: const EmptyState(icon: Icons.event_note, message: '먼저 홈에서 반려동물을 등록해주세요'),
      );
    }

    final schedulesAsync = ref.watch(schedulesForDogProvider(dog.id));

    return Scaffold(
      appBar: AppBar(title: const Text('일정')),
      body: schedulesAsync.when(
        data: (items) {
          final eventsByDay = <DateTime, List<ScheduleItem>>{};
          for (final item in items) {
            final day = _dateOnly(item.nextDueDate);
            eventsByDay.putIfAbsent(day, () => []).add(item);
          }
          final selectedKey = _dateOnly(_selectedDay ?? _focusedDay);
          final dayItems = eventsByDay[selectedKey] ?? [];

          return Column(
            children: [
              GestureDetector(
                onDoubleTap: () => _openForm(context, dog),
                child: TableCalendar<ScheduleItem>(
                  firstDay: DateTime.now().subtract(const Duration(days: 365)),
                  lastDay: DateTime.now().add(const Duration(days: 730)),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) =>
                      _selectedDay != null && isSameDay(_selectedDay, day),
                  eventLoader: (day) => eventsByDay[_dateOnly(day)] ?? [],
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  calendarStyle: const CalendarStyle(
                    todayDecoration: BoxDecoration(
                        color: Color(0x33141414), shape: BoxShape.circle),
                    selectedDecoration:
                        BoxDecoration(color: AppColors.coral, shape: BoxShape.circle),
                    markerDecoration:
                        BoxDecoration(color: AppColors.mint, shape: BoxShape.circle),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: dayItems.isEmpty
                    ? const EmptyState(
                        icon: Icons.event_available, message: '이 날 예정된 일정이 없어요')
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: dayItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) =>
                            _ScheduleCard(item: dayItems[i], dog: dog),
                      ),
              ),
            ],
          );
        },
        loading: () => const SizedBox(),
        error: (_, __) => const SizedBox(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context, dog),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openForm(BuildContext context, Dog dog) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScheduleFormScreen(
          dog: dog,
          initialDate: _selectedDay ?? _focusedDay,
        ),
      ),
    );
  }
}

class _ScheduleCard extends ConsumerWidget {
  const _ScheduleCard({required this.item, required this.dog});

  final ScheduleItem item;
  final Dog dog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SoftCard(
      child: ListTile(
        leading: Checkbox(
          value: false,
          onChanged: (_) async {
            final db = ref.read(databaseProvider);
            await db.completeSchedule(item);
            if (item.notifyEnabled) {
              final updated = item.intervalDays != null
                  ? DateTime.now().add(Duration(days: item.intervalDays!))
                  : DateTime.now();
              await NotificationService.instance.scheduleForItem(
                scheduleId: item.id,
                dogName: dog.name,
                title: item.title,
                dueDate: updated,
              );
            }
          },
        ),
        title: Text(item.title),
        subtitle: Text(
          [
            DateFormat('yyyy.MM.dd').format(item.nextDueDate),
            if (item.intervalDays != null) '${item.intervalDays}일마다 반복',
          ].join(' · '),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ScheduleFormScreen(dog: dog, existing: item),
          ),
        ),
      ),
    );
  }
}
