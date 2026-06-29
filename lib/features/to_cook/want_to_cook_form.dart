import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/enums.dart';
import '../../data/providers.dart';

/// 新增「想做」菜谱表单（F-01）。
class WantToCookFormScreen extends ConsumerStatefulWidget {
  const WantToCookFormScreen({super.key});

  @override
  ConsumerState<WantToCookFormScreen> createState() =>
      _WantToCookFormScreenState();
}

class _WantToCookFormScreenState extends ConsumerState<WantToCookFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _sourceUrl = TextEditingController();
  final _sourceAuthor = TextEditingController();
  SourceType _sourceType = SourceType.none;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _sourceUrl.dispose();
    _sourceAuthor.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await ref.read(recipeRepositoryProvider).createWantToCook(
          title: _title.text.trim(),
          description: _description.text.trim().isEmpty
              ? null
              : _description.text.trim(),
          sourceType: _sourceType,
          sourceUrl:
              _sourceUrl.text.trim().isEmpty ? null : _sourceUrl.text.trim(),
          sourceAuthor: _sourceAuthor.text.trim().isEmpty
              ? null
              : _sourceAuthor.text.trim(),
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('想做一道菜')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '菜名 *',
                hintText: '如：番茄炒蛋',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '请输入菜名' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(labelText: '简介'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<SourceType>(
              initialValue: _sourceType,
              decoration: const InputDecoration(labelText: '来源'),
              items: SourceType.values
                  .map((s) =>
                      DropdownMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _sourceType = v ?? SourceType.none),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sourceUrl,
              decoration: const InputDecoration(labelText: '来源链接'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sourceAuthor,
              decoration: const InputDecoration(labelText: '来源作者/博主'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? '保存中…' : '加入想做清单'),
            ),
          ],
        ),
      ),
    );
  }
}
