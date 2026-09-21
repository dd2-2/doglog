import 'dart:async';

import 'package:drift/drift.dart' show Value;

import 'database.dart';
import 'petlog_db.dart';

/// 파일시스템이 없는 플랫폼(웹 프리뷰)에서 쓰는 인메모리 DB.
/// 실제 sqlite 대신 List + Stream.multi로 drift의 반응형 watch()를 흉내낸다.
/// 새로고침하면 데이터가 초기 시드 상태로 리셋된다(브라우저 미리보기 용도라 영구 저장 불필요).
class MockAppDatabase implements PetlogDb {
  final _dogs = _Watchable<Dog>();
  final _schedules = _Watchable<ScheduleItem>();
  final _weights = _Watchable<WeightRecord>();
  final _healthLogs = _Watchable<HealthLog>();
  final _expenses = _Watchable<Expense>();

  int _nextDogId = 1;
  int _nextScheduleId = 1;
  int _nextWeightId = 1;
  int _nextHealthLogId = 1;
  int _nextExpenseId = 1;

  MockAppDatabase() {
    _seed();
  }

  void _seed() {
    final now = DateTime.now();
    final dogId = _nextDogId++;
    _dogs.items = [
      Dog(
        id: dogId,
        name: '맹구',
        breed: '골든리트리버',
        birthDate: DateTime(now.year - 3, 3, 15),
        photoPath: 'asset:assets/demo/mangu.jpg',
      ),
    ];

    _schedules.items = [
      ScheduleItem(
        id: _nextScheduleId++,
        dogId: dogId,
        type: ScheduleType.vaccination,
        title: '종합백신',
        intervalDays: 365,
        nextDueDate: now.add(const Duration(days: 5)),
        notifyEnabled: true,
      ),
      ScheduleItem(
        id: _nextScheduleId++,
        dogId: dogId,
        type: ScheduleType.bath,
        title: '목욕',
        intervalDays: 30,
        nextDueDate: now.add(const Duration(days: 2)),
        notifyEnabled: true,
      ),
    ];

    _weights.items = [
      for (final (i, w) in const [5.2, 5.3, 5.4, 5.5, 5.6].indexed)
        WeightRecord(
          id: _nextWeightId++,
          dogId: dogId,
          date: now.subtract(Duration(days: (4 - i) * 14)),
          weightKg: w,
        ),
    ];

    _healthLogs.items = [
      HealthLog(
        id: _nextHealthLogId++,
        dogId: dogId,
        date: now.subtract(const Duration(days: 10)),
        type: HealthLogType.vetVisit,
        title: '정기검진',
        memo: '이상 없음',
      ),
    ];

    _expenses.items = [
      Expense(
        id: _nextExpenseId++,
        dogId: dogId,
        date: DateTime(now.year, now.month, 3),
        category: ExpenseCategory.food,
        amount: 35000,
        memo: '사료 구매',
      ),
      Expense(
        id: _nextExpenseId++,
        dogId: dogId,
        date: DateTime(now.year, now.month, 10),
        category: ExpenseCategory.vet,
        amount: 50000,
        memo: '정기검진',
      ),
    ];
  }

  // ---- Dogs ----
  @override
  Stream<List<Dog>> watchDogs() => _dogs.watch(() => List.unmodifiable(_dogs.items));

  @override
  Future<int> addDog(DogsCompanion entry) async {
    final id = _nextDogId++;
    _dogs.items = [
      ..._dogs.items,
      Dog(
        id: id,
        name: entry.name.value,
        breed: entry.breed.present ? entry.breed.value : null,
        birthDate: entry.birthDate.present ? entry.birthDate.value : null,
        photoPath: entry.photoPath.present ? entry.photoPath.value : null,
      ),
    ];
    _dogs.notify();
    return id;
  }

  @override
  Future<void> updateDog(Dog dog) async {
    _dogs.items = [for (final d in _dogs.items) if (d.id == dog.id) dog else d];
    _dogs.notify();
  }

  @override
  Future<void> deleteDog(int id) async {
    _dogs.items = _dogs.items.where((d) => d.id != id).toList();
    _dogs.notify();
    _schedules.items = _schedules.items.where((s) => s.dogId != id).toList();
    _schedules.notify();
    _weights.items = _weights.items.where((w) => w.dogId != id).toList();
    _weights.notify();
    _healthLogs.items = _healthLogs.items.where((h) => h.dogId != id).toList();
    _healthLogs.notify();
    _expenses.items = _expenses.items.where((e) => e.dogId != id).toList();
    _expenses.notify();
  }

  // ---- Schedule ----
  @override
  Stream<List<ScheduleItem>> watchSchedulesForDog(int dogId) => _schedules.watch(() {
        final list = _schedules.items.where((s) => s.dogId == dogId).toList()
          ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
        return list;
      });

  @override
  Stream<List<ScheduleItem>> watchUpcomingSchedules(int dogId, {int days = 14}) =>
      _schedules.watch(() {
        final until = DateTime.now().add(Duration(days: days));
        final list = _schedules.items
            .where((s) => s.dogId == dogId && !s.nextDueDate.isAfter(until))
            .toList()
          ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
        return list;
      });

