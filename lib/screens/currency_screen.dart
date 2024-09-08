import 'package:flutter/material.dart';
import 'package:kukuo/common/top_section_container.dart';
import 'package:kukuo/models/currency_model.dart';

class CurrencyScreen extends StatefulWidget {
  const CurrencyScreen({super.key});

  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> {
  TextEditingController _searchController = TextEditingController();
  List<Currency> _filteredCurrencies = localCurrencyList;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterCurrencies);
  }

  void _filterCurrencies() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCurrencies = localCurrencyList.where((currency) {
        final nameLower = currency.name.toLowerCase();
        final codeLower = currency.code.toLowerCase();
        return nameLower.contains(query) || codeLower.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TTopSectionContainer(
        title: Container(
          height: 50,
          padding: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: Colors.grey),
              Expanded(
                  child: TextField(
                controller: _searchController,
                onChanged: (value) => _filterCurrencies(),
              )),
            ],
          ),
        ),
        child: Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFF00312F),
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            child: ListView.builder(
              itemCount: _filteredCurrencies.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(
                      bottom: 10), // Adds space below each tile
                  decoration: BoxDecoration(
                    color: const Color(0xFF001817),

                    borderRadius: BorderRadius.circular(
                        10), // Rounds the corners of the tile
                  ),
                  child: ListTile(
                    leading: Text(
                      _filteredCurrencies[index].flag,
                      style: const TextStyle(fontSize: 29),
                    ),
                    title: Text(
                      _filteredCurrencies[index].code,
                      style: const TextStyle(
                          color: Color(0xFFFAFFB5), fontSize: 20),
                    ),
                    onTap: () =>
                        Navigator.pop(context, _filteredCurrencies[index].code),
                  ),
                );
              },
            )),
      ),
    );
  }
}
