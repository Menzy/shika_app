// class CurrencyAmount {
//   final String code;
//   final double amount;

//   CurrencyAmount({required this.code, required this.amount});

//   // Convert Currency to Map for JSON encoding
//   Map<String, dynamic> toJson() => {
//         'code': code,
//         'amount': amount,
//       };

//   // Create Currency from Map
//   factory CurrencyAmount.fromJson(Map<String, dynamic> json) => CurrencyAmount(
//         code: json['code'],
//         amount: json['amount'],
//       );
// }

import 'package:kukuo/models/currency_model.dart';

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
    String code = json['code'];
    double amount = json['amount'];

    // Find the corresponding currency details from the local list
    Currency? currency = localCurrencyList.firstWhere(
      (c) => c.code == code,
      orElse: () => Currency(
          code: code, name: 'Unknown', flag: '🏳️'), // default if not found
    );

    return CurrencyAmount(
      code: currency.code,
      name: currency.name,
      flag: currency.flag,
      amount: amount,
    );
  }
}
