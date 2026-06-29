import 'package:flutter/material.dart';

import '../../core/widgets/empty_placeholder.dart';

/// 首页 / 时间线（M4 完善）。当前为占位。
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('首页')),
      body: const EmptyPlaceholder(
        icon: Icons.timeline_outlined,
        title: '做菜时间线',
        subtitle: '后续里程碑将在这里展示「今天做什么」与历史记录',
      ),
    );
  }
}
