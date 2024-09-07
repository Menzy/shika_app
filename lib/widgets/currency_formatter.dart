import 'package:intl/intl.dart';

extension CurrencyFormatter on double {
  String toStringAsCurrency() {
    final formatter = NumberFormat.currency(
      locale: 'en_US', // You can change the locale if needed
      symbol: '', // You can add a symbol if you want, e.g., '\$'
      decimalDigits: 2,
    );
    return formatter.format(this);
  }
}
