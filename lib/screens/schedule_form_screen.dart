import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../providers/database_provider.dart';
import '../services/notification_service.dart';

class ScheduleFormScreen extends ConsumerStatefulWidget {
  const ScheduleFormScreen({super.key, required this.dog, this.existing});

  final Dog dog;
  final ScheduleItem? existing;

  @override
  ConsumerState<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends ConsumerState<ScheduleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late ScheduleType _type;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _memoCtrl;
  late final TextEditingController _intervalCtrl;
  late DateTime _dueDate;
  late bool _notifyEnabled;

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    _type = item?.type ?? ScheduleType.vaccination;
    _titleCtrl = TextEditingController(text: item?.title ?? _type.label);
    _memoCtrl = TextEditingController(text: item?.memo ?? '');
    _intervalCtrl = TextEditingController(text: item?.intervalDays?.toString() ?? '');
    _dueDate = item?.nextDueDate ?? DateTime.now();
    _notifyEnabled = item?.notifyEnabled ?? true;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _memoCtrl.dispose();
    _intervalCtrl.dispose();
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
    final interval = int.tryParse(_intervalCtrl.text.trim());
    final title = _titleCtrl.text.trim();

    int scheduleId;
    if (widget.existing == null) {
      scheduleId = await db.addSchedule(ScheduleItemsCompanion.insert(
        dogId: widget.dog.id,
        type: _type,
        title: title,
        nextDueDate: _dueDate,
        intervalDays: Value(interval),
        memo: Value(_memoCtrl.text.trim().isEmpty ? null : _memoCtrl.text.trim()),
        notifyEnabled: Value(_notifyEnabled),
      ));
    } else {
      scheduleId = widget.existing!.id;
      await db.updateSchedule(widget.existing!.copyWith(
        type: _type,
        title: title,
        nextDueDate: _dueDate,
        intervalDays: Value(interval),
        memo: Value(_memoCtrl.text.trim().isEmpty ? null : _memoCtrl.text.trim()),
        notifyEnabled: _notifyEnabled,
      ));
    }

    try {
      if (_notifyEnabled) {
        await NotificationService.instance.scheduleForItem(
          scheduleId: scheduleId,
          dogName: widget.dog.name,
          title: title,
          dueDate: _dueDate,
        );
      } else {
        await NotificationService.instance.cancel(scheduleId);
      }
    } catch (_) {
      // 알림 예약 실패는 저장 자체를 막지 않음
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
            DropdownButtonFormField<ScheduleType>(
              value: _type,
              decoration: const InputDecoration(labelText: '종류'),
              items: [
                for (final t in ScheduleType.values)
                  DropdownMenuItem(value: t, child: Text(t.label)),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  if (_titleCtrl.text.trim().isEmpty ||
                      _titleCtrl.text.trim() == _type.label) {
                    _titleCtrl.text = v.label;
                  }
                  _type = v;
                });
              },
            ),
            const SizedBox(height: 12),
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
                decoration: const InputDecoration(labelText: '다음 예정일'),
                child: Text(DateFormat('yyyy.MM.dd').format(_dueDate)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _intervalCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '반복 주기 (일 단위, 선택)',
                hintText: '예: 30 (한 번만이면 비워두세요)',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _memoCtrl,
              decoration: const InputDecoration(labelText: '메모 (선택)'),
              maxLines: 2,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('알림 받기'),
              value: _notifyEnabled,
              onChanged: (v) => setState(() => _notifyEnabled = v),
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
