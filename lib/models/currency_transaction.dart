class CurrencyTransaction {
  final String currencyCode;
  final double amount;
  final DateTime timestamp;
  final String type; // 'addition', 'subtraction', etc.

  CurrencyTransaction({
    required this.currencyCode,
    required this.amount,
    required this.timestamp,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'currencyCode': currencyCode,
        'amount': amount,
        'timestamp': timestamp.toIso8601String(),
        'type': type,
      };

  factory CurrencyTransaction.fromJson(Map<String, dynamic> json) {
    return CurrencyTransaction(
      currencyCode: json['currencyCode'],
      amount: json['amount'],
      timestamp: DateTime.parse(json['timestamp']),
      type: json['type'],
    );
  }
}
