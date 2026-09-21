import 'database.dart';

/// AppDatabase(drift/sqlite, 모바일)와 MockAppDatabase(인메모리, 웹 프리뷰)가
/// 공통으로 구현하는 인터페이스. 화면/프로바이더는 이 타입만 알면 된다.
abstract class PetlogDb {
  // ---- Dogs ----
  Stream<List<Dog>> watchDogs();
  Future<int> addDog(DogsCompanion entry);
  Future<void> updateDog(Dog dog);
  Future<void> deleteDog(int id);

  // ---- Schedule ----
  Stream<List<ScheduleItem>> watchSchedulesForDog(int dogId);
  Stream<List<ScheduleItem>> watchUpcomingSchedules(int dogId, {int days = 14});
  Future<int> addSchedule(ScheduleItemsCompanion entry);
  Future<void> updateSchedule(ScheduleItem item);
  Future<void> deleteSchedule(int id);
  Future<void> completeSchedule(ScheduleItem item);

  // ---- Weight ----
  Stream<List<WeightRecord>> watchWeightsForDog(int dogId);
  Future<int> addWeight(WeightRecordsCompanion entry);
  Future<bool> updateWeight(WeightRecord entry);
  Future<void> deleteWeight(int id);

  // ---- Health logs ----
  Stream<List<HealthLog>> watchHealthLogsForDog(int dogId);
  Future<int> addHealthLog(HealthLogsCompanion entry);
  Future<bool> updateHealthLog(HealthLog entry);
  Future<void> deleteHealthLog(int id);

  // ---- Expenses ----
  Stream<List<Expense>> watchExpensesForMonth(int dogId, DateTime month);
  Future<int> addExpense(ExpensesCompanion entry);
  Future<void> deleteExpense(int id);

  Future<void> close();
}
