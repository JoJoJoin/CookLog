import 'dart:convert';

/// 配方中的单条配料（原材料 / 调味料 + 用量）。
class FormulaIngredient {
  const FormulaIngredient({required this.name, this.amount});

  final String name;

  /// 用量，如「300 克」「2 勺」，可为空。
  final String? amount;

  Map<String, dynamic> toJson() => {
        'name': name,
        if (amount != null && amount!.isNotEmpty) 'amount': amount,
      };

  factory FormulaIngredient.fromJson(Map<String, dynamic> json) {
    return FormulaIngredient(
      name: (json['name'] ?? '').toString(),
      amount: json['amount']?.toString(),
    );
  }
}

/// 将配料列表编码为存库用的 JSON 字符串。
String encodeIngredients(List<FormulaIngredient> items) {
  return jsonEncode(items.map((e) => e.toJson()).toList());
}

/// 将存库的 JSON 字符串解码为配料列表。
List<FormulaIngredient> decodeIngredients(String? raw) {
  if (raw == null || raw.trim().isEmpty) return [];
  try {
    final data = jsonDecode(raw);
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((e) => FormulaIngredient.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.name.isNotEmpty)
        .toList();
  } catch (_) {
    return [];
  }
}
