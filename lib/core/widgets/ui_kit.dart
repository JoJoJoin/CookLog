import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/enums.dart';
import '../../data/providers.dart';

/// 一组贯穿全局的食物渐变配色，按 id 稳定取色，让无图卡片也好看。
const _coverGradients = <List<Color>>[
  [Color(0xFFFF9966), Color(0xFFFF5E62)],
  [Color(0xFFFFB75E), Color(0xFFED8F03)],
  [Color(0xFF56AB2F), Color(0xFFA8E063)],
  [Color(0xFF36D1DC), Color(0xFF5B86E5)],
  [Color(0xFFFFAFBD), Color(0xFFFFC3A0)],
  [Color(0xFFF7971E), Color(0xFFFFD200)],
];

List<Color> _gradientFor(String id) {
  final idx = id.hashCode.abs() % _coverGradients.length;
  return _coverGradients[idx];
}

/// 菜谱/记录封面：有图显缩略图，无图显稳定渐变 + emoji。
///
/// [ownerType] 取 `recipe` 或 `cooking_log`，[ownerId] 为对应主键。
class CoverThumb extends ConsumerWidget {
  const CoverThumb({
    super.key,
    required this.ownerType,
    required this.ownerId,
    this.size = 64,
    this.radius = 16,
    this.emoji = '🍽️',
  });

  final String ownerType;
  final String ownerId;
  final double size;
  final double radius;
  final String emoji;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = ref.watch(
      mediaForOwnerProvider((type: ownerType, id: ownerId)),
    );
    final path = media.maybeWhen(
      data: (list) =>
          list.isEmpty ? null : (list.first.thumbPath ?? list.first.filePath),
      orElse: () => null,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: path == null
            ? _Fallback(id: ownerId, emoji: emoji, size: size)
            : Image.file(File(path), fit: BoxFit.cover),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.id, required this.emoji, required this.size});

  final String id;
  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = _gradientFor(id);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(emoji, style: TextStyle(fontSize: size * 0.42)),
      ),
    );
  }
}

/// 菜谱状态小药丸标签。
class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});

  final RecipeStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg, emoji) = switch (status) {
      RecipeStatus.wantToCook => (
          scheme.tertiaryContainer,
          scheme.onTertiaryContainer,
          '✨'
        ),
      RecipeStatus.cooked => (
          scheme.secondaryContainer,
          scheme.onSecondaryContainer,
          '🍳'
        ),
      RecipeStatus.frequent => (
          scheme.primaryContainer,
          scheme.onPrimaryContainer,
          '❤️'
        ),
      RecipeStatus.shelved => (
          scheme.surfaceContainerHighest,
          scheme.onSurfaceVariant,
          '💤'
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        '$emoji ${status.label}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

/// 五星评分展示（只读）。
class RatingStars extends StatelessWidget {
  const RatingStars(this.rating, {super.key, this.size = 15});

  final int rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating;
        return Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: filled ? const Color(0xFFFFB300) : scheme.outlineVariant,
        );
      }),
    );
  }
}
