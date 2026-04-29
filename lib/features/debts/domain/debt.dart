class Debt {
  final int id;
  final int farmerId;
  final String? farmerName;
  final num originalAmount;
  final num remainingAmount;
  final num? interestRate;
  final DateTime? createdAt;
  final DateTime? dueAt;
  final String status;

  const Debt({
    required this.id,
    required this.farmerId,
    required this.originalAmount,
    required this.remainingAmount,
    required this.status,
    this.farmerName,
    this.interestRate,
    this.createdAt,
    this.dueAt,
  });

  bool get isOverdue =>
      status != 'paid' && dueAt != null && dueAt!.isBefore(DateTime.now());

  double get progress {
    if (originalAmount <= 0) return 0;
    return ((originalAmount - remainingAmount) / originalAmount)
        .clamp(0, 1)
        .toDouble();
  }

  factory Debt.fromJson(Map<String, dynamic> j) {
    final farmer = j['farmer'];
    String? name;
    if (farmer is Map) {
      name = '${farmer['first_name'] ?? ''} ${farmer['last_name'] ?? ''}'
          .trim();
    }
    return Debt(
      id: (j['id'] as num).toInt(),
      farmerId: (j['farmer_id'] as num).toInt(),
      farmerName: name,
      originalAmount: (j['original_amount'] as num?) ?? 0,
      remainingAmount: (j['remaining_amount'] as num?) ?? 0,
      interestRate: j['interest_rate'] as num?,
      status: j['status'] as String? ?? 'open',
      createdAt: _parseDate(j['issued_at']) ?? _parseDate(j['created_at']),
      dueAt: _parseDate(j['due_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'farmer_id': farmerId,
    'farmer_name': farmerName,
    'original_amount': originalAmount,
    'remaining_amount': remainingAmount,
    'interest_rate': interestRate,
    'status': status,
    'created_at': createdAt?.toIso8601String(),
    'due_at': dueAt?.toIso8601String(),
  };

  static DateTime? _parseDate(dynamic v) {
    if (v is String) return DateTime.tryParse(v);
    return null;
  }
}
