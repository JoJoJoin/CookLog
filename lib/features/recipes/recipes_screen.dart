import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/brand_fx.dart';
import '../../core/widgets/emoji_empty_state.dart';
import '../../core/widgets/ui_kit.dart';
import '../../data/db/database.dart';
import '../../data/models/enums.dart';
import '../../data/providers.dart';

/// 菜谱库：搜索 + 标签筛选 + 列表，点进详情。
class RecipesScreen extends ConsumerWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipes = ref.watch(filteredRecipesProvider);
    final tags = ref.watch(allTagsProvider);
    final activeTag = ref.watch(recipeTagFilterProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('菜谱库')),
      body: BrandBackdrop(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: '搜索菜名或描述',
                  isDense: true,
                ),
                onChanged: (v) =>
                    ref.read(recipeKeywordProvider.notifier).state = v,
              ),
            ),
            tags.maybeWhen(
              data: (list) => _TagFilters(list: list, activeTag: activeTag),
              orElse: () => const SizedBox.shrink(),
            ),
            Expanded(
              child: recipes.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('加载失败：$e')),
                data: (list) {
                  if (list.isEmpty) {
                    return EmojiEmptyState(
                      emoji: '📚',
                      title: '还没有沉淀下来的菜谱',
                      subtitle: '在「想做」加菜，或记录一次做菜后，\n就会自动出现在这里。',
                      tone: Theme.of(context).colorScheme.secondaryContainer,
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 90),
                    itemCount: list.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child:
                          StaggerItem(index: i, child: _RecipeCard(recipe: list[i])),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagFilters extends ConsumerWidget {
  const _TagFilters({required this.list, required this.activeTag});

  final List<Tag> list;
  final String? activeTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('全部'),
              selected: activeTag == null,
              onSelected: (_) =>
                  ref.read(recipeTagFilterProvider.notifier).state = null,
            ),
          ),
          for (final t in list)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(t.name),
                selected: activeTag == t.id,
                onSelected: (sel) => ref.read(recipeTagFilterProvider.notifier).state =
                    sel ? t.id : null,
              ),
            ),
        ],
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final status = RecipeStatus.fromValue(recipe.status);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => context.push('/recipe/${recipe.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RecipeCoverThumb(
                recipeId: recipe.id,
                size: 82,
                radius: 18,
                emoji: '🍲',
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StatusPill(status),
                        const Spacer(),
                        if (recipe.rating != null)
                          RatingStars(recipe.rating!, size: 14),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      recipe.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '做过 ${recipe.cookCount} 次',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    if (recipe.description != null &&
                        recipe.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        recipe.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color:
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
