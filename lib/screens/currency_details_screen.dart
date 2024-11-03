import 'package:flutter/material.dart';
import 'package:kukuo/common/top_section_container.dart';
import 'package:kukuo/models/currency_transaction.dart';

class CurrencyDetailScreen extends StatelessWidget {
  final String currencyCode;
  final List<CurrencyTransaction> transactions;

  const CurrencyDetailScreen({
    super.key,
    required this.currencyCode,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TTopSectionContainer(
        title: Text(
          '$currencyCode Transaction History',
          style: const TextStyle(color: Color(0xFFFAFFB5), fontSize: 22),
        ),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: Color(0xFF00312F),
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          // Wrap everything in a ConstrainedBox to give it a fixed height
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height -
                  200, // Adjust this value as needed
            ),
            child: Column(
              children: [
                // Summary Card
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF001817),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total $currencyCode',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        transactions
                            .fold<double>(
                              0,
                              (sum, transaction) => sum + transaction.amount,
                            )
                            .toString(),
                        style: const TextStyle(
                          color: Color(0xFFFAFFB5),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Transactions List
                Expanded(
                  child: transactions.isEmpty
                      ? const Center(
                          child: Text(
                            'No transactions yet',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            final transaction = transactions[index];
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: const Color(0xFF001817),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${transaction.amount > 0 ? '+' : ''}${transaction.amount}',
                                        style: TextStyle(
                                          color: transaction.amount > 0
                                              ? Colors.green
                                              : Colors.red,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatDate(transaction.timestamp),
                                        style: const TextStyle(
                                          color: Color(0xFF00514F),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    transaction.type,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
