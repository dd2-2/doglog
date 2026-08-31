import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import 'database_provider.dart';

final schedulesForDogProvider =
    StreamProvider.family<List<ScheduleItem>, int>((ref, dogId) {
  return ref.watch(databaseProvider).watchSchedulesForDog(dogId);
});

final upcomingSchedulesProvider =
    StreamProvider.family<List<ScheduleItem>, int>((ref, dogId) {
  return ref.watch(databaseProvider).watchUpcomingSchedules(dogId);
});

final weightsForDogProvider =
    StreamProvider.family<List<WeightRecord>, int>((ref, dogId) {
  return ref.watch(databaseProvider).watchWeightsForDog(dogId);
});

final healthLogsForDogProvider =
    StreamProvider.family<List<HealthLog>, int>((ref, dogId) {
  return ref.watch(databaseProvider).watchHealthLogsForDog(dogId);
});

/// 지출 탭에서 조회 중인 월 (매달 1일 기준)
final selectedExpenseMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

final expensesForMonthProvider =
    StreamProvider.family<List<Expense>, int>((ref, dogId) {
  final month = ref.watch(selectedExpenseMonthProvider);
  return ref.watch(databaseProvider).watchExpensesForMonth(dogId, month);
});
