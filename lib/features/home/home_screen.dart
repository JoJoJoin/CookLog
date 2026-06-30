import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/brand_fx.dart';
import '../../core/widgets/emoji_empty_state.dart';
import '../../core/widgets/quick_add_sheet.dart';
import '../../core/widgets/ui_kit.dart';
import '../../data/db/database.dart';
import '../../data/providers.dart';

/// 首页：问候头部 + 今天做什么推荐 + 做菜时间线（按月分组卡片）。
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(allCookingLogsProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showQuickAddSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('记一笔'),
      ),
      body: BrandBackdrop(
        child: SafeArea(
          bottom: false,
          child: logs.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('加载失败：$e')),
            data: (list) {
              return CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(child: _GreetingHeader()),
                  const SliverToBoxAdapter(child: _TodayPickCard()),
                  if (list.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyTimeline(),
                    )
                  else
                    ..._timelineSlivers(context, list),
                  const SliverToBoxAdapter(child: SizedBox(height: 96)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _timelineSlivers(BuildContext context, List<CookingLog> logs) {
    final entries = _groupByMonth(logs);
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        sliver: SliverList.builder(
          itemCount: entries.length,
          itemBuilder: (context, i) {
            final entry = entries[i];
            if (entry.isHeader) {
              return Padding(
                padding: EdgeInsets.fromLTRB(4, i == 0 ? 4 : 20, 4, 10),
                child: Text(
                  entry.header!,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: StaggerItem(index: i, child: _LogCard(log: entry.log!)),
            );
          },
        ),
      ),
    ];
  }

  /// 按「yyyy年M月」分组，返回交错的表头/日志条目（保持原有时间排序）。
  List<_Entry> _groupByMonth(List<CookingLog> logs) {
    final result = <_Entry>[];
    String? current;
    for (final log in logs) {
      final d = DateTime.fromMillisecondsSinceEpoch(log.cookedAt);
      final key = DateFormat('yyyy 年 M 月').format(d);
      if (key != current) {
        current = key;
        result.add(_Entry.header(key));
      }
      result.add(_Entry.log(log));
    }
    return result;
  }
}

/// 时间线列表项：表头或一条日志。
class _Entry {
  _Entry.header(this.header) : log = null;
  _Entry.log(this.log) : header = null;

  final String? header;
  final CookingLog? log;

  bool get isHeader => header != null;
}

/// 顶部问候语，按时段切换。
class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader();

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final (greeting, emoji) = switch (hour) {
      >= 5 && < 11 => ('早上好', '🌤️'),
      >= 11 && < 14 => ('中午好', '🍜'),
      >= 14 && < 18 => ('下午好', '🍰'),
      _ => ('晚上好', '🌙'),
    };
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$greeting $emoji', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  '今天又做了什么好吃的？',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 「今天做什么」推荐卡：从想做清单随机挑一道。
class _TodayPickCard extends ConsumerWidget {
  const _TodayPickCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishes = ref.watch(wantToCookProvider);
    return wishes.maybeWhen(
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        final pick = list[DateTime.now().day % list.length];
        final scheme = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Material(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(22),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.push('/recipe/${pick.id}'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CoverThumb(
                      ownerType: 'recipe',
                      ownerId: pick.id,
                      size: 56,
                      radius: 14,
                      emoji: '🎲',
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '今天做这道吧',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color:
                                  scheme.onPrimaryContainer.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pick.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_rounded,
                        color: scheme.onPrimaryContainer),
                  ],
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

class _EmptyTimeline extends StatelessWidget {
  const _EmptyTimeline();

  @override
  Widget build(BuildContext context) {
    return EmojiEmptyState(
      emoji: '🍳',
      title: '开启你的做菜日记',
      subtitle: '点右下角记录今天做的菜，\n或在「想做」里把灵感存下来',
      tone: Theme.of(context).colorScheme.primaryContainer,
    );
  }
}

/// 时间线单条做菜记录卡。
class _LogCard extends ConsumerWidget {
  const _LogCard({required this.log});

  final CookingLog log;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final d = DateTime.fromMillisecondsSinceEpoch(log.cookedAt);
    final dateText = DateFormat('M月d日').format(d);
    final recipeId = log.recipeId;
    final title = recipeId == null
        ? const AsyncValue<Recipe?>.data(null)
        : ref.watch(recipeDetailProvider(recipeId));
    final titleText = title.maybeWhen(
      data: (r) => r?.title ?? '随手记',
      orElse: () => '…',
    );
    return Card(
      child: InkWell(
        onTap: recipeId == null ? null : () => context.push('/recipe/$recipeId'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CoverThumb(
                ownerType: 'cooking_log',
                ownerId: log.id,
                size: 72,
                radius: 16,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            titleText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        if (log.rating != null) RatingStars(log.rating!),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateText,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (log.notes != null && log.notes!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        log.notes!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
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
