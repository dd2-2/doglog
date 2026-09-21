import 'package:drift/drift.dart';

import 'connection/connection.dart' as conn;
import 'petlog_db.dart';

part 'database.g.dart';

enum ScheduleType { vaccination, heartworm, deworming, bath, grooming, teeth, other }

enum HealthLogType { vetVisit, medication, other }

enum ExpenseCategory { vet, food, grooming, supplies, other }

extension ScheduleTypeLabel on ScheduleType {
  String get label => switch (this) {
        ScheduleType.vaccination => '예방접종',
        ScheduleType.heartworm => '심장사상충',
        ScheduleType.deworming => '구충',
        ScheduleType.bath => '목욕',
        ScheduleType.grooming => '미용',
        ScheduleType.teeth => '양치',
        ScheduleType.other => '기타',
      };
}

extension HealthLogTypeLabel on HealthLogType {
  String get label => switch (this) {
        HealthLogType.vetVisit => '병원방문',
        HealthLogType.medication => '투약',
        HealthLogType.other => '기타',
      };
}

extension ExpenseCategoryLabel on ExpenseCategory {
  String get label => switch (this) {
        ExpenseCategory.vet => '병원비',
        ExpenseCategory.food => '사료비',
        ExpenseCategory.grooming => '미용비',
        ExpenseCategory.supplies => '용품비',
        ExpenseCategory.other => '기타',
      };
}

class Dogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get breed => text().nullable()();
  DateTimeColumn get birthDate => dateTime().nullable()();
  TextColumn get photoPath => text().nullable()();
}

class ScheduleItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dogId => integer().references(Dogs, #id, onDelete: KeyAction.cascade)();
  IntColumn get type => intEnum<ScheduleType>()();
  TextColumn get title => text()();
  IntColumn get intervalDays => integer().nullable()();
  DateTimeColumn get lastDoneDate => dateTime().nullable()();
  DateTimeColumn get nextDueDate => dateTime()();
  TextColumn get memo => text().nullable()();
  BoolColumn get notifyEnabled => boolean().withDefault(const Constant(true))();
}

class WeightRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dogId => integer().references(Dogs, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get date => dateTime()();
  RealColumn get weightKg => real()();
}

class HealthLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dogId => integer().references(Dogs, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get date => dateTime()();
  IntColumn get type => intEnum<HealthLogType>()();
  TextColumn get title => text()();
  TextColumn get memo => text().nullable()();
}

class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dogId => integer().references(Dogs, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get date => dateTime()();
  IntColumn get category => intEnum<ExpenseCategory>()();
  RealColumn get amount => real()();
  TextColumn get memo => text().nullable()();
}

@DriftDatabase(tables: [Dogs, ScheduleItems, WeightRecords, HealthLogs, Expenses])
class AppDatabase extends _$AppDatabase implements PetlogDb {
  AppDatabase() : super(conn.openConnection());

  @override
  int get schemaVersion => 1;

  // ---- Dogs ----
  Stream<List<Dog>> watchDogs() => select(dogs).watch();

  Future<int> addDog(DogsCompanion entry) => into(dogs).insert(entry);

  Future<void> updateDog(Dog dog) => update(dogs).replace(dog);

  Future<void> deleteDog(int id) =>
      (delete(dogs)..where((t) => t.id.equals(id))).go();

  // ---- Schedule ----
  Stream<List<ScheduleItem>> watchSchedulesForDog(int dogId) => (select(scheduleItems)
        ..where((t) => t.dogId.equals(dogId))
        ..orderBy([(t) => OrderingTerm.asc(t.nextDueDate)]))
      .watch();

  Stream<List<ScheduleItem>> watchUpcomingSchedules(int dogId, {int days = 14}) {
    final until = DateTime.now().add(Duration(days: days));
    return (select(scheduleItems)
          ..where((t) => t.dogId.equals(dogId) & t.nextDueDate.isSmallerOrEqualValue(until))
          ..orderBy([(t) => OrderingTerm.asc(t.nextDueDate)]))
        .watch();
  }

  Future<int> addSchedule(ScheduleItemsCompanion entry) => into(scheduleItems).insert(entry);

  Future<void> updateSchedule(ScheduleItem item) => update(scheduleItems).replace(item);

  Future<void> deleteSchedule(int id) =>
      (delete(scheduleItems)..where((t) => t.id.equals(id))).go();

  /// 완료 체크: 오늘을 lastDoneDate로 기록하고, 주기가 있으면 다음 회차 날짜로 nextDueDate 갱신
  Future<void> completeSchedule(ScheduleItem item) {
    final now = DateTime.now();
    final next = item.intervalDays != null
        ? now.add(Duration(days: item.intervalDays!))
        : now;
    return update(scheduleItems).replace(
      item.copyWith(lastDoneDate: Value(now), nextDueDate: next),
    );
  }

  // ---- Weight ----
  Stream<List<WeightRecord>> watchWeightsForDog(int dogId) => (select(weightRecords)
        ..where((t) => t.dogId.equals(dogId))
        ..orderBy([(t) => OrderingTerm.asc(t.date)]))
      .watch();

  Future<int> addWeight(WeightRecordsCompanion entry) => into(weightRecords).insert(entry);

  Future<bool> updateWeight(WeightRecord entry) => update(weightRecords).replace(entry);

  Future<void> deleteWeight(int id) =>
      (delete(weightRecords)..where((t) => t.id.equals(id))).go();

  // ---- Health logs ----
  Stream<List<HealthLog>> watchHealthLogsForDog(int dogId) => (select(healthLogs)
        ..where((t) => t.dogId.equals(dogId))
        ..orderBy([(t) => OrderingTerm.desc(t.date)]))
      .watch();

  Future<int> addHealthLog(HealthLogsCompanion entry) => into(healthLogs).insert(entry);

  Future<bool> updateHealthLog(HealthLog entry) => update(healthLogs).replace(entry);

  Future<void> deleteHealthLog(int id) =>
      (delete(healthLogs)..where((t) => t.id.equals(id))).go();

  // ---- Expenses ----
  Stream<List<Expense>> watchExpensesForMonth(int dogId, DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    return (select(expenses)
          ..where((t) =>
              t.dogId.equals(dogId) &
              t.date.isBiggerOrEqualValue(start) &
              t.date.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  Future<int> addExpense(ExpensesCompanion entry) => into(expenses).insert(entry);

  Future<void> deleteExpense(int id) =>
      (delete(expenses)..where((t) => t.id.equals(id))).go();
}
