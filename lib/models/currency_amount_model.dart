class CurrencyAmount {
  final String code;
  final String name;
  final String flag;
  final double amount;

  CurrencyAmount(
      {required this.code,
      required this.amount,
      required this.name,
      required this.flag});

  // Convert Currency to Map for JSON encoding
  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'flag': flag,
        'amount': amount,
      };

  factory CurrencyAmount.fromJson(Map<String, dynamic> json) {
    return CurrencyAmount(
      code: json['code'],
      name: json['name'] ?? 'Unknown',
      flag: json['flag'] ?? '🏳️',
      amount: json['amount'].toDouble(),
    );
  }
}
