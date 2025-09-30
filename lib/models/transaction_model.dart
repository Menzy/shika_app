import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Transaction {
  final String currencyCode;
  final double amount;
  final DateTime timestamp;
  final String type; // 'Addition' or 'Subtraction'

  Transaction({
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
        'currencyCode': currencyCode,
        'amount': amount,
        'timestamp': timestamp.toIso8601String(),
        'type': type,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        currencyCode: json['currencyCode'],
        amount: json['amount'],
        timestamp: DateTime.parse(json['timestamp']),
        type: json['type'],
      );
}
