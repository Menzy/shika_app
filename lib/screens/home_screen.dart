import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shika_app/providers/exchange_rate_provider.dart';
import 'package:shika_app/providers/user_input_provider.dart';
import 'package:shika_app/screens/currency_input_screen.dart';
import 'package:shika_app/screens/currency_screen.dart';
import 'package:shika_app/widgets/total_amount_display.dart';
import 'package:shika_app/widgets/currency_list.dart';

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
      print('Error fetching data: $e');
    } finally {
      setState(() {
        _loadingRates = false;
      });
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total amount display
              TotalAmountDisplay(
                selectedLocalCurrency: _selectedLocalCurrency,
                userInputProvider: userInputProvider,
                exchangeRateProvider: exchangeRateProvider,
                onTap: _selectLocalCurrency,
              ),
              const SizedBox(height: 20),
              // List of tiles
              if (userInputProvider.currencies.isEmpty)
                const Center(child: Text('No currencies or money saved.')),
              if (userInputProvider.currencies.isNotEmpty)
                Expanded(
                  child: CurrencyList(
                    currencies: userInputProvider.currencies,
                    selectedLocalCurrency: _selectedLocalCurrency,
                    exchangeRateProvider: exchangeRateProvider,
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CurrencyInputScreen(),
            ),
          );
        },
        backgroundColor: Colors.amber,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _selectLocalCurrency() async {
    final selectedCurrency = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CurrencyScreen(),
      ),
    );

    if (selectedCurrency != null) {
      setState(() {
        _selectedLocalCurrency = selectedCurrency;
      });
    }
  }
}
