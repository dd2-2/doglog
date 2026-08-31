import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final dogsStreamProvider = StreamProvider<List<Dog>>((ref) {
  return ref.watch(databaseProvider).watchDogs();
});

/// 사용자가 명시적으로 선택한 반려견 id. null이면 목록의 첫 번째 견을 기본 선택.
final selectedDogIdProvider = StateProvider<int?>((ref) => null);

final selectedDogProvider = Provider<Dog?>((ref) {
  final dogsAsync = ref.watch(dogsStreamProvider);
  final selectedId = ref.watch(selectedDogIdProvider);
  return dogsAsync.maybeWhen(
    data: (dogs) {
      if (dogs.isEmpty) return null;
      if (selectedId == null) return dogs.first;
      for (final dog in dogs) {
        if (dog.id == selectedId) return dog;
      }
      return dogs.first;
    },
    orElse: () => null,
  );
});
