import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove any non-digit characters except for the decimal point
    final numericString = newValue.text.replaceAll(RegExp(r'[^\d.]'), '');

    if (numericString.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Handle the decimal point
    final parts = numericString.split('.');
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : '';

    final number = int.tryParse(integerPart) ?? 0;
    final formatter = NumberFormat('#,###', 'en_US');
    final formattedIntegerPart = formatter.format(number);

    final formattedString = decimalPart.isNotEmpty
        ? '$formattedIntegerPart.$decimalPart'
        : formattedIntegerPart;

    // Return the updated value with the formatted string
    return newValue.copyWith(
      text: formattedString,
      selection: TextSelection.collapsed(offset: formattedString.length),
    );
  }
}