  @override
  Future<int> addSchedule(ScheduleItemsCompanion entry) async {
    final id = _nextScheduleId++;
    _schedules.items = [
      ..._schedules.items,
      ScheduleItem(
        id: id,
        dogId: entry.dogId.value,
        type: entry.type.value,
        title: entry.title.value,
        intervalDays: entry.intervalDays.present ? entry.intervalDays.value : null,
        lastDoneDate: entry.lastDoneDate.present ? entry.lastDoneDate.value : null,
        nextDueDate: entry.nextDueDate.value,
        memo: entry.memo.present ? entry.memo.value : null,
        notifyEnabled: entry.notifyEnabled.present ? entry.notifyEnabled.value : true,
      ),
    ];
    _schedules.notify();
    return id;
  }

  @override
  Future<void> updateSchedule(ScheduleItem item) async {
    _schedules.items = [for (final s in _schedules.items) if (s.id == item.id) item else s];
    _schedules.notify();
  }

  @override
  Future<void> deleteSchedule(int id) async {
    _schedules.items = _schedules.items.where((s) => s.id != id).toList();
    _schedules.notify();
  }

  @override
  Future<void> completeSchedule(ScheduleItem item) async {
    final now = DateTime.now();
    final next = item.intervalDays != null ? now.add(Duration(days: item.intervalDays!)) : now;
    final updated = item.copyWith(lastDoneDate: Value(now), nextDueDate: next);
    _schedules.items = [
      for (final s in _schedules.items) if (s.id == item.id) updated else s,
    ];
    _schedules.notify();
  }

  // ---- Weight ----
  @override
  Stream<List<WeightRecord>> watchWeightsForDog(int dogId) => _weights.watch(() {
        final list = _weights.items.where((w) => w.dogId == dogId).toList()
          ..sort((a, b) => a.date.compareTo(b.date));
        return list;
      });

  @override
  Future<int> addWeight(WeightRecordsCompanion entry) async {
    final id = _nextWeightId++;
    _weights.items = [
      ..._weights.items,
      WeightRecord(id: id, dogId: entry.dogId.value, date: entry.date.value, weightKg: entry.weightKg.value),
    ];
    _weights.notify();
    return id;
  }

  @override
  Future<bool> updateWeight(WeightRecord entry) async {
    _weights.items = [for (final w in _weights.items) if (w.id == entry.id) entry else w];
    _weights.notify();
    return true;
  }

  @override
  Future<void> deleteWeight(int id) async {
    _weights.items = _weights.items.where((w) => w.id != id).toList();
    _weights.notify();
  }

  // ---- Health logs ----
  @override
  Stream<List<HealthLog>> watchHealthLogsForDog(int dogId) => _healthLogs.watch(() {
        final list = _healthLogs.items.where((h) => h.dogId == dogId).toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        return list;
      });

  @override
  Future<int> addHealthLog(HealthLogsCompanion entry) async {
    final id = _nextHealthLogId++;
    _healthLogs.items = [
      ..._healthLogs.items,
      HealthLog(
        id: id,
        dogId: entry.dogId.value,
        date: entry.date.value,
        type: entry.type.value,
        title: entry.title.value,
        memo: entry.memo.present ? entry.memo.value : null,
      ),
    ];
    _healthLogs.notify();
    return id;
  }

  @override
  Future<bool> updateHealthLog(HealthLog entry) async {
    _healthLogs.items = [for (final h in _healthLogs.items) if (h.id == entry.id) entry else h];
    _healthLogs.notify();
    return true;
  }

  @override
  Future<void> deleteHealthLog(int id) async {
    _healthLogs.items = _healthLogs.items.where((h) => h.id != id).toList();
    _healthLogs.notify();
  }

  // ---- Expenses ----
  @override
  Stream<List<Expense>> watchExpensesForMonth(int dogId, DateTime month) => _expenses.watch(() {
        final start = DateTime(month.year, month.month, 1);
        final end = DateTime(month.year, month.month + 1, 1);
        final list = _expenses.items
            .where((e) =>
                e.dogId == dogId &&
                !e.date.isBefore(start) &&
                e.date.isBefore(end))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        return list;
      });

  @override
  Future<int> addExpense(ExpensesCompanion entry) async {
    final id = _nextExpenseId++;
    _expenses.items = [
      ..._expenses.items,
      Expense(
        id: id,
        dogId: entry.dogId.value,
        date: entry.date.value,
        category: entry.category.value,
        amount: entry.amount.value,
        memo: entry.memo.present ? entry.memo.value : null,
      ),
    ];
    _expenses.notify();
    return id;
  }

  @override
  Future<void> deleteExpense(int id) async {
    _expenses.items = _expenses.items.where((e) => e.id != id).toList();
    _expenses.notify();
  }

  @override
  Future<void> close() async {}
}

/// List<T> 상태 + 변경 브로드캐스트를 묶어 drift의 watch() 스트림처럼 동작하게 하는 헬퍼.
/// 구독 즉시 현재 스냅샷을 한 번 내보내고, 이후 notify() 호출마다 다시 내보낸다.
class _Watchable<T> {
  List<T> items = [];
  final _changes = StreamController<void>.broadcast();

  void notify() => _changes.add(null);

  Stream<List<T>> watch(List<T> Function() snapshot) {
    return Stream.multi((controller) {
      controller.add(snapshot());
      final sub = _changes.stream.listen((_) => controller.add(snapshot()));
      controller.onCancel = sub.cancel;
    });
  }
}
