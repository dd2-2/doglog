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

class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dog = ref.watch(selectedDogProvider);
    if (dog == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('건강')),
        body: const EmptyState(icon: Icons.favorite, message: '먼저 홈에서 반려동물을 등록해주세요'),
      );
    }

    final weights = ref.watch(weightsForDogProvider(dog.id));
    final logs = ref.watch(healthLogsForDogProvider(dog.id));

    return Scaffold(
      appBar: AppBar(title: const Text('건강')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('체중 변화', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              TextButton.icon(
                onPressed: () => _showWeightSheet(context, ref, dog.id),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('기록'),
              ),
            ],
          ),
          weights.when(
            data: (list) {
              if (list.isEmpty) return const _MiniEmpty(text: '체중 기록이 없어요');
              if (list.length == 1) {
                return _SingleWeight(
                  record: list.first,
                  onEdit: () => _showWeightSheet(context, ref, dog.id, existing: list.first),
                );
              }
              return Column(
                children: [
                  _WeightChart(records: list),
                  const SizedBox(height: 8),
                  for (final w in list.reversed)
                    _WeightTile(
                      record: w,
                      onEdit: () => _showWeightSheet(context, ref, dog.id, existing: w),
                    ),
                ],
              );
            },
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('건강 기록', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              TextButton.icon(
                onPressed: () => _showLogSheet(context, ref, dog.id),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('기록'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          logs.when(
            data: (list) => list.isEmpty
                ? const _MiniEmpty(text: '병원 방문/투약 기록이 없어요')
                : Column(children: [
                    for (final l in list)
                      _HealthLogTile(
                        log: l,
                        onEdit: () => _showLogSheet(context, ref, dog.id, existing: l),
                      ),
                  ]),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
    );
  }
}

class _SingleWeight extends StatelessWidget {
  const _SingleWeight({required this.record, required this.onEdit});

  final WeightRecord record;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: onEdit,
      child: SoftCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${record.weightKg} kg',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              Text(
                DateFormat('yyyy.MM.dd').format(record.date),
                style: const TextStyle(color: AppColors.inkLight),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeightTile extends StatelessWidget {
  const _WeightTile({required this.record, required this.onEdit});

  final WeightRecord record;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: onEdit,
      child: SoftCard(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          title: Text('${record.weightKg} kg'),
          subtitle: Text(DateFormat('yyyy.MM.dd').format(record.date)),
        ),
      ),
    );
  }
}

class _WeightChart extends StatelessWidget {
  const _WeightChart({required this.records});

  final List<WeightRecord> records;

  @override
  Widget build(BuildContext context) {
    final recent = records.length > 20 ? records.sublist(records.length - 20) : records;
    final spots = [
      for (var i = 0; i < recent.length; i++) FlSpot(i.toDouble(), recent[i].weightKg),
    ];
    final minY = recent.map((e) => e.weightKg).reduce((a, b) => a < b ? a : b);
    final maxY = recent.map((e) => e.weightKg).reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY).abs() < 1 ? 1.0 : (maxY - minY) * 0.2;

    return SoftCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
        child: SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              minX: -0.3,
              maxX: (recent.length - 1) + 0.3,
              minY: (minY - pad).clamp(0, double.infinity),
              maxY: maxY + pad,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: const FlTitlesData(
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 34),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: AppColors.coral,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.coral.withValues(alpha: 0.12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HealthLogTile extends StatelessWidget {
  const _HealthLogTile({required this.log, required this.onEdit});

  final HealthLog log;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: onEdit,
      child: SoftCard(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.mint.withValues(alpha: 0.18),
            child: const Icon(Icons.medical_services_outlined, color: AppColors.ink, size: 18),
          ),
          title: Text(log.title),
          subtitle: Text('${log.type.label} · ${DateFormat('yyyy.MM.dd').format(log.date)}'
              '${log.memo != null && log.memo!.isNotEmpty ? '\n${log.memo}' : ''}'),
          isThreeLine: log.memo != null && log.memo!.isNotEmpty,
        ),
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

Future<void> _showWeightSheet(
  BuildContext context,
  WidgetRef ref,
  int dogId, {
  WeightRecord? existing,
}) {
  final weightCtrl = TextEditingController(
    text: existing != null ? existing.weightKg.toString() : '',
  );
  DateTime date = existing?.date ?? DateTime.now();

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(existing == null ? '체중 기록 추가' : '체중 기록 수정',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                if (existing != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final db = ref.read(databaseProvider);
                      await db.deleteWeight(existing.id);
                      if (ctx.mounted) Navigator.of(ctx).pop();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: '체중 (kg)'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: date,
                  firstDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
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
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final w = double.tryParse(weightCtrl.text.trim());
                if (w == null) return;
                final db = ref.read(databaseProvider);
                if (existing == null) {
                  await db.addWeight(WeightRecordsCompanion.insert(
                    dogId: dogId,
                    date: date,
                    weightKg: w,
                  ));
                } else {
                  await db.updateWeight(existing.copyWith(date: date, weightKg: w));
                }
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(existing == null ? '추가' : '저장', textAlign: TextAlign.center),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _showLogSheet(
  BuildContext context,
  WidgetRef ref,
  int dogId, {
  HealthLog? existing,
}) {
  final titleCtrl = TextEditingController(text: existing?.title ?? '');
  final memoCtrl = TextEditingController(text: existing?.memo ?? '');
  HealthLogType type = existing?.type ?? HealthLogType.vetVisit;
  DateTime date = existing?.date ?? DateTime.now();

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(existing == null ? '건강 기록 추가' : '건강 기록 수정',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                if (existing != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final db = ref.read(databaseProvider);
                      await db.deleteHealthLog(existing.id);
                      if (ctx.mounted) Navigator.of(ctx).pop();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<HealthLogType>(
              value: type,
              decoration: const InputDecoration(labelText: '종류'),
              items: [
                for (final t in HealthLogType.values)
                  DropdownMenuItem(value: t, child: Text(t.label)),
              ],
              onChanged: (v) {
                if (v != null) setSheetState(() => type = v);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: '제목'),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: date,
                  firstDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
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
                final title = titleCtrl.text.trim();
                if (title.isEmpty) return;
                final db = ref.read(databaseProvider);
                final memo = memoCtrl.text.trim();
                if (existing == null) {
                  await db.addHealthLog(HealthLogsCompanion.insert(
                    dogId: dogId,
                    date: date,
                    type: type,
                    title: title,
                    memo: Value(memo.isEmpty ? null : memo),
                  ));
                } else {
                  await db.updateHealthLog(existing.copyWith(
                    date: date,
                    type: type,
                    title: title,
                    memo: Value(memo.isEmpty ? null : memo),
                  ));
                }
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(existing == null ? '추가' : '저장', textAlign: TextAlign.center),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
