import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';

/// 记录一次做菜（F-02）。recipeId 非空表示给已有菜谱补记，空则随手记。
class CookingLogFormScreen extends ConsumerStatefulWidget {
  const CookingLogFormScreen({super.key, this.recipeId, this.recipeTitle});

  final String? recipeId;
  final String? recipeTitle;

  @override
  ConsumerState<CookingLogFormScreen> createState() =>
      _CookingLogFormScreenState();
}

class _CookingLogFormScreenState extends ConsumerState<CookingLogFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _notes = TextEditingController();
  final _improvements = TextEditingController();
  int _rating = 0;
  DateTime _cookedAt = DateTime.now();
  bool _saving = false;

  bool get _isQuick => widget.recipeId == null;

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _improvements.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _cookedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _cookedAt = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final repo = ref.read(cookingLogRepositoryProvider);
    final cookedAt = _cookedAt.millisecondsSinceEpoch;
    final notes = _notes.text.trim().isEmpty ? null : _notes.text.trim();
    if (_isQuick) {
      await repo.createQuick(
        title: _title.text.trim(),
        cookedAt: cookedAt,
        notes: notes,
        rating: _rating == 0 ? null : _rating,
      );
    } else {
      await repo.create(
        recipeId: widget.recipeId,
        cookedAt: cookedAt,
        notes: notes,
        improvements: _improvements.text.trim().isEmpty
            ? null
            : _improvements.text.trim(),
        rating: _rating == 0 ? null : _rating,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final dateText =
        '${_cookedAt.year}-${_cookedAt.month.toString().padLeft(2, '0')}-${_cookedAt.day.toString().padLeft(2, '0')}';
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipeTitle == null
            ? '记一笔做菜'
            : '做了 · ${widget.recipeTitle}'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_isQuick)
              TextFormField(
                controller: _title,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: '做了什么菜 *',
                  hintText: '如：番茄炒蛋',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '请输入菜名' : null,
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: const Text('做菜日期'),
              subtitle: Text(dateText),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickDate,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('评分'),
                const SizedBox(width: 12),
                ...List.generate(5, (i) {
                  final n = i + 1;
                  return IconButton(
                    icon: Icon(n <= _rating ? Icons.star : Icons.star_border),
                    onPressed: () => setState(() => _rating = n),
                  );
                }),
              ],
            ),
            TextFormField(
              controller: _notes,
              decoration:
                  const InputDecoration(labelText: '心得（咸淡、火候、用时）'),
              maxLines: 3,
            ),
            if (!_isQuick) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _improvements,
                decoration: const InputDecoration(labelText: '下次改良'),
                maxLines: 2,
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? '保存中…' : '保存记录'),
            ),
          ],
        ),
      ),
    );
  }
}
