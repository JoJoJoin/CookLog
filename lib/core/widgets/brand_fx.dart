import 'package:flutter/material.dart';

/// 页面背景装饰：顶部渐变与几何光斑，强化品牌记忆点。
class BrandBackdrop extends StatelessWidget {
  const BrandBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Positioned(
          top: -120,
          left: -30,
          right: -30,
          child: IgnorePointer(
            child: Container(
              height: 260,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    scheme.primaryContainer.withValues(alpha: 0.55),
                    scheme.surface.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: -36,
          right: -24,
          child: IgnorePointer(
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: scheme.tertiaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(48),
              ),
            ),
          ),
        ),
        Positioned(
          top: 34,
          left: -18,
          child: IgnorePointer(
            child: Transform.rotate(
              angle: -0.4,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// 列表项渐入动效：带轻微上移动画，按 [index] 错峰进入。
class StaggerItem extends StatelessWidget {
  const StaggerItem({
    super.key,
    required this.index,
    required this.child,
    this.maxDelay = 7,
  });

  final int index;
  final Widget child;
  final int maxDelay;

  @override
  Widget build(BuildContext context) {
    final delayIndex = index > maxDelay ? maxDelay : index;
    final begin = 0.86 + delayIndex * 0.02;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: begin, end: 1),
      duration: Duration(milliseconds: 320 + delayIndex * 34),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final dy = (1 - value) * 12;
        return Opacity(
          opacity: value.clamp(0, 1),
          child: Transform.translate(offset: Offset(0, dy), child: child),
        );
      },
      child: child,
    );
  }
}
