import 'package:flutter/material.dart';
import 'package:kukuo/common/top_section_container.dart';
import 'package:kukuo/providers/user_input_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class PaperTrailScreen extends StatelessWidget {
  const PaperTrailScreen({super.key});

  Widget _buildEmptyState(double height) {
    return SizedBox(
      height: height,
      child: const Center(
        child: Text(
          'No transactions yet',
          style: TextStyle(
            color: Color(0xFFFAFFB5),
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(transaction) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF001817),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Row(
          children: [
            Expanded(
              child: Text(
                '${transaction.currencyCode} ${transaction.formattedAmount}',
                style: TextStyle(
                  color: transaction.color,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              transaction.type == 'Addition'
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
              color: transaction.color,
              size: 16,
            ),
          ],
        ),
        trailing: Text(
          DateFormat('MMM dd, yyyy').format(transaction.timestamp),
          style: TextStyle(
            color: transaction.color,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableHeight = MediaQuery.of(context).size.height - 300;

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
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          color: Color(0xFF00312F),
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        child: Consumer<UserInputProvider>(
          builder: (context, provider, child) {
            // Get transactions and reverse the list to show newest at the top
            final transactions = provider.getTransactions().reversed.toList();

            if (transactions.isEmpty) {
              return _buildEmptyState(availableHeight);
            }

            return Container(
              constraints: BoxConstraints(
                minHeight: availableHeight - 20, // Adjusted for padding
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Transaction History',
                      style: TextStyle(
                        color: Color(0xFF008F8A),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  ...transactions.map(_buildTransactionItem),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
