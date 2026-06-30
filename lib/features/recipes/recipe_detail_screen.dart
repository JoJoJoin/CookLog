import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/ui_kit.dart';
import '../../data/db/database.dart';
import '../../data/models/enums.dart';
import '../../data/providers.dart';
import '../media/photo_viewer_screen.dart';

/// 菜谱详情：基础信息 + 改良汇总 + 做菜时间线，并支持流转/标签/删除。
class RecipeDetailScreen extends ConsumerWidget {
  const RecipeDetailScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipeAsync = ref.watch(recipeDetailProvider(recipeId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('菜谱详情'),
        actions: [
          recipeAsync.maybeWhen(
            data: (r) => r == null
                ? const SizedBox.shrink()
                : PopupMenuButton<String>(
                    onSelected: (v) => _onAction(context, ref, r, v),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'want',
                        child: Text(r.wantToCook ? '移出想做' : '加入想做'),
                      ),
                      PopupMenuItem(
                        value: 'shelve',
                        child: Text(
                          r.status == RecipeStatus.shelved.value ? '取消搁置' : '搁置',
                        ),
                      ),
                      const PopupMenuItem(value: 'delete', child: Text('删除')),
                    ],
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: recipeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (recipe) {
          if (recipe == null) {
            return const Center(child: Text('菜谱不存在或已删除'));
          }
          return _DetailBody(recipe: recipe);
        },
      ),
    );
  }

  Future<void> _onAction(
      BuildContext context, WidgetRef ref, Recipe r, String action) async {
    final repo = ref.read(recipeRepositoryProvider);
    switch (action) {
      case 'want':
        await repo.setWantToCook(r.id, !r.wantToCook);
      case 'shelve':
        await repo.setShelved(r.id, r.status != RecipeStatus.shelved.value);
      case 'delete':
        await repo.softDelete(r.id);
        if (context.mounted) context.pop();
    }
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = RecipeStatus.fromValue(recipe.status);
    final tags = ref.watch(recipeTagsProvider(recipe.id));
    final logs = ref.watch(recipeLogsProvider(recipe.id));
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CoverThumb(
                      ownerType: 'recipe',
                      ownerId: recipe.id,
                      size: 92,
                      radius: 20,
                      emoji: '🍲',
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(recipe.title,
                              style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              StatusPill(status),
                              Chip(label: Text('做过 ${recipe.cookCount} 次')),
                              if (recipe.rating != null)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    RatingStars(recipe.rating!, size: 14),
                                    const SizedBox(width: 4),
                                    Text('${recipe.rating}'),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (recipe.description != null && recipe.description!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    recipe.description!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                  ),
                ],
                const SizedBox(height: 12),
                _Gallery(ownerType: 'recipe', ownerId: recipe.id),
              ],
            ),
          ),
        ),
        tags.maybeWhen(
          data: (list) => list.isEmpty
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Wrap(
                    spacing: 8,
                    children: list
                        .map((t) => Chip(label: Text('#${t.name}')))
                        .toList(),
                  ),
                ),
          orElse: () => const SizedBox.shrink(),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: '改良汇总',
          child: logs.maybeWhen(
            data: _buildImprovements,
            orElse: () => const SizedBox.shrink(),
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: '做菜时间线',
          child: logs.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('加载失败：$e'),
            data: (list) => list.isEmpty
                ? const Text('还没有做菜记录')
                : Column(children: list.map(_logTile).toList()),
          ),
        ),
      ],
    );
  }

  Widget _buildImprovements(List<CookingLog> logs) {
    final items = logs
        .where((l) => (l.improvements ?? '').trim().isNotEmpty)
        .toList();
    if (items.isEmpty) return const Text('暂无改良记录');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map((l) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('• ${l.improvements}',
                    style: const TextStyle(height: 1.35)),
              ))
          .toList(),
    );
  }

  Widget _logTile(CookingLog log) {
    final date = DateFormat('yyyy-MM-dd')
        .format(DateTime.fromMillisecondsSinceEpoch(log.cookedAt));
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CoverThumb(
          ownerType: 'cooking_log',
          ownerId: log.id,
          size: 42,
          radius: 10,
          emoji: '🍳',
        ),
        title: Text(date),
        subtitle: Text(log.notes?.isNotEmpty == true ? log.notes! : '无备注'),
        trailing: log.rating != null ? RatingStars(log.rating!) : null,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _Gallery extends ConsumerWidget {
  const _Gallery({required this.ownerType, required this.ownerId});

  final String ownerType;
  final String ownerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = ref.watch(
        mediaForOwnerProvider((type: ownerType, id: ownerId)));
    return media.maybeWhen(
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        final paths = list.map((m) => m.filePath).toList();
        return SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PhotoViewerScreen(paths: paths, initial: i),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  File(list[i].thumbPath ?? list[i].filePath),
                  width: 88,
                  height: 88,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
