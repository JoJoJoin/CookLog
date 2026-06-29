import 'package:flutter/material.dart';

import '../../core/widgets/empty_placeholder.dart';

/// 想做清单（M2 完善）。当前为占位。
class ToCookScreen extends StatelessWidget {
  const ToCookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('想做')),
      body: const EmptyPlaceholder(
        icon: Icons.favorite_border,
        title: '想做清单',
        subtitle: '收藏想尝试的菜，做过后自动流转为「已做」',
      ),
    );
  }
}
