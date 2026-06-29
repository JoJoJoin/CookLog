import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/empty_placeholder.dart';
import '../../data/db/database.dart';
import '../../data/providers.dart';
import '../cooking_log/cooking_log_form.dart';
import 'want_to_cook_form.dart';

/// 想做清单（F-01）：想做的菜列表，做过后自动流转为「已做」。
class ToCookScreen extends ConsumerWidget {
  const ToCookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipes = ref.watch(wantToCookProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('想做')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const WantToCookFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('想做'),
      ),
      body: recipes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyPlaceholder(
              icon: Icons.favorite_border,
              title: '想做清单是空的',
              subtitle: '点右下角加一道想尝试的菜，做过后会自动变「已做」',
            );
          }
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) => _ToCookTile(recipe: list[i]),
          );
        },
      ),
    );
  }
}

class _ToCookTile extends ConsumerWidget {
  const _ToCookTile({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(recipe.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) =>
          ref.read(recipeRepositoryProvider).softDelete(recipe.id),
      child: ListTile(
        leading: const Icon(Icons.restaurant_menu),
        title: Text(recipe.title),
        subtitle: recipe.description == null ? null : Text(recipe.description!),
        onTap: () => context.push('/recipe/${recipe.id}'),
        trailing: FilledButton.tonal(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CookingLogFormScreen(
                recipeId: recipe.id,
                recipeTitle: recipe.title,
              ),
            ),
          ),
          child: const Text('做了'),
        ),
      ),
    );
  }
}
