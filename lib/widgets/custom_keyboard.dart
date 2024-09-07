import 'package:flutter/material.dart';
import 'package:expressions/expressions.dart' as expressions;

class CustomKeyboard extends StatefulWidget {
  final TextEditingController inputController;
  final VoidCallback onSubmit;

  const CustomKeyboard({
    super.key,
    required this.inputController,
    required this.onSubmit,
  });

  @override
  _CustomKeyboardState createState() => _CustomKeyboardState();
}

class _CustomKeyboardState extends State<CustomKeyboard> {
  String _expression = '';
  bool _showEquals = false;

  @override
  void initState() {
    super.initState();
    _expression = widget.inputController.text;
    _updateShowEquals();
  }

  void _onKeyTap(String key) {
    setState(() {
      if (_expression == '0') {
        _expression = key; // Replace 0 with the key
      } else {
        if (!_showEquals) {
          _expression += key;
        } else {
          _expression = widget.inputController.text + key;
        }
      }
      widget.inputController.text = _expression;
      _updateShowEquals();
    });
  }

  void _onClear() {
    setState(() {
      if (_expression.isNotEmpty) {
        _expression = _expression.substring(0, _expression.length - 1);
        if (_expression.isEmpty) {
          _expression = '0'; // Set to 0 if empty
        }
        widget.inputController.text = _expression;
      }
      _updateShowEquals();
    });
  }

  void _onReset() {
    setState(() {
      _expression = '0';
      widget.inputController.text = '0';
      _showEquals = false;
    });
  }

  void _onSubmit() {
    if (_showEquals) {
      try {
        final result = _evaluateExpression(_expression);
        widget.inputController.text = result.toString();
        _expression = result.toString(); // Update expression with result

        // Always reset to ">" after evaluation
        setState(() {
          _showEquals = false;
        });
      } catch (e) {
        print('Error evaluating expression: $e');
        widget.inputController.text = 'Error';
        _expression = '0';
        setState(() {
          _showEquals = false;
        });
      }
    } else {
      widget.onSubmit();
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
      print('Error in expression parsing or evaluation: $e');
      throw Exception('Invalid expression');
    }
  }

  void _updateShowEquals() {
    // Update _showEquals based on the presence of math symbols in the expression
    _showEquals = _containsMathSymbol(_expression);
  }

  bool _containsMathSymbol(String input) {
    return input.contains(RegExp(r'[+\-*/]'));
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      child: Container(
        padding: const EdgeInsets.all(8.0),
        child: GridView.count(
          crossAxisCount: 4,
          children: [
            _buildKey('C', _onReset, textColor: Colors.green),
            _buildKey('÷', () => _onKeyTap('/'), textColor: Colors.green),
            _buildKey('×', () => _onKeyTap('*'), textColor: Colors.green),
            _buildIconKey(Icons.backspace, _onClear, color: Colors.green),
            _buildKey('7', () => _onKeyTap('7')),
            _buildKey('8', () => _onKeyTap('8')),
            _buildKey('9', () => _onKeyTap('9')),
            _buildKey('-', () => _onKeyTap('-'), textColor: Colors.green),
            _buildKey('4', () => _onKeyTap('4')),
            _buildKey('5', () => _onKeyTap('5')),
            _buildKey('6', () => _onKeyTap('6')),
            _buildKey('+', () => _onKeyTap('+'), textColor: Colors.green),
            _buildKey('1', () => _onKeyTap('1')),
            _buildKey('2', () => _onKeyTap('2')),
            _buildKey('3', () => _onKeyTap('3')),
            _buildKey(_showEquals ? '=' : '>', _onSubmit,
                textColor: Colors.white,
                backgroundColor: _showEquals ? Colors.green : Colors.blue),
            _buildKey('0', () => _onKeyTap('0')),
            _buildKey('000', () => _onKeyTap('000')),
            _buildKey('.', () => _onKeyTap('.')),
          ],
        ),
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
          color: backgroundColor ?? Colors.grey[200],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 24,
            color: textColor ?? Colors.black,
          ),
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
          color: Colors.grey[200],
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
