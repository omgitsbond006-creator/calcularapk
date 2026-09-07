import 'package:flutter/material.dart';

void main() {
  runApp(const CalcularApp());
}

class CalcularApp extends StatelessWidget {
  const CalcularApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calcular',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFFFF9500),
        useMaterial3: true,
      ),
      home: const CalculatorScreen(),
    );
  }
}

enum _ButtonType { number, operatorBtn, function, equals }

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _display = '0';
  String _expression = '';
  double? _firstOperand;
  String? _operator;
  bool _shouldResetDisplay = false;
  bool _hasError = false;

  void _inputDigit(String digit) {
    setState(() {
      if (_hasError) {
        _display = digit;
        _hasError = false;
        _shouldResetDisplay = false;
        return;
      }
      if (_shouldResetDisplay || _display == '0') {
        _display = digit;
        _shouldResetDisplay = false;
      } else {
        _display += digit;
      }
    });
  }

  void _inputDecimal() {
    setState(() {
      if (_hasError) {
        _display = '0.';
        _hasError = false;
        _shouldResetDisplay = false;
        return;
      }
      if (_shouldResetDisplay) {
        _display = '0.';
        _shouldResetDisplay = false;
        return;
      }
      if (!_display.contains('.')) {
        _display += '.';
      }
    });
  }

  void _inputOperator(String op) {
    setState(() {
      if (_hasError) return;
      final current = double.tryParse(_display) ?? 0;
      if (_operator != null && !_shouldResetDisplay) {
        final result = _calculate(_firstOperand!, current, _operator!);
        if (result == null) {
          _display = 'Error';
          _hasError = true;
          _firstOperand = null;
          _operator = null;
          _expression = '';
          _shouldResetDisplay = true;
          return;
        }
        _firstOperand = result;
        _display = _formatNumber(result);
      } else {
        _firstOperand = current;
      }
      _operator = op;
      _expression = '${_formatNumber(_firstOperand!)} $op';
      _shouldResetDisplay = true;
    });
  }

  void _calculateResult() {
    setState(() {
      if (_hasError || _operator == null || _firstOperand == null) return;
      final current = double.tryParse(_display) ?? 0;
      final result = _calculate(_firstOperand!, current, _operator!);
      if (result == null) {
        _display = 'Error';
        _hasError = true;
        _expression = '';
        _firstOperand = null;
        _operator = null;
        _shouldResetDisplay = true;
        return;
      }
      _expression =
          '${_formatNumber(_firstOperand!)} $_operator ${_formatNumber(current)} =';
      _display = _formatNumber(result);
      _firstOperand = null;
      _operator = null;
      _shouldResetDisplay = true;
    });
  }

  double? _calculate(double a, double b, String op) {
    switch (op) {
      case '+':
        return a + b;
      case '−':
        return a - b;
      case '×':
        return a * b;
      case '÷':
        if (b == 0) return null;
        return a / b;
      default:
        return null;
    }
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble() && value.abs() < 1e15) {
      return value.toInt().toString();
    }
    String s = value.toString();
    if (s.contains('.') && s.length > 12) {
      s = value.toStringAsFixed(6);
      while (s.endsWith('0')) {
        s = s.substring(0, s.length - 1);
      }
      if (s.endsWith('.')) {
        s = s.substring(0, s.length - 1);
      }
    }
    return s;
  }

  void _clear() {
    setState(() {
      _display = '0';
      _expression = '';
      _firstOperand = null;
      _operator = null;
      _shouldResetDisplay = false;
      _hasError = false;
    });
  }

  void _delete() {
    setState(() {
      if (_hasError) {
        _clear();
        return;
      }
      if (_shouldResetDisplay) return;
      if (_display.length <= 1) {
        _display = '0';
      } else {
        _display = _display.substring(0, _display.length - 1);
        if (_display == '-' || _display.isEmpty) {
          _display = '0';
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calcular'),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                alignment: Alignment.bottomRight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _expression,
                      style: const TextStyle(
                        fontSize: 22,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _display,
                      style: TextStyle(
                        fontSize: _display.length > 8 ? 40 : 56,
                        fontWeight: FontWeight.w300,
                        color: _hasError ? Colors.redAccent : Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: GridView.count(
                  crossAxisCount: 4,
                  childAspectRatio: 1,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  children: [
                    _buildButton('C', _clear, type: _ButtonType.function),
                    _buildButton('⌫', _delete, type: _ButtonType.function),
                    _buildButton('÷', () => _inputOperator('÷'),
                        type: _ButtonType.operatorBtn),
                    _buildButton('×', () => _inputOperator('×'),
                        type: _ButtonType.operatorBtn),
                    _buildButton('7', () => _inputDigit('7')),
                    _buildButton('8', () => _inputDigit('8')),
                    _buildButton('9', () => _inputDigit('9')),
                    _buildButton('−', () => _inputOperator('−'),
                        type: _ButtonType.operatorBtn),
                    _buildButton('4', () => _inputDigit('4')),
                    _buildButton('5', () => _inputDigit('5')),
                    _buildButton('6', () => _inputDigit('6')),
                    _buildButton('+', () => _inputOperator('+'),
                        type: _ButtonType.operatorBtn),
                    _buildButton('1', () => _inputDigit('1')),
                    _buildButton('2', () => _inputDigit('2')),
                    _buildButton('3', () => _inputDigit('3')),
                    _buildButton('=', _calculateResult,
                        type: _ButtonType.equals),
                    _buildButton('0', () => _inputDigit('0')),
                    _buildButton('.', _inputDecimal),
                    const SizedBox(),
                    const SizedBox(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String label, VoidCallback onPressed,
      {_ButtonType type = _ButtonType.number}) {
    Color bgColor;
    Color fgColor;
    switch (type) {
      case _ButtonType.function:
        bgColor = const Color(0xFF3A3A3C);
        fgColor = Colors.orangeAccent;
        break;
      case _ButtonType.operatorBtn:
        bgColor = const Color(0xFF2C2C2E);
        fgColor = Colors.orangeAccent;
        break;
      case _ButtonType.equals:
        bgColor = const Color(0xFFFF9500);
        fgColor = Colors.white;
        break;
      case _ButtonType.number:
        bgColor = const Color(0xFF2C2C2E);
        fgColor = Colors.white;
        break;
    }
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w500,
              color: fgColor,
            ),
          ),
        ),
      ),
    );
  }
}
