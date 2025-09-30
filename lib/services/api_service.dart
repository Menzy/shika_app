import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl =
      'https://time-lapse-backend.vercel.app/api/rates';

  static Future<Map<String, double>> fetchExchangeRates() async {
    try {
      // Add ?all=true parameter to get all available currencies (~170) instead of default 15
      const url = '$_baseUrl?all=true';
      debugPrint('Fetching exchange rates from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        debugPrint(
            'Successfully fetched ${data['currencies_returned'] ?? 'unknown'} currencies');

        // The rates are contained in the 'rates' field of the response
        Map<String, double> exchangeRates = {};
        if (data.containsKey('rates')) {
          data['rates'].forEach((key, value) {
            if (value is num) {
              exchangeRates[key] = value.toDouble();
            }
          });

          debugPrint(
              'Successfully parsed ${exchangeRates.length} exchange rates');
          return exchangeRates;
        } else {
          throw Exception('No rates data found in API response');
        }
      } else {
        throw Exception(
            'Failed to fetch exchange rates: HTTP ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      debugPrint('Error fetching exchange rates: $e');
      rethrow;
    }
  }
}
