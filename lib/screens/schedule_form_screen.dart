import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../providers/database_provider.dart';
import '../services/notification_service.dart';

enum _RepeatOption { none, weekly, monthly }

extension on _RepeatOption {
  String get label => switch (this) {
        _RepeatOption.none => '없음 (한 번만)',
        _RepeatOption.weekly => '1주일마다',
        _RepeatOption.monthly => '1개월마다',
      };

  int? get days => switch (this) {
        _RepeatOption.none => null,
        _RepeatOption.weekly => 7,
        _RepeatOption.monthly => 30,
      };
}

_RepeatOption _repeatOptionFromDays(int? days) => switch (days) {
      7 => _RepeatOption.weekly,
      30 => _RepeatOption.monthly,
      _ => _RepeatOption.none,
    };

class ScheduleFormScreen extends ConsumerStatefulWidget {
  const ScheduleFormScreen({super.key, required this.dog, this.existing, this.initialDate});

  final Dog dog;
  final ScheduleItem? existing;

  /// 새 일정 추가 시 캘린더에서 선택된 날짜로 미리 채워둘 기본 날짜.
  final DateTime? initialDate;

  @override
  ConsumerState<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends ConsumerState<ScheduleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _memoCtrl;
  late DateTime _dueDate;
  late _RepeatOption _repeat;

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    _titleCtrl = TextEditingController(text: item?.title ?? '');
    _memoCtrl = TextEditingController(text: item?.memo ?? '');
    _dueDate = item?.nextDueDate ?? widget.initialDate ?? DateTime.now();
    _repeat = _repeatOptionFromDays(item?.intervalDays);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final db = ref.read(databaseProvider);
    final title = _titleCtrl.text.trim();
    final memo = _memoCtrl.text.trim();
    final interval = _repeat.days;

    int scheduleId;
    try {
      if (widget.existing == null) {
        scheduleId = await db.addSchedule(ScheduleItemsCompanion.insert(
          dogId: widget.dog.id,
          type: ScheduleType.other,
          title: title,
          nextDueDate: _dueDate,
          intervalDays: Value(interval),
          memo: Value(memo.isEmpty ? null : memo),
        ));
      } else {
        scheduleId = widget.existing!.id;
        await db.updateSchedule(widget.existing!.copyWith(
          title: title,
          nextDueDate: _dueDate,
          intervalDays: Value(interval),
          memo: Value(memo.isEmpty ? null : memo),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장에 실패했습니다. 다시 시도해주세요.')),
        );
      }
      return;
    }

    try {
      await NotificationService.instance.scheduleForItem(
        scheduleId: scheduleId,
        dogName: widget.dog.name,
        title: title,
        dueDate: _dueDate,
      );
    } catch (_) {
      // 알림 예약 실패는 일정 저장 자체를 막지 않음
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final db = ref.read(databaseProvider);
    await NotificationService.instance.cancel(widget.existing!.id);
    await db.deleteSchedule(widget.existing!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? '일정 수정' : '일정 추가'),
        actions: [
          if (isEdit)
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: '제목'),
              validator: (v) => (v == null || v.trim().isEmpty) ? '제목을 입력해주세요' : null,
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(14),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: '날짜'),
                child: Text(DateFormat('yyyy.MM.dd').format(_dueDate)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _memoCtrl,
              decoration: const InputDecoration(labelText: '메모 (선택)'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<_RepeatOption>(
              value: _repeat,
              decoration: const InputDecoration(labelText: '반복 주기'),
              items: [
                for (final r in _RepeatOption.values)
                  DropdownMenuItem(value: r, child: Text(r.label)),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _repeat = v);
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _save,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(isEdit ? '저장' : '추가', textAlign: TextAlign.center),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
