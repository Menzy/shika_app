import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kukuo/providers/auth_provider.dart';
import 'package:kukuo/common/section_heading.dart';
import 'package:kukuo/common/top_section_container.dart';
import 'package:kukuo/providers/exchange_rate_provider.dart';
import 'package:kukuo/providers/user_input_provider.dart';

import 'package:kukuo/widgets/total_balance.dart';
import 'package:kukuo/widgets/added_list.dart';
import 'package:kukuo/widgets/settings_bottom_sheet.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kukuo/widgets/balance_chart.dart';
import 'package:kukuo/models/currency_model.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onSeeAllPressed;

  const HomeScreen({super.key, required this.onSeeAllPressed});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
  }

  // Extracted welcome message widget
  Widget _buildWelcomeMessage(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final displayName = authProvider.username ?? 'User';
    String firstName = displayName.split(' ').first;
    if (firstName.isNotEmpty) {
      firstName = firstName[0].toUpperCase() + firstName.substring(1);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        'Welcome $firstName! Let\'s make our first entry, shall we!',
        style: const TextStyle(
          color: Color.fromARGB(32, 216, 254, 0),
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Extracted assets section widget
  Widget _buildAssetsSection(UserInputProvider userInputProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF00312F),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TSectionHeading(
            title: 'My Assets',
            showActionButton: true,
            onPressed: widget.onSeeAllPressed,
          ),
          const SizedBox(height: 8),
          AddedList(
            currencies: userInputProvider
                .getSortedConsolidatedCurrencies(
                    Provider.of<ExchangeRateProvider>(context).exchangeRates,
                    userInputProvider.selectedCurrency)
                .take(4)
                .toList(),
            selectedLocalCurrency: userInputProvider.selectedCurrency,
            exchangeRateProvider: Provider.of<ExchangeRateProvider>(context),
            isAllAssetsScreen: false,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Loading and error states are now handled in SplashScreen

    return Scaffold(
      body: TTopSectionContainer(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Consumer<UserInputProvider>(
              builder: (context, userInputProvider, _) => TotalBalance(
                selectedLocalCurrency: userInputProvider.selectedCurrency,
                userInputProvider: userInputProvider,
                exchangeRateProvider:
                    Provider.of<ExchangeRateProvider>(context),
              ),
            ),
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (context) => const SettingsBottomSheet(),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00312F),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF00514F),
                  ),
                ),
                child: const Icon(
                  Iconsax.setting_2,
                  color: Color(0xFFD8FE00),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 70),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Consumer<UserInputProvider>(
                builder: (context, userInputProvider, _) {
                  final chart = userInputProvider.currencies.isEmpty
                      ? const SizedBox.shrink()
                      : BalanceChart(
                          balanceHistory: userInputProvider.balanceHistory,
                          investedHistory: userInputProvider.investedHistory,
                          timeHistory: userInputProvider.timeHistory,
                          currencySymbol: Currency.getSymbolForCode(
                              userInputProvider.selectedCurrency),
                        );

                  final assets = userInputProvider.currencies.isEmpty
                      ? _buildWelcomeMessage(context)
                      : _buildAssetsSection(userInputProvider);

                  return Column(
                    children: userInputProvider.showChartAboveAssets
                        ? [chart, const SizedBox(height: 16), assets]
                        : [assets, const SizedBox(height: 16), chart],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
