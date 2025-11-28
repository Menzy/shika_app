import 'package:flutter/material.dart';
import 'package:kukuo/common/section_heading.dart';
import 'package:kukuo/common/top_section_container.dart';
import 'package:kukuo/providers/user_input_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class PaperTrailScreen extends StatelessWidget {
  const PaperTrailScreen({super.key});

  Widget _buildTransactionItem(transaction) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 5, 0, 20),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Color(0xFF001817),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${transaction.currencyCode} ${transaction.formattedAmount}',
            style: TextStyle(
              color: transaction.color,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            DateFormat('dd.MM.yyyy').format(transaction.timestamp),
            style: TextStyle(
              color: transaction.color,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TTopSectionContainer(
      title: const Text(
        'PaperTrail',
        style: TextStyle(
          fontFamily: 'Gazpacho',
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: Color(0xFFD8FE00),
        ),
      ),
      child: Consumer<UserInputProvider>(
        builder: (context, provider, child) {
          // Get transactions and reverse the list to show newest at the top
          final transactions = provider.getTransactions().reversed.toList();

          return SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF00312F),
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TSectionHeading(
                    title: 'Transaction History',
                    showActionButton: false,
                  ),
                  const SizedBox(height: 8),
                  if (transactions.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 32.0),
                        child: Text(
                          'No transactions yet',
                          style: TextStyle(
                            color: Color(0xFFFAFFB5),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  else
                    ...transactions.map(_buildTransactionItem),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
