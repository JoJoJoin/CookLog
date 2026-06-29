import 'package:flutter/material.dart';

import '../../core/widgets/empty_placeholder.dart';

/// 菜谱库（M2/M3 完善）。当前为占位。
class RecipesScreen extends StatelessWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('菜谱')),
      body: const EmptyPlaceholder(
        icon: Icons.menu_book_outlined,
        title: '菜谱库',
        subtitle: '沉淀每道菜的做法、改良与做菜时间线',
      ),
    );
  }
}
