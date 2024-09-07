import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shika_app/models/currency_model.dart';
import 'package:shika_app/providers/user_input_provider.dart';
import 'package:shika_app/screens/edit_currency_screen.dart';
import 'package:shika_app/widgets/currency_formatter.dart';

class CurrencyDetailsScreen extends StatelessWidget {
  final Currency currency;
  final int index;

  const CurrencyDetailsScreen({
    required this.currency,
    required this.index,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final userInputProvider =
        Provider.of<UserInputProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Currency: ${currency.code}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              'Amount: ${currency.amount.toStringAsCurrency()}', // Apply currency formatting
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditCurrencyScreen(
                            currency: currency,
                            index: index,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      backgroundColor: Colors.amber,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      userInputProvider.removeCurrency(index);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      backgroundColor: Colors.red,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
