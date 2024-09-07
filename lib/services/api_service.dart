import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static Future<Map<String, double>> fetchExchangeRates() async {
    final apiUrl = dotenv.env['API_URL'];
    final apiKey = dotenv.env['API_KEY'];

    // Construct the API URL with your key
    final url = '$apiUrl?app_id=$apiKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      // The rates are contained in the 'rates' field of the response
      Map<String, double> exchangeRates = {};
      data['rates'].forEach((key, value) {
        exchangeRates[key] = value.toDouble();
      });

      return exchangeRates;
    } else {
      // Handle error responses
      throw Exception('Failed to fetch exchange rates');
    }
  }
}
