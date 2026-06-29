import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/empty_placeholder.dart';
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
      appBar: AppBar(title: const Text('菜谱')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: '搜索菜名或描述',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (v) =>
                  ref.read(recipeKeywordProvider.notifier).state = v,
            ),
          ),
          tags.maybeWhen(
            data: (list) => SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final t in list)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(t.name),
                        selected: activeTag == t.id,
                        onSelected: (sel) => ref
                            .read(recipeTagFilterProvider.notifier)
                            .state = sel ? t.id : null,
                      ),
                    ),
                ],
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          Expanded(
            child: recipes.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载失败：$e')),
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyPlaceholder(
                    icon: Icons.menu_book_outlined,
                    title: '没有匹配的菜谱',
                    subtitle: '在「想做」加菜或「记一笔」做菜后会沉淀到这里',
                  );
                }
                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) => _RecipeTile(recipe: list[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipeTile extends StatelessWidget {
  const _RecipeTile({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final status = RecipeStatus.fromValue(recipe.status);
    return ListTile(
      leading: const Icon(Icons.restaurant_menu),
      title: Text(recipe.title),
      subtitle: Text('${status.label} · 做过 ${recipe.cookCount} 次'),
      onTap: () => context.push('/recipe/${recipe.id}'),
    );
  }
}
