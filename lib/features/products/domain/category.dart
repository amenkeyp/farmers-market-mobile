class Category {
  final int id;
  final String name;
  final int? parentId;
  final List<Category> children;

  const Category({
    required this.id,
    required this.name,
    this.parentId,
    this.children = const [],
  });

  factory Category.fromJson(Map<String, dynamic> j) {
    final raw = j['children'];
    final kids = raw is List
        ? raw
            .whereType<Map>()
            .map((m) => Category.fromJson(Map<String, dynamic>.from(m)))
            .toList()
        : <Category>[];
    return Category(
      id: (j['id'] as num).toInt(),
      name: j['name'] as String? ?? '',
      parentId: (j['parent_id'] as num?)?.toInt(),
      children: kids,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'parent_id': parentId,
        'children': children.map((c) => c.toJson()).toList(),
      };
}
