import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kukuo/models/currency_model.dart';

Future<String?> showCurrencyBottomSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => const CurrencyBottomSheet(),
  );
}

class CurrencyBottomSheet extends StatefulWidget {
  const CurrencyBottomSheet({super.key});

  @override
  State<CurrencyBottomSheet> createState() => _CurrencyBottomSheetState();
}

class _CurrencyBottomSheetState extends State<CurrencyBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Currency> _filteredCurrencies = localCurrencyList;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterCurrencies);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: Container(
        constraints: const BoxConstraints(
          maxHeight: 450,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF001817),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          children: [
            // Drag handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF008F8A),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Currency',
                    style: TextStyle(
                      fontFamily: 'Gazpacho',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD8FE00),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.close,
                      color: Color(0xFF008F8A),
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Iconsax.search_normal,
                        color: Color(0xFFD8FE00),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) => _filterCurrencies(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Search currency',
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    height: 2,
                    color: const Color(0xFF008F8A),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Currency list
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF00312F),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListView.builder(
                  itemCount: _filteredCurrencies.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF001817),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: Text(
                          _filteredCurrencies[index].flag,
                          style: const TextStyle(fontSize: 29),
                        ),
                        title: Text(
                          _filteredCurrencies[index].code,
                          style: const TextStyle(
                            color: Color(0xFFFAFFB5),
                            fontSize: 20,
                          ),
                        ),
                        onTap: () => Navigator.pop(
                          context,
                          _filteredCurrencies[index].code,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }
}
