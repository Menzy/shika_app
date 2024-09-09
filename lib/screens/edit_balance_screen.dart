import 'package:flutter/material.dart';
import 'package:kukuo/common/top_section_container.dart';
import 'package:provider/provider.dart';
import 'package:kukuo/models/currency_amount_model.dart';
import 'package:kukuo/providers/user_input_provider.dart';
import 'package:kukuo/screens/edit_currency_screen.dart';
import 'package:kukuo/widgets/currency_formatter.dart';

class EditBalanceScreen extends StatelessWidget {
  final CurrencyAmount currency;
  final int index;

  const EditBalanceScreen({
    required this.currency,
    required this.index,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final userInputProvider =
        Provider.of<UserInputProvider>(context, listen: false);

    return Scaffold(
      body: TTopSectionContainer(
        title: const Text(
          'Edit Balance',
          style: TextStyle(
            fontFamily: 'Gazpacho',
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Color(0xFFD8FE00),
          ),
        ),

        // Display the currency details
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

