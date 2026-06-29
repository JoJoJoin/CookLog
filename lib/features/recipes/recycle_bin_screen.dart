import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/providers.dart';

/// 回收站：恢复或永久删除已软删除的菜谱。
class RecycleBinScreen extends ConsumerWidget {
  const RecycleBinScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trashed = ref.watch(trashedRecipesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('回收站')),
      body: trashed.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (list) => list.isEmpty
            ? const Center(child: Text('回收站为空'))
            : ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) => _TrashTile(recipe: list[i]),
              ),
      ),
    );
  }
}

class _TrashTile extends ConsumerWidget {
  const _TrashTile({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(recipeRepositoryProvider);
    return ListTile(
      title: Text(recipe.title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () => repo.restore(recipe.id),
            child: const Text('恢复'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever_outlined),
            tooltip: '永久删除',
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('永久删除'),
                  content: Text('确定要永久删除「${recipe.title}」吗？此操作不可恢复。'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('取消'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('删除'),
                    ),
                  ],
                ),
              );
              if (ok == true) await repo.purge(recipe.id);
            },
          ),
        ],
      ),
    );
  }
}
