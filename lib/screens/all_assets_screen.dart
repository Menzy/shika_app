import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kukuo/common/section_heading.dart';
import 'package:kukuo/common/top_section_container.dart';
import 'package:kukuo/providers/exchange_rate_provider.dart';
import 'package:kukuo/providers/user_input_provider.dart';
import 'package:kukuo/widgets/added_list.dart';

class AllAssetsScreen extends StatefulWidget {
  const AllAssetsScreen({super.key});

  @override
  State<AllAssetsScreen> createState() => _AllAssetsScreenState();
}

class _AllAssetsScreenState extends State<AllAssetsScreen> {
  @override
  Widget build(BuildContext context) {
    final userInputProvider = Provider.of<UserInputProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF001817),
      body: TTopSectionContainer(
        title: const Text(
          'All Assets',
          style: TextStyle(
            fontFamily: 'Gazpacho',
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Color(0xFFD8FE00),
          ),
        ),
        child: Container(
          // color: const Color(0xFF00312F),
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: Color(0xFF00312F),
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TSectionHeading(
                title: 'All Assets',
                showActionButton: false,
              ),
              const SizedBox(height: 30),
              Expanded(
                child: AddedList(
                  currencies: userInputProvider.currencies,
                  selectedLocalCurrency: '',
                  exchangeRateProvider:
                      Provider.of<ExchangeRateProvider>(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
