import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../data/db/database.dart';
import '../../data/providers.dart';
import '../media/photo_viewer_screen.dart';

/// 记录一次做菜（F-02）。recipeId 非空表示给已有菜谱补记，空则随手记。
///
/// 传入 [log] 时进入编辑模式：可改日期/评分/心得/改良，并增删照片。
class CookingLogFormScreen extends ConsumerStatefulWidget {
  const CookingLogFormScreen({
    super.key,
    this.recipeId,
    this.recipeTitle,
    this.log,
  });

  final String? recipeId;
  final String? recipeTitle;
  final CookingLog? log;

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
  final List<XFile> _photos = [];
  List<MediaItem> _existing = [];
  final List<MediaItem> _removed = [];

  bool get _isQuick => widget.recipeId == null && widget.log == null;
  bool get _isEdit => widget.log != null;

  @override
  void initState() {
    super.initState();
    final log = widget.log;
    if (log != null) {
      _cookedAt = DateTime.fromMillisecondsSinceEpoch(log.cookedAt);
      _rating = log.rating ?? 0;
      _notes.text = log.notes ?? '';
      _improvements.text = log.improvements ?? '';
      _loadExistingPhotos(log.id);
    }
  }

  Future<void> _loadExistingPhotos(String logId) async {
    final list = await ref
        .read(mediaRepositoryProvider)
        .watchForOwner('cooking_log', logId)
        .first;
    if (mounted) setState(() => _existing = list);
  }

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

  Future<void> _addPhotos() async {
    final storage = ref.read(mediaStorageServiceProvider);
    final picked = await storage.pickFromGallery();
    if (picked.isNotEmpty) setState(() => _photos.addAll(picked));
  }

  void _viewExisting(int index) {
    final paths = _existing.map((m) => m.filePath).toList();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhotoViewerScreen(paths: paths, initial: index),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final repo = ref.read(cookingLogRepositoryProvider);
    final media = ref.read(mediaRepositoryProvider);
    final cookedAt = _cookedAt.millisecondsSinceEpoch;
    final notes = _notes.text.trim().isEmpty ? null : _notes.text.trim();
    final improvements =
        _improvements.text.trim().isEmpty ? null : _improvements.text.trim();
    if (_isEdit) {
      final logId = widget.log!.id;
      await repo.update(
        id: logId,
        cookedAt: cookedAt,
        notes: notes,
        improvements: improvements,
        rating: _rating == 0 ? null : _rating,
      );
      for (final m in _removed) {
        await media.delete(m);
      }
      if (_photos.isNotEmpty) {
        await media.addImages('cooking_log', logId, _photos);
      }
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final String logId;
    if (_isQuick) {
      logId = await repo.createQuick(
        title: _title.text.trim(),
        cookedAt: cookedAt,
        notes: notes,
        rating: _rating == 0 ? null : _rating,
      );
    } else {
      logId = await repo.create(
        recipeId: widget.recipeId,
        cookedAt: cookedAt,
        notes: notes,
        improvements: improvements,
        rating: _rating == 0 ? null : _rating,
      );
    }
    if (_photos.isNotEmpty) {
      await media.addImages('cooking_log', logId, _photos);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dateText = DateFormat('yyyy-MM-dd').format(_cookedAt);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit
            ? '编辑做菜记录'
            : widget.recipeTitle == null
                ? '记一笔做菜'
                : '做了 · ${widget.recipeTitle}'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: scheme.onSecondaryContainer.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: const Text('🍳', style: TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '记录这次做菜',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: 4),
                        Text('你的心得会变成下次更稳的经验。'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
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
                    if (_isQuick) const SizedBox(height: 12),
                    Material(
                      color: scheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        leading: const Icon(Icons.event_rounded),
                        title: const Text('做菜日期'),
                        subtitle: Text(dateText),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _pickDate,
                      ),
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
                    Text('评分', style: Theme.of(context).textTheme.titleSmall),
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
                          onPressed: () => setState(() => _rating = n),
                        );
                      }),
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
                    Text('照片', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 10),
                    _EditablePhotoRow(
                      existing: _existing,
                      newPhotos: _photos,
                      onAdd: _addPhotos,
                      onView: _viewExisting,
                      onRemoveNew: (i) =>
                          setState(() => _photos.removeAt(i)),
                      onRemoveExisting: (i) => setState(() {
                        _removed.add(_existing[i]);
                        _existing = List.of(_existing)..removeAt(i);
                      }),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving
                  ? '保存中…'
                  : _isEdit
                      ? '保存修改'
                      : '保存记录'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditablePhotoRow extends StatelessWidget {
  const _EditablePhotoRow({
    required this.existing,
    required this.newPhotos,
    required this.onAdd,
    required this.onView,
    required this.onRemoveExisting,
    required this.onRemoveNew,
  });

  final List<MediaItem> existing;
  final List<XFile> newPhotos;
  final VoidCallback onAdd;
  final void Function(int) onView;
  final void Function(int) onRemoveExisting;
  final void Function(int) onRemoveNew;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 94,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (var i = 0; i < existing.length; i++)
            _Thumb(
              image: Image.file(
                File(existing[i].thumbPath ?? existing[i].filePath),
                width: 88,
                height: 88,
                fit: BoxFit.cover,
              ),
              onTap: () => onView(i),
              onRemove: () => onRemoveExisting(i),
            ),
          for (var i = 0; i < newPhotos.length; i++)
            _Thumb(
              image: Image.file(File(newPhotos[i].path),
                  width: 88, height: 88, fit: BoxFit.cover),
              onRemove: () => onRemoveNew(i),
            ),
          InkWell(
            onTap: onAdd,
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                border: Border.all(color: scheme.outlineVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add_a_photo_outlined),
            ),
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.image, required this.onRemove, this.onTap});

  final Widget image;
  final VoidCallback onRemove;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          GestureDetector(
            onTap: onTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: image,
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: GestureDetector(
              onTap: onRemove,
              child: const CircleAvatar(
                radius: 11,
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
