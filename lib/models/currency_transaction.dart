import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CurrencyTransaction {
  final String? id;
  final String currencyCode;
  final double amount;
  final DateTime timestamp;
  final String type; // 'addition', 'subtraction', etc.

  CurrencyTransaction({
    this.id,
    required this.currencyCode,
    required this.amount,
    required this.timestamp,
    required this.type,
  });

  Color get color =>
      type == 'Addition' ? const Color(0xFFFAFFB5) : const Color(0xFFFF5E00);

  String get formattedAmount {
    final formatter = NumberFormat('#,##0.##');
    return formatter.format(amount.abs());
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'currencyCode': currencyCode,
        'amount': amount,
        'timestamp': timestamp.toIso8601String(),
        'type': type,
      };

  factory CurrencyTransaction.fromJson(Map<String, dynamic> json) {
    return CurrencyTransaction(
      id: json['id'],
      currencyCode: json['currencyCode'],
      amount: json['amount'],
      timestamp: DateTime.parse(json['timestamp']),
      type: json['type'],
    );
  }
}
