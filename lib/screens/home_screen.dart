import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:kukuo/common/section_heading.dart';
import 'package:kukuo/common/top_section_container.dart';
import 'package:kukuo/models/balance_data.dart';
import 'package:kukuo/providers/exchange_rate_provider.dart';
import 'package:kukuo/providers/user_input_provider.dart';
import 'package:kukuo/screens/all_assets_screen.dart';
import 'package:kukuo/screens/currency_screen.dart';
import 'package:kukuo/widgets/balance_chart_data.dart';
import 'package:kukuo/widgets/total_balance.dart';
import 'package:kukuo/widgets/added_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedLocalCurrency = 'USD'; // Default local currency
  bool _loadingRates = true; // Flag to check if exchange rates are loading

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      await Provider.of<ExchangeRateProvider>(context, listen: false)
          .fetchExchangeRates();
      await Provider.of<UserInputProvider>(context, listen: false)
          .loadCurrencies();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingRates = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userInputProvider = Provider.of<UserInputProvider>(context);
    final exchangeRateProvider = Provider.of<ExchangeRateProvider>(context);

    if (_loadingRates) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (exchangeRateProvider.exchangeRates.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Exchange rates are not available')),
      );
    }

    return Scaffold(
      body: TTopSectionContainer(
        title: // Total amount display
            TotalBalance(
          selectedLocalCurrency: _selectedLocalCurrency,
          userInputProvider: userInputProvider,
          exchangeRateProvider: exchangeRateProvider,
          onTap: _selectLocalCurrency,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome message for first-time users 
              if (userInputProvider.currencies.isEmpty)
                const Center(
                    child: Text(
                  'Welcome, lets make our First entry shall we!',
                  style: TextStyle(
                    color: Color.fromARGB(32, 216, 254, 0),
                    fontSize: 34,
                  ),
                )),

              // Currency list showing only top 4 currencies
              if (userInputProvider.currencies.isNotEmpty)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFF00312F),
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TSectionHeading(
                          title: 'My Assets',
                          showActionButton: true,
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const AllAssetsScreen()));
                          },
                        ),
                        AddedList(
                          currencies: userInputProvider.getTopCurrencies(4),
                          selectedLocalCurrency: _selectedLocalCurrency,
                          exchangeRateProvider: exchangeRateProvider,
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 25),
              Container(
                height: 350,
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFF00312F),
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const TSectionHeading(
                        title: 'Growth %',
                        showActionButton: true,
                        buttonTitle: '28D'),
                    const Row(
                      children: [
                        Text('+20%',
                            style: TextStyle(
                                fontSize: 25, color: Color(0xFFFAFFB5))),
                        Icon(
                          Iconsax.arrow_up,
                          color: Color(0xFFD8FE00),
                        )
                      ],
                    ),
                    SizedBox(height: 200, child: BalanceChart(data: data)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectLocalCurrency() async {
    final selectedCurrency = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CurrencyScreen(),
      ),
    );

    if (selectedCurrency != null) {
      setState(() {
        _selectedLocalCurrency = selectedCurrency;
      });
    }
  }
}
