import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/empty_placeholder.dart';
import '../../data/db/database.dart';
import '../../data/providers.dart';
import '../cooking_log/cooking_log_form.dart';

/// 首页：做菜记录时间线（F-02 列表，按月分组），右下角随手记一笔。
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
          final entries = _groupByMonth(list);
          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, i) {
              final entry = entries[i];
              if (entry.isHeader) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    entry.header!,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                );
              }
              return _LogTile(log: entry.log!);
            },
          );
        },
      ),
    );
  }

  /// 按「yyyy年M月」分组，返回交错的表头/日志条目（保持原有时间排序）。
  List<_Entry> _groupByMonth(List<CookingLog> logs) {
    final result = <_Entry>[];
    String? current;
    for (final log in logs) {
      final d = DateTime.fromMillisecondsSinceEpoch(log.cookedAt);
      final key = DateFormat('yyyy年M月').format(d);
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

class _LogTile extends ConsumerWidget {
  const _LogTile({required this.log});

  final CookingLog log;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = DateTime.fromMillisecondsSinceEpoch(log.cookedAt);
    final dateText = DateFormat('M月d日').format(d);
    final recipeId = log.recipeId;
    final title = recipeId == null
        ? const AsyncValue<Recipe?>.data(null)
        : ref.watch(recipeDetailProvider(recipeId));
    final media = ref.watch(
      mediaForOwnerProvider((type: 'cooking_log', id: log.id)),
    );
    final thumb = media.maybeWhen(
      data: (list) =>
          list.isEmpty ? null : (list.first.thumbPath ?? list.first.filePath),
      orElse: () => null,
    );
    final titleText = title.maybeWhen(
      data: (r) => r?.title ?? '随手记',
      orElse: () => '…',
    );
    final subtitle = [
      dateText,
      if (log.notes != null && log.notes!.isNotEmpty) log.notes!,
    ].join(' · ');
    return ListTile(
      leading: thumb == null
          ? const CircleAvatar(
              child: Icon(Icons.local_fire_department_outlined))
          : ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(thumb),
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            ),
      title: Text(titleText),
      subtitle: Text(subtitle),
      trailing: log.rating == null ? null : Text('★ ${log.rating}'),
      onTap: recipeId == null ? null : () => context.push('/recipe/$recipeId'),
    );
  }
}
