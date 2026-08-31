import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../providers/database_provider.dart';
import '../theme/app_theme.dart';

class DogFormScreen extends ConsumerStatefulWidget {
  const DogFormScreen({super.key, this.existing});

  final Dog? existing;

  @override
  ConsumerState<DogFormScreen> createState() => _DogFormScreenState();
}

class _DogFormScreenState extends ConsumerState<DogFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _breedCtrl;
  DateTime? _birthDate;
  String? _photoPath;

  @override
  void initState() {
    super.initState();
    final dog = widget.existing;
    _nameCtrl = TextEditingController(text: dog?.name ?? '');
    _breedCtrl = TextEditingController(text: dog?.breed ?? '');
    _birthDate = dog?.birthDate;
    _photoPath = dog?.photoPath;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _breedCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (picked != null) setState(() => _photoPath = picked.path);
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? now,
      firstDate: DateTime(now.year - 30),
      lastDate: now,
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final db = ref.read(databaseProvider);
    final name = _nameCtrl.text.trim();
    final breed = _breedCtrl.text.trim();

    if (widget.existing == null) {
      final id = await db.addDog(DogsCompanion.insert(
        name: name,
        breed: Value(breed.isEmpty ? null : breed),
        birthDate: Value(_birthDate),
        photoPath: Value(_photoPath),
      ));
      ref.read(selectedDogIdProvider.notifier).state = id;
    } else {
      await db.updateDog(widget.existing!.copyWith(
        name: name,
        breed: Value(breed.isEmpty ? null : breed),
        birthDate: Value(_birthDate),
        photoPath: Value(_photoPath),
      ));
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('반려견 삭제'),
        content: Text('${widget.existing!.name}의 모든 일정/건강/지출 기록도 함께 삭제됩니다.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('삭제', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;
    final db = ref.read(databaseProvider);
    await db.deleteDog(widget.existing!.id);
    ref.read(selectedDogIdProvider.notifier).state = null;
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? '반려견 정보 수정' : '반려견 등록'),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.coral.withValues(alpha: 0.15),
                  backgroundImage:
                      _photoPath != null ? FileImage(File(_photoPath!)) : null,
                  child: _photoPath == null
                      ? const Icon(Icons.add_a_photo_outlined,
                          size: 28, color: AppColors.coralDark)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: '이름'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '이름을 입력해주세요' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _breedCtrl,
              decoration: const InputDecoration(labelText: '품종 (선택)'),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickBirthDate,
              borderRadius: BorderRadius.circular(14),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: '생일 (선택)'),
                child: Text(
                  _birthDate != null
                      ? DateFormat('yyyy.MM.dd').format(_birthDate!)
                      : '선택 안 함',
                ),
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _save,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(isEdit ? '저장' : '등록', textAlign: TextAlign.center),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
