// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:provider/provider.dart';
// import 'package:shika_app/screens/currency_screen.dart';
// import 'package:shika_app/models/currency_model.dart';
// import 'package:shika_app/providers/user_input_provider.dart';
// import 'package:math_expressions/math_expressions.dart'; // For evaluating mathematical expressions

// class CurrencyInputModal extends StatefulWidget {
//   const CurrencyInputModal({Key? key}) : super(key: key);

//   @override
//   _CurrencyInputModalState createState() => _CurrencyInputModalState();
// }

// class _CurrencyInputModalState extends State<CurrencyInputModal> {
//   String _selectedCurrency = 'USD'; // Default currency
//   final TextEditingController _amountController = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Row(
//             children: [
//               Expanded(
//                 child: GestureDetector(
//                   onTap: () async {
//                     final selectedCurrency = await Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => CurrencyScreen(),
//                       ),
//                     );

//                     if (selectedCurrency != null) {
//                       setState(() {
//                         _selectedCurrency = selectedCurrency;
//                       });
//                     }
//                   },
//                   child: Container(
//                     padding: const EdgeInsets.all(8.0),
//                     decoration: BoxDecoration(
//                       border: Border.all(color: Colors.grey),
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                     child: Text(_selectedCurrency),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 flex: 6,
//                 child: TextField(
//                   controller: _amountController,
//                   keyboardType:
//                       TextInputType.text, // Switch to text-based keyboard
//                   decoration: const InputDecoration(labelText: 'Amount'),
//                   inputFormatters: [
//                     FilteringTextInputFormatter.allow(
//                       RegExp(
//                           r'[0-9+\-*/.]'), // Allow numbers, +, -, *, /, and .
//                     ),
//                   ],
//                 ),
//               )
//             ],
//           ),
//           const SizedBox(height: 20),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               padding: const EdgeInsets.symmetric(vertical: 16.0),
//               backgroundColor: Colors.amber,
//               minimumSize: const Size(
//                   double.infinity, 50), // Make the button take the full width
//             ),
//             onPressed: () {
//               final String input = _amountController.text;
//               try {
//                 // Parse and evaluate the mathematical expression
//                 Parser p = Parser();
//                 Expression exp = p.parse(input);
//                 double amount =
//                     exp.evaluate(EvaluationType.REAL, ContextModel());

//                 if (amount > 0) {
//                   final currency =
//                       Currency(code: _selectedCurrency, amount: amount);
//                   Provider.of<UserInputProvider>(context, listen: false)
//                       .addCurrency(currency);
//                   Navigator.pop(context);
//                 }
//               } catch (e) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(content: Text('Invalid expression')),
//                 );
//               }
//             },
//             child: const Text('Save'),
//           ),
//         ],
//       ),
//     );
//   }
// }
