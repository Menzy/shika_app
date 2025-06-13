import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kukuo/common/section_heading.dart';
import 'package:kukuo/common/top_section_container.dart';
import 'package:kukuo/providers/exchange_rate_provider.dart';
import 'package:kukuo/providers/user_input_provider.dart';
import 'package:kukuo/screens/currency_screen.dart';
import 'package:kukuo/widgets/total_balance.dart';
import 'package:kukuo/widgets/added_list.dart';
import 'package:kukuo/widgets/growth_chart.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onSeeAllPressed;

  const HomeScreen({super.key, required this.onSeeAllPressed});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedLocalCurrency = 'USD';
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final exchangeRateProvider =
        Provider.of<ExchangeRateProvider>(context, listen: false);
    final userInputProvider =
        Provider.of<UserInputProvider>(context, listen: false);

    exchangeRateProvider.setUserInputProvider(userInputProvider);
    userInputProvider.setExchangeRateProvider(exchangeRateProvider);

    try {
      await Future.wait([
        userInputProvider.loadTransactions(),
        _loadInitialData(),
      ]);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadInitialData() async {
    try {
      await Provider.of<ExchangeRateProvider>(context, listen: false)
          .fetchExchangeRates();
      await Provider.of<UserInputProvider>(context, listen: false)
          .loadCurrencies();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching data: $e')),
        );
      }
    }
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

  // Extracted welcome message widget
  Widget _buildWelcomeMessage() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        'Welcome! Let\'s make our first entry, shall we!',
        style: TextStyle(
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
          const SizedBox(height: 15),
          AddedList(
            currencies:
                userInputProvider.getConsolidatedCurrencies().take(4).toList(),
            selectedLocalCurrency: _selectedLocalCurrency,
            exchangeRateProvider: Provider.of<ExchangeRateProvider>(context),
            isAllAssetsScreen: false,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_error'),
              ElevatedButton(
                onPressed: _initializeData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: TTopSectionContainer(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Consumer<UserInputProvider>(
              builder: (context, userInputProvider, _) => TotalBalance(
                selectedLocalCurrency: _selectedLocalCurrency,
                userInputProvider: userInputProvider,
                exchangeRateProvider:
                    Provider.of<ExchangeRateProvider>(context),
                onTap: _selectLocalCurrency,
              ),
            ),
          ],
        ),
        child: SingleChildScrollView(
          // padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Consumer<UserInputProvider>(
                builder: (context, userInputProvider, _) {
                  return userInputProvider.currencies.isEmpty
                      ? _buildWelcomeMessage()
                      : _buildAssetsSection(userInputProvider);
                },
              ),
              const SizedBox(height: 25),
              Consumer<UserInputProvider>(
                builder: (context, userInputProvider, _) {
                  return userInputProvider.currencies.isEmpty
                      ? const SizedBox.shrink()
                      : GrowthChart(
                          selectedLocalCurrency: _selectedLocalCurrency,
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
