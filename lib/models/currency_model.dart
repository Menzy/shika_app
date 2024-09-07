class Currency {
  final String code; // e.g., 'USD', 'GBP'
  final double amount; // e.g., 200.0

  Currency({required this.code, required this.amount});

  // Convert Currency to Map for JSON encoding
  Map<String, dynamic> toJson() => {
    'code': code,
    'amount': amount,
  };

  // Create Currency from Map
  factory Currency.fromJson(Map<String, dynamic> json) => Currency(
    code: json['code'],
    amount: json['amount'],
  );
}