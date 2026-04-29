class Farmer {
  final int id;
  final String identifier;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? village;
  final String? region;
  final num? creditLimit;
  final num? totalDebt;
  final num? availableCredit;

  const Farmer({
    required this.id,
    required this.identifier,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.village,
    this.region,
    this.creditLimit,
    this.totalDebt,
    this.availableCredit,
  });

  String get fullName => '$firstName $lastName'.trim();
  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    return (f + l).toUpperCase();
  }

  factory Farmer.fromJson(Map<String, dynamic> j) => Farmer(
    id: (j['id'] as num).toInt(),
    identifier: j['identifier'] as String? ?? '',
    firstName: j['first_name'] as String? ?? '',
    lastName: j['last_name'] as String? ?? '',
    phone: j['phone'] as String?,
    village: j['village'] as String?,
    region: j['region'] as String?,
    creditLimit: j['credit_limit'] as num?,
    totalDebt: (j['current_debt'] as num?) ?? (j['total_debt'] as num?),
    availableCredit: j['available_credit'] as num?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'identifier': identifier,
    'first_name': firstName,
    'last_name': lastName,
    'phone': phone,
    'village': village,
    'region': region,
    'credit_limit': creditLimit,
    'total_debt': totalDebt,
    'available_credit': availableCredit,
  };
}
