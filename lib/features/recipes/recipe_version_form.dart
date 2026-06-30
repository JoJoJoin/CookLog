import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/models/formula.dart';
import '../../data/providers.dart';

/// 配方记录编辑表单：新增或修改一条配方（原材料 / 调味料 + 用量），
/// 可填写备注与自评打分。每次保存都会留下一条独立记录。
class RecipeVersionFormScreen extends ConsumerStatefulWidget {
  const RecipeVersionFormScreen({
    super.key,
    required this.recipeId,
    this.version,
    this.defaultName,
  });

  final String recipeId;

  /// 不为空表示编辑现有记录；为空表示新增。
  final RecipeVersion? version;

  /// 新增时的默认名称（如「配方 1」）。
  final String? defaultName;

  @override
  ConsumerState<RecipeVersionFormScreen> createState() =>
      _RecipeVersionFormScreenState();
}

class _IngredientRow {
  _IngredientRow({String name = '', String amount = ''})
      : name = TextEditingController(text: name),
        amount = TextEditingController(text: amount);

  final TextEditingController name;
  final TextEditingController amount;

  void dispose() {
    name.dispose();
    amount.dispose();
  }
}

class _RecipeVersionFormScreenState
    extends ConsumerState<RecipeVersionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _note;
  final List<_IngredientRow> _rows = [];
  int _rating = 0;
  bool _saving = false;

  bool get _isEdit => widget.version != null;

  @override
  void initState() {
    super.initState();
    final v = widget.version;
    _name = TextEditingController(text: v?.name ?? widget.defaultName ?? '配方');
    _note = TextEditingController(text: v?.note ?? '');
    _rating = v?.rating ?? 0;
    final existing = decodeIngredients(v?.ingredients);
    if (existing.isEmpty) {
      _rows.add(_IngredientRow());
      _rows.add(_IngredientRow());
    } else {
      for (final ing in existing) {
        _rows.add(_IngredientRow(name: ing.name, amount: ing.amount ?? ''));
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  List<FormulaIngredient> _collectIngredients() {
    final out = <FormulaIngredient>[];
    for (final r in _rows) {
      final name = r.name.text.trim();
      if (name.isEmpty) continue;
      final amount = r.amount.text.trim();
      out.add(FormulaIngredient(
        name: name,
        amount: amount.isEmpty ? null : amount,
      ));
    }
    return out;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final ingredients = _collectIngredients();
    if (ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少填写一项配料')),
      );
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(recipeRepositoryProvider);
    final name = _name.text.trim().isEmpty ? '配方' : _name.text.trim();
    final note = _note.text.trim().isEmpty ? null : _note.text.trim();
    final rating = _rating == 0 ? null : _rating;
    if (_isEdit) {
      await repo.updateVersion(
        widget.version!.id,
        recipeId: widget.recipeId,
        name: name,
        ingredients: ingredients,
        note: note,
        rating: rating,
      );
    } else {
      await repo.addVersion(
        widget.recipeId,
        name: name,
        ingredients: ingredients,
        note: note,
        rating: rating,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? '修改配方' : '新建配方')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: '配方名称',
                    hintText: '如：少油版、加辣版',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('配料与用量',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    ..._rows.asMap().entries.map((e) => _ingredientRow(e.key)),
                    const SizedBox(height: 4),
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _rows.add(_IngredientRow())),
                      icon: const Icon(Icons.add),
                      label: const Text('添加一项'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('自评打分',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      children: List.generate(5, (i) {
                        final n = i + 1;
                        return IconButton(
                          iconSize: 28,
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            n <= _rating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                          ),
                          color: const Color(0xFFFFB300),
                          onPressed: () => setState(
                              () => _rating = _rating == n ? 0 : n),
                        );
                      }),
                    ),
                    TextFormField(
                      controller: _note,
                      decoration: const InputDecoration(
                        labelText: '改良备注（口味、火候等）',
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? '保存中…' : '保存配方'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ingredientRow(int index) {
    final row = _rows[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 5,
            child: TextFormField(
              controller: row.name,
              decoration: const InputDecoration(
                labelText: '配料',
                hintText: '如：五花肉',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: TextFormField(
              controller: row.amount,
              decoration: const InputDecoration(
                labelText: '用量',
                hintText: '如：300 克',
                isDense: true,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            tooltip: '删除该项',
            onPressed: _rows.length <= 1
                ? null
                : () => setState(() {
                      _rows.removeAt(index).dispose();
                    }),
          ),
        ],
      ),
    );
  }
}
