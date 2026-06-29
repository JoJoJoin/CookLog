import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/empty_placeholder.dart';
import '../../data/db/database.dart';
import '../../data/providers.dart';
import '../cooking_log/cooking_log_form.dart';

/// 首页：做菜记录时间线（F-02 列表），右下角随手记一笔。
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(allCookingLogsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('首页')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CookingLogFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('记一笔'),
      ),
      body: logs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyPlaceholder(
              icon: Icons.timeline_outlined,
              title: '还没有做菜记录',
              subtitle: '点右下角记录今天做的菜，或在「想做」里点「做了」',
            );
          }
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) => _LogTile(log: list[i]),
          );
        },
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.log});

  final CookingLog log;

  @override
  Widget build(BuildContext context) {
    final d = DateTime.fromMillisecondsSinceEpoch(log.cookedAt);
    final dateText =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return ListTile(
      leading: const Icon(Icons.local_fire_department_outlined),
      title: Text(dateText),
      subtitle: log.notes == null ? null : Text(log.notes!),
      trailing: log.rating == null ? null : Text('★ ${log.rating}'),
    );
  }
}
