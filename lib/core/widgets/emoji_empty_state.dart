import 'package:flutter/material.dart';

/// 统一空状态组件：emoji 头像 + 标题 + 副文案 + 可选主按钮。
class EmojiEmptyState extends StatelessWidget {
  const EmojiEmptyState({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.tone,
    this.actionText,
    this.onAction,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final Color? tone;
  final String? actionText;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = tone ?? theme.colorScheme.primaryContainer;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 44)),
            ),
            const SizedBox(height: 20),
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded),
                label: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
