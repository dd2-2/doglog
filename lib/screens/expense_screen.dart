import 'package:drift/drift.dart' show Value;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../providers/database_provider.dart';
import '../providers/record_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/soft_card.dart';

const _categoryColors = {
  ExpenseCategory.vet: Color(0xFF141414),
  ExpenseCategory.food: Color(0xFF4D4D4D),
  ExpenseCategory.grooming: Color(0xFF7A7A7A),
  ExpenseCategory.supplies: Color(0xFFA6A6A6),
  ExpenseCategory.other: Color(0xFFD1D1D1),
};

class ExpenseScreen extends ConsumerWidget {
  const ExpenseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dog = ref.watch(selectedDogProvider);
    if (dog == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('지출')),
        body: const EmptyState(icon: Icons.savings, message: '먼저 홈에서 반려동물을 등록해주세요'),
      );
    }

    final month = ref.watch(selectedExpenseMonthProvider);
    final expensesAsync = ref.watch(expensesForMonthProvider(dog.id));

    return Scaffold(
      appBar: AppBar(title: const Text('지출')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => ref.read(selectedExpenseMonthProvider.notifier).state =
                      DateTime(month.year, month.month - 1, 1),
                ),
                Text(
                  DateFormat('yyyy년 M월').format(month),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => ref.read(selectedExpenseMonthProvider.notifier).state =
                      DateTime(month.year, month.month + 1, 1),
                ),
              ],
            ),
          ),
          Expanded(
            child: expensesAsync.when(
              data: (list) => list.isEmpty
                  ? const EmptyState(icon: Icons.savings, message: '이 달 지출 기록이 없어요')
                  : _ExpenseBody(list: list),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExpenseSheet(context, ref, dog.id),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ExpenseBody extends StatelessWidget {
  const _ExpenseBody({required this.list});

  final List<Expense> list;

  @override
  Widget build(BuildContext context) {
    final byCategory = <ExpenseCategory, double>{};
    for (final e in list) {
      byCategory.update(e.category, (v) => v + e.amount, ifAbsent: () => e.amount);
    }
    final total = list.fold<double>(0, (sum, e) => sum + e.amount);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        SoftCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  height: 160,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: [
                        for (final entry in byCategory.entries)
                          PieChartSectionData(
                            value: entry.value,
                            color: _categoryColors[entry.key],
                            title: '',
                            radius: 34,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '총 ${NumberFormat('#,###').format(total)}원',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    for (final entry in byCategory.entries)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _categoryColors[entry.key],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${entry.key.label} ${NumberFormat('#,###').format(entry.value)}원',
                            style: const TextStyle(fontSize: 12, color: AppColors.inkLight),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (final e in list) _ExpenseTile(expense: e),
      ],
    );
  }
}

class _ExpenseTile extends ConsumerWidget {
  const _ExpenseTile({required this.expense});

  final Expense expense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SoftCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (_categoryColors[expense.category] ?? AppColors.inkLight)
              .withValues(alpha: 0.18),
          child: Icon(Icons.receipt_long, size: 18, color: _categoryColors[expense.category]),
        ),
        title: Text('${NumberFormat('#,###').format(expense.amount)}원'),
        subtitle: Text(
          '${expense.category.label} · ${DateFormat('yyyy.MM.dd').format(expense.date)}'
          '${expense.memo != null && expense.memo!.isNotEmpty ? '\n${expense.memo}' : ''}',
        ),
        isThreeLine: expense.memo != null && expense.memo!.isNotEmpty,
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 18, color: AppColors.inkLight),
          onPressed: () => ref.read(databaseProvider).deleteExpense(expense.id),
        ),
      ),
    );
  }
}

Future<void> _showAddExpenseSheet(BuildContext context, WidgetRef ref, int dogId) {
  final amountCtrl = TextEditingController();
  final memoCtrl = TextEditingController();
  ExpenseCategory category = ExpenseCategory.vet;
  DateTime date = DateTime.now();

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('지출 추가', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            DropdownButtonFormField<ExpenseCategory>(
              value: category,
              decoration: const InputDecoration(labelText: '카테고리'),
              items: [
                for (final c in ExpenseCategory.values)
                  DropdownMenuItem(value: c, child: Text(c.label)),
              ],
              onChanged: (v) {
                if (v != null) setSheetState(() => category = v);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '금액 (원)'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: date,
                  firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setSheetState(() => date = picked);
              },
              borderRadius: BorderRadius.circular(14),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: '날짜'),
                child: Text(DateFormat('yyyy.MM.dd').format(date)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: memoCtrl,
              decoration: const InputDecoration(labelText: '메모 (선택)'),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountCtrl.text.trim());
                if (amount == null) return;
                final db = ref.read(databaseProvider);
                await db.addExpense(ExpensesCompanion.insert(
                  dogId: dogId,
                  date: date,
                  category: category,
                  amount: amount,
                  memo: Value(memoCtrl.text.trim().isEmpty ? null : memoCtrl.text.trim()),
                ));
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text('추가', textAlign: TextAlign.center),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
