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
                onPressed: () => _showAddWeightSheet(context, ref, dog.id),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('기록'),
              ),
            ],
          ),
          weights.when(
            data: (list) => list.isEmpty
                ? const _MiniEmpty(text: '체중 기록이 없어요')
                : _WeightChart(records: list),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('건강 기록', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              TextButton.icon(
                onPressed: () => _showAddLogSheet(context, ref, dog.id),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('기록'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          logs.when(
            data: (list) => list.isEmpty
                ? const _MiniEmpty(text: '병원 방문/투약 기록이 없어요')
                : Column(children: [for (final l in list) _HealthLogTile(log: l)]),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
        child: SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
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
  const _HealthLogTile({required this.log});

  final HealthLog log;

  @override
  Widget build(BuildContext context) {
    return Card(
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

Future<void> _showAddWeightSheet(BuildContext context, WidgetRef ref, int dogId) {
  final weightCtrl = TextEditingController();
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
            const Text('체중 기록 추가', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
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
                await db.addWeight(WeightRecordsCompanion.insert(
                  dogId: dogId,
                  date: date,
                  weightKg: w,
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

Future<void> _showAddLogSheet(BuildContext context, WidgetRef ref, int dogId) {
  final titleCtrl = TextEditingController();
  final memoCtrl = TextEditingController();
  HealthLogType type = HealthLogType.vetVisit;
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
            const Text('건강 기록 추가', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
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
                await db.addHealthLog(HealthLogsCompanion.insert(
                  dogId: dogId,
                  date: date,
                  type: type,
                  title: title,
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
