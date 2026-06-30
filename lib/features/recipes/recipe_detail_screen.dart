import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/ui_kit.dart';
import '../../data/db/database.dart';
import '../../data/models/enums.dart';
import '../../data/models/formula.dart';
import '../../data/providers.dart';
import '../media/photo_viewer_screen.dart';
import '../cooking_log/cooking_log_form.dart';
import 'recipe_version_form.dart';

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
                    RecipeCoverThumb(
                      recipeId: recipe.id,
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
        _VersionsSection(recipeId: recipe.id),
        const SizedBox(height: 12),
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
          trailing: FilledButton.tonalIcon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CookingLogFormScreen(
                  recipeId: recipe.id,
                  recipeTitle: recipe.title,
                ),
              ),
            ),
            icon: const Icon(Icons.restaurant_rounded, size: 18),
            label: const Text('今天做了'),
          ),
          child: logs.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('加载失败：$e'),
            data: (list) => list.isEmpty
                ? const Text('还没有做菜记录')
                : Column(
                    children:
                        list.map((l) => _logTile(context, l)).toList()),
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

  Widget _logTile(BuildContext context, CookingLog log) {
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
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CookingLogFormScreen(
              recipeId: recipe.id,
              recipeTitle: recipe.title,
              log: log,
            ),
          ),
        ),
      ),
    );
  }
}

/// 配方记录区：最高分配方排第一，可新增 / 修改 / 删除，每次保存留下记录。
class _VersionsSection extends ConsumerWidget {
  const _VersionsSection({required this.recipeId});

  final String recipeId;

  Future<void> _add(BuildContext context, int count) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecipeVersionFormScreen(
          recipeId: recipeId,
          defaultName: '配方 ${count + 1}',
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, RecipeVersion v) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecipeVersionFormScreen(recipeId: recipeId, version: v),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, RecipeVersion v) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除配方'),
        content: Text('确定删除「${v.name}」这条配方记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(recipeRepositoryProvider).deleteVersion(v.id, recipeId);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versions = ref.watch(recipeVersionsProvider(recipeId));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('配方记录',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                versions.maybeWhen(
                  data: (list) => TextButton.icon(
                    onPressed: () => _add(context, list.length),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('新建'),
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            versions.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('加载失败：$e'),
              data: (list) {
                if (list.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('还没有配方记录，点「新建」记录第一版配料用量。'),
                  );
                }
                return Column(
                  children: [
                    for (var i = 0; i < list.length; i++)
                      _versionTile(context, ref, list[i], i == 0),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _versionTile(
      BuildContext context, WidgetRef ref, RecipeVersion v, bool top) {
    final scheme = Theme.of(context).colorScheme;
    final ingredients = decodeIngredients(v.ingredients);
    final date = DateFormat('yyyy-MM-dd HH:mm')
        .format(DateTime.fromMillisecondsSinceEpoch(v.updatedAt));
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: top
            ? scheme.primaryContainer.withValues(alpha: 0.5)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: top
            ? Border.all(color: scheme.primary.withValues(alpha: 0.4))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (top)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(Icons.workspace_premium,
                      size: 18, color: scheme.primary),
                ),
              Expanded(
                child: Text(
                  v.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (v.rating != null) ...[
                RatingStars(v.rating!, size: 14),
                const SizedBox(width: 4),
                Text('${v.rating}'),
              ] else
                Text('未评分',
                    style: Theme.of(context).textTheme.labelSmall),
              PopupMenuButton<String>(
                onSelected: (action) {
                  if (action == 'edit') {
                    _edit(context, v);
                  } else if (action == 'delete') {
                    _delete(context, ref, v);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('修改')),
                  PopupMenuItem(value: 'delete', child: Text('删除')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (ingredients.isEmpty)
            const Text('（无配料）')
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: ingredients
                  .map((ing) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: Row(
                          children: [
                            Expanded(child: Text('• ${ing.name}')),
                            if ((ing.amount ?? '').isNotEmpty)
                              Text(
                                ing.amount!,
                                style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          if ((v.note ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              v.note!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
          const SizedBox(height: 6),
          Text(date, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                ?trailing,
              ],
            ),
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
