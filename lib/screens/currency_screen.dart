import 'package:flutter/material.dart';
import 'package:shika_app/models/currency_list.dart';

class CurrencyScreen extends StatefulWidget {
  @override
  _CurrencyScreenState createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> {
  TextEditingController _searchController = TextEditingController();
  List<Currency> _filteredCurrencies = currencies;
  int? _selectedIndex;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _filterCurrencies();
    });
  }

  void _filterCurrencies() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCurrencies = currencies.where((currency) {
        final nameLower = currency.name.toLowerCase();
        final codeLower = currency.code.toLowerCase();
        return nameLower.contains(query) || codeLower.contains(query);
      }).toList();
    });
  }

  void _onCurrencySelected(int index) {
    Navigator.pop(context, _filteredCurrencies[index].code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? AnimatedContainer(
                duration: Duration(milliseconds: 300),
                width:
                    _isSearching ? MediaQuery.of(context).size.width - 80 : 0,
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    border: InputBorder.none,
                  ),
                ),
              )
            : Text('Currencies'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _filteredCurrencies = currencies;
                }
              });
            },
          ),
        ],
      ),
      body: ListView.separated(
        itemCount: _filteredCurrencies.length,
        separatorBuilder: (context, index) => Divider(),
        itemBuilder: (context, index) {
          final currency = _filteredCurrencies[index];
          final isSelected = _selectedIndex == index;
          return ListTile(
            leading: Text(
              currency.flagEmoji,
              style: const TextStyle(fontSize: 24), // Adjust size as needed
            ),
            title: Text(currency.name),
            subtitle: Text(currency.code),
            trailing:
                isSelected ? Icon(Icons.check, color: Colors.green) : null,
            onTap: () => _onCurrencySelected(index),
          );
        },
      ),
    );
  }
}
