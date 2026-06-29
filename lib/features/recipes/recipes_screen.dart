import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/empty_placeholder.dart';
import '../../data/db/database.dart';
import '../../data/models/enums.dart';
import '../../data/providers.dart';

/// 菜谱库（M2 列表，M3 完善详情/搜索）。
class RecipesScreen extends ConsumerWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipes = ref.watch(allRecipesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('菜谱')),
      body: recipes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyPlaceholder(
              icon: Icons.menu_book_outlined,
              title: '菜谱库还是空的',
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
    );
  }
}
