import 'package:flutter/material.dart';
import 'package:expressions/expressions.dart' as expressions;
import 'package:kukuo/utils/constants/colors.dart';

class CustomKeyboard extends StatefulWidget {
  final TextEditingController inputController;
  final VoidCallback onSubmit;

  const CustomKeyboard({
    super.key,
    required this.inputController,
    required this.onSubmit,
  });

  @override
  State<CustomKeyboard> createState() => _CustomKeyboardState();
}

class _CustomKeyboardState extends State<CustomKeyboard> {
  @override
  void initState() {
    super.initState();
  }

  void _onKeyTap(String key) {
    setState(() {
      if (widget.inputController.text == '0') {
        widget.inputController.text = key;
      } else {
        widget.inputController.text += key;
      }
    });
  }

  void _onClear() {
    setState(() {
      if (widget.inputController.text.isNotEmpty) {
        widget.inputController.text = widget.inputController.text
            .substring(0, widget.inputController.text.length - 1);
        if (widget.inputController.text.isEmpty) {
          widget.inputController.text = '0';
        }
      }
    });
  }

  void _onReset() {
    setState(() {
      widget.inputController.text = '0';
    });
  }

  void _onEquals() {
    try {
      final result = _evaluateExpression(widget.inputController.text);
      widget.inputController.text = result.toString(); // Display the result
    } catch (e) {
      // print('Error evaluating expression: $e');
      widget.inputController.text = 'Error';
    }
  }

  double _evaluateExpression(String expression) {
    try {
      final parsedExpression = expressions.Expression.parse(expression);
      const evaluator = expressions.ExpressionEvaluator();
      final result = evaluator.eval(parsedExpression, {});

      if (result is num) {
        return result.toDouble();
      } else {
        throw Exception('Invalid result type');
      }
    } catch (e) {
      // print('Error in expression parsing or evaluation: $e');
      throw Exception('Invalid expression');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(4.0),
        children: [
          _buildSymbol('C', _onReset),
          _buildSymbol('-', () => _onKeyTap('-')),
          _buildSymbol('+', () => _onKeyTap('+')),
          _buildIconKey(Icons.backspace, _onClear,
              color: TColors.primaryBGColor),
          _buildKey('7', () => _onKeyTap('7')),
          _buildKey('8', () => _onKeyTap('8')),
          _buildKey('9', () => _onKeyTap('9')),
          _buildSymbol('×', () => _onKeyTap('*')),
          _buildKey('4', () => _onKeyTap('4')),
          _buildKey('5', () => _onKeyTap('5')),
          _buildKey('6', () => _onKeyTap('6')),
          _buildSymbol('÷', () => _onKeyTap('/')),
          _buildKey('1', () => _onKeyTap('1')),
          _buildKey('2', () => _onKeyTap('2')),
          _buildKey('3', () => _onKeyTap('3')),
          _buildSymbol('=', _onEquals),
          _buildKey('0', () => _onKeyTap('0')),
          _buildKey('00', () => _onKeyTap('00')),
          _buildKey('000', () => _onKeyTap('000')),
          _buildKey('.', () => _onKeyTap('.')),
        ],
      ),
    );
  }

  Widget _buildKey(String label, VoidCallback onTap,
      {Color? textColor, Color? backgroundColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(4.0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor ?? const Color(0xFF00312F),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 30,
            color: textColor ?? const Color(0xFF008F8A),
          ),
        ),
      ),
    );
  }

  Widget _buildSymbol(String symbol, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(4.0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF008F8A),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(
          symbol,
          style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Color(0xFF001817)),
        ),
      ),
    );
  }

  Widget _buildIconKey(IconData icon, VoidCallback onTap, {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(4.0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF008F8A),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Icon(
          icon,
          size: 24,
          color: color ?? Colors.black,
        ),
      ),
    );
  }
}
