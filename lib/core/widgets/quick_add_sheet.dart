import 'package:flutter/material.dart';

import '../../features/cooking_log/cooking_log_form.dart';
import '../../features/to_cook/want_to_cook_form.dart';

/// FAB 二级动作：底部弹层「想做的菜 / 今天做的菜」。
Future<void> showQuickAddSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  '记一笔',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
              ),
              _QuickAction(
                emoji: '📝',
                title: '想做的菜',
                subtitle: '刷到好菜谱，先存下来',
                color: Theme.of(sheetContext).colorScheme.tertiaryContainer,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const WantToCookFormScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _QuickAction(
                emoji: '🍳',
                title: '今天做的菜',
                subtitle: '记录这次的心得与照片',
                color: Theme.of(sheetContext).colorScheme.secondaryContainer,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CookingLogFormScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
