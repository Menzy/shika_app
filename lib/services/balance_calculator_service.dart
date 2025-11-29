import 'dart:math' as math;

class BalanceCalculatorService {
  /// Calculates the total balance in the specified local currency
  static double calculateTotalInLocalCurrency(List<dynamic> currencies,
      String localCurrencyCode, Map<String, double> exchangeRates,
      {required String Function(dynamic) getCode,
      required double Function(dynamic) getAmount}) {
    double total = 0.0;

    for (final currency in currencies) {
      final code = getCode(currency);
      final amount = getAmount(currency);
      if (code == localCurrencyCode) {
        total += amount;
        continue;
      }

      final rate = exchangeRates[code];

      if (rate != null) {
        final localRate = exchangeRates[localCurrencyCode] ?? 1.0;

        // Convert to USD first (assuming rates are USD-based), then to local currency
        // If rate is FROM USD TO currency, then: USD = amount / rate
        // If rate is FROM currency TO USD, then: USD = amount * rate
        // Based on typical API behavior, rates are usually FROM USD TO currency
        double amountInUSD = amount / rate;
        double amountInLocalCurrency = amountInUSD * localRate;

        total += amountInLocalCurrency;
      }
    }

    return total;
  }

  /// Validates if a currency amount is valid
  static bool isValidCurrencyAmount(double amount) {
    return amount > 0 && amount < double.infinity;
  }

  /// Converts amount from one currency to another
  static double convertCurrency(
    double amount,
    String fromCurrency,
    String toCurrency,
    Map<String, double> exchangeRates,
  ) {
    final fromRate = exchangeRates[fromCurrency];
    final toRate = exchangeRates[toCurrency];

    if (fromRate == null || toRate == null) {
      throw ArgumentError('Exchange rate not found for currency conversion');
    }

    return amount / fromRate * toRate;
  }

  /// Gets the exchange rate between two currencies
  static double? getExchangeRate(
    String fromCurrency,
    String toCurrency,
    Map<String, double> exchangeRates,
  ) {
    final fromRate = exchangeRates[fromCurrency];
    final toRate = exchangeRates[toCurrency];

    if (fromRate == null || toRate == null) {
      return null;
    }

    return toRate / fromRate;
  }

  /// Calculates percentage change between two values
  static double calculatePercentageChange(double oldValue, double newValue) {
    if (oldValue == 0) return 0;
    return ((newValue - oldValue) / oldValue) * 100;
  }

  /// Formats currency amount with appropriate decimal places
  static String formatCurrencyAmount(double amount, {int decimalPlaces = 2}) {
    return amount.toStringAsFixed(decimalPlaces);
  }

  /// Rounds currency amount to appropriate decimal places
  static double roundCurrencyAmount(double amount, {int decimalPlaces = 2}) {
    final factor = math.pow(10, decimalPlaces);
    return (amount * factor).round() / factor;
  }
}
