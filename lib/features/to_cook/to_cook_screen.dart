import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/brand_fx.dart';
import '../../core/widgets/emoji_empty_state.dart';
import '../../core/widgets/quick_add_sheet.dart';
import '../../core/widgets/ui_kit.dart';
import '../../data/db/database.dart';
import '../../data/models/enums.dart';
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
      appBar: AppBar(title: const Text('想做清单')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showQuickAddSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('添加'),
      ),
      body: BrandBackdrop(
        child: recipes.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('加载失败：$e')),
          data: (list) {
            if (list.isEmpty) {
              return EmojiEmptyState(
                emoji: '📝',
                title: '先收藏几道灵感菜',
                subtitle: '刷到好菜谱？点一下就能存。\n周末做菜再也不纠结。',
                tone: Theme.of(context).colorScheme.tertiaryContainer,
                actionText: '添加想做菜谱',
                onAction: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const WantToCookFormScreen()),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 96),
              itemCount: list.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: StaggerItem(index: i, child: _ToCookCard(recipe: list[i])),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ToCookCard extends ConsumerWidget {
  const _ToCookCard({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(recipe.id),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Icon(
          Icons.delete_outline_rounded,
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
      ),
      onDismissed: (_) =>
          ref.read(recipeRepositoryProvider).softDelete(recipe.id),
      child: Card(
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
                  size: 78,
                  radius: 18,
                  emoji: '🥗',
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          StatusPill(RecipeStatus.wantToCook),
                          const Spacer(),
                          Text(
                            '想做',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        recipe.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (recipe.description != null &&
                          recipe.description!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          recipe.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color:
                                    Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.tonalIcon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CookingLogFormScreen(
                                recipeId: recipe.id,
                                recipeTitle: recipe.title,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.local_fire_department_rounded),
                          label: const Text('今天做了'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
