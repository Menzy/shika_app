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
import 'package:kukuo/providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onSeeAllPressed;

  const HomeScreen({super.key, required this.onSeeAllPressed});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedLocalCurrency = 'USD'; // Default local currency

  @override
  void initState() {
    super.initState();
    final exchangeRateProvider =
        Provider.of<ExchangeRateProvider>(context, listen: false);
    final userInputProvider =
        Provider.of<UserInputProvider>(context, listen: false);

    exchangeRateProvider.setUserInputProvider(userInputProvider);
    userInputProvider.setExchangeRateProvider(exchangeRateProvider);
    userInputProvider.loadTransactions();
    _loadInitialData();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TTopSectionContainer(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Consumer<UserInputProvider>(
              builder: (context, userInputProvider, child) {
                return TotalBalance(
                  selectedLocalCurrency: _selectedLocalCurrency,
                  userInputProvider: userInputProvider,
                  exchangeRateProvider:
                      Provider.of<ExchangeRateProvider>(context),
                  onTap: _selectLocalCurrency,
                );
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.exit_to_app,
                color: Colors.white,
              ),
              onPressed: () {
                context.read<AuthProvider>().signOut(context);
              },
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Consumer<UserInputProvider>(
                builder: (context, userInputProvider, child) {
                  return userInputProvider.currencies.isEmpty
                      ? Center(
                          child: Consumer<AuthProvider>(
                          builder: (context, auth, _) => Text(
                            'Welcome ${auth.username ?? 'User'}, let\'s make our first entry, shall we!',
                            style: const TextStyle(
                              color: Color.fromARGB(32, 216, 254, 0),
                              fontSize: 34,
                            ),
                          ),
                        ))
                      : Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color(0xFF00312F),
                            borderRadius: BorderRadius.all(Radius.circular(16)),
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
                                currencies: userInputProvider
                                    .getConsolidatedCurrencies()
                                    .take(4) // Only take first 4 items
                                    .toList(),
                                selectedLocalCurrency: _selectedLocalCurrency,
                                exchangeRateProvider:
                                    Provider.of<ExchangeRateProvider>(context),
                                isAllAssetsScreen:
                                    false, // Default value, can be omitted
                              )
                            ],
                          ),
                        );
                },
              ),
              const SizedBox(height: 25),

              // Growth Chart Section
              Consumer<UserInputProvider>(
                builder: (context, userInputProvider, child) {
                  // Only show the graph if currencies exist
                  if (userInputProvider.currencies.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return GrowthChart(
                    selectedLocalCurrency:
                        _selectedLocalCurrency, // Add this parameter
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
