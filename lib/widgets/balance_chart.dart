import 'package:flutter/material.dart';
import 'dart:math' as math;

enum ChartTimeFilter { today, week, month, year, all }

class BalanceChart extends StatefulWidget {
  final List<double> balanceHistory;
  final List<double> investedHistory;
  final List<DateTime> timeHistory;
  final String currencySymbol;

  const BalanceChart({
    super.key,
    required this.balanceHistory,
    required this.investedHistory,
    required this.timeHistory,
    required this.currencySymbol,
  });

  @override
  State<BalanceChart> createState() => _BalanceChartState();
}

class _BalanceChartState extends State<BalanceChart> {
  ChartTimeFilter _selectedFilter = ChartTimeFilter.month;

  @override
  Widget build(BuildContext context) {
    if (widget.balanceHistory.isEmpty || widget.timeHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    final filteredData = _getFilteredData();

    if (filteredData.balances.isEmpty) {
      return const SizedBox.shrink();
    }

    final growthPercentage = _calculateGrowthPercentage(filteredData);
    final isPositive = growthPercentage >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF00312F),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with growth percentage and filter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Portfolio Growth',
                    style: TextStyle(
                      color: Color(0xFFFAFFB5),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${growthPercentage >= 0 ? '+' : ''}${growthPercentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 24,
                          color: Color(0xFFFAFFB5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        color:
                            isPositive ? Colors.green : const Color(0xFFFF6B47),
                        size: 24,
                      ),
                    ],
                  ),
                ],
              ),
              _buildFilterDropdown(),
            ],
          ),

          const SizedBox(height: 20),

          // Chart
          SizedBox(
            height: 180,
            child: CustomPaint(
              size: const Size(double.infinity, 180),
              painter: ChartPainter(
                balances: filteredData.balances,
                times: filteredData.times,
                isPositive: isPositive,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return GestureDetector(
      onTap: () {
        _showFilterBottomSheet(context);
      },
      child: Text(
        _getFilterLabel(_selectedFilter),
        style: const TextStyle(
          color: Color(0xFFD8FE00),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF001817),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              _buildBottomSheetItem('1D', ChartTimeFilter.today),
              _buildBottomSheetItem('1W', ChartTimeFilter.week),
              _buildBottomSheetItem('1M', ChartTimeFilter.month),
              _buildBottomSheetItem('1Y', ChartTimeFilter.year),
              _buildBottomSheetItem('All', ChartTimeFilter.all),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetItem(String label, ChartTimeFilter filter) {
    final isSelected = _selectedFilter == filter;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFFD8FE00)
                    : const Color(0xFFFAFFB5),
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check,
                color: Color(0xFFD8FE00),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  String _getFilterLabel(ChartTimeFilter filter) {
    switch (filter) {
      case ChartTimeFilter.today:
        return '1D';
      case ChartTimeFilter.week:
        return '1W';
      case ChartTimeFilter.month:
        return '1M';
      case ChartTimeFilter.year:
        return '1Y';
      case ChartTimeFilter.all:
        return 'All';
    }
  }

  ({List<double> balances, List<double> invested, List<DateTime> times})
      _getFilteredData() {
    final now = DateTime.now();
    DateTime cutoffDate;

    switch (_selectedFilter) {
      case ChartTimeFilter.today:
        cutoffDate = DateTime(now.year, now.month, now.day);
        break;
      case ChartTimeFilter.week:
        cutoffDate = now.subtract(const Duration(days: 7));
        break;
      case ChartTimeFilter.month:
        cutoffDate = now.subtract(const Duration(days: 30));
        break;
      case ChartTimeFilter.year:
        cutoffDate = now.subtract(const Duration(days: 365));
        break;
      case ChartTimeFilter.all:
        cutoffDate = DateTime(1970);
        break;
    }

    final filteredBalances = <double>[];
    final filteredInvested = <double>[];
    final filteredTimes = <DateTime>[];

    for (int i = 0; i < widget.timeHistory.length; i++) {
      if (widget.timeHistory[i].isAfter(cutoffDate) ||
          widget.timeHistory[i].isAtSameMomentAs(cutoffDate)) {
        filteredBalances.add(widget.balanceHistory[i]);
        if (i < widget.investedHistory.length) {
          filteredInvested.add(widget.investedHistory[i]);
        } else {
          filteredInvested.add(0); // Fallback
        }
        filteredTimes.add(widget.timeHistory[i]);
      }
    }

    // If no data in the filtered range but we have data, include at least the first and last
    if (filteredBalances.isEmpty && widget.balanceHistory.isNotEmpty) {
      // Add the closest point before the cutoff date
      for (int i = widget.timeHistory.length - 1; i >= 0; i--) {
        if (widget.timeHistory[i].isBefore(cutoffDate)) {
          filteredBalances.insert(0, widget.balanceHistory[i]);
          if (i < widget.investedHistory.length) {
            filteredInvested.insert(0, widget.investedHistory[i]);
          } else {
            filteredInvested.insert(0, 0);
          }
          filteredTimes.insert(0, widget.timeHistory[i]);
          break;
        }
      }
      // Add the last point
      if (filteredBalances.isEmpty) {
        filteredBalances.add(widget.balanceHistory.last);
        if (widget.investedHistory.isNotEmpty) {
          filteredInvested.add(widget.investedHistory.last);
        } else {
          filteredInvested.add(0);
        }
        filteredTimes.add(widget.timeHistory.last);
      }
    }

    return (
      balances: filteredBalances,
      invested: filteredInvested,
      times: filteredTimes
    );
  }

  double _calculateGrowthPercentage(
      ({
        List<double> balances,
        List<double> invested,
        List<DateTime> times
      }) data) {
    if (data.balances.isEmpty) return 0;

    // If only one data point, no growth
    if (data.balances.length == 1) {
      return 0;
    }

    final startBalance = data.balances.first;
    final endBalance = data.balances.last;

    final startInvested = data.invested.isNotEmpty ? data.invested.first : 0.0;
    final endInvested = data.invested.isNotEmpty ? data.invested.last : 0.0;

    // Calculate Net Invested Capital (NIC) change during the period
    final netInvestedChange = endInvested - startInvested;

    // Calculate Profit/Loss
    // Profit = (EndBalance - StartBalance) - NetInvestedChange
    final profit = (endBalance - startBalance) - netInvestedChange;

    // Calculate Basis for percentage
    // Basis = StartBalance + NetInvestedChange
    // This is a simplified Modified Dietz approach where we assume flows happen at start
    // For more accuracy we would time-weight, but this is sufficient for "not 15000%"
    final basis = startBalance + netInvestedChange;

    if (basis.abs() < 0.01) return 0;

    return (profit / basis) * 100;
  }
}

class ChartPainter extends CustomPainter {
  final List<double> balances;
  final List<DateTime> times;
  final bool isPositive;

  ChartPainter({
    required this.balances,
    required this.times,
    required this.isPositive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (balances.isEmpty || times.isEmpty) return;

    // Find min and max values
    final minValue = balances.reduce(math.min);
    final maxValue = balances.reduce(math.max);
    final range = maxValue - minValue;

    // Add padding to the range
    final paddedMin = minValue - (range * 0.1);
    final paddedMax = maxValue + (range * 0.1);
    final paddedRange = paddedMax - paddedMin;

    // Create path for the line
    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < balances.length; i++) {
      final double x;
      if (balances.length > 1) {
        x = (i / (balances.length - 1)) * size.width;
      } else {
        x = size.width / 2; // Center the single point
      }

      final normalizedValue =
          paddedRange == 0 ? 0.5 : (balances[i] - paddedMin) / paddedRange;
      final y = size.height - (normalizedValue * size.height);

      points.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Draw gradient fill
    final gradientPath = Path.from(path);
    gradientPath.lineTo(size.width, size.height);
    gradientPath.lineTo(0, size.height);
    gradientPath.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        (isPositive ? Colors.green : const Color(0xFFFF6B47))
            .withValues(alpha: 0.3),
        (isPositive ? Colors.green : const Color(0xFFFF6B47))
            .withValues(alpha: 0.0),
      ],
    );

    final gradientPaint = Paint()
      ..shader =
          gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(gradientPath, gradientPaint);

    // Draw the line
    final linePaint = Paint()
      ..color = isPositive ? Colors.green : const Color(0xFFFF6B47)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);

    // Draw points
    for (final point in points) {
      final pointPaint = Paint()
        ..color = isPositive ? Colors.green : const Color(0xFFFF6B47)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(point, 3, pointPaint);

      // White center
      final centerPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(point, 1.5, centerPaint);
    }
  }

  @override
  bool shouldRepaint(ChartPainter oldDelegate) {
    return oldDelegate.balances != balances ||
        oldDelegate.times != times ||
        oldDelegate.isPositive != isPositive;
  }
}
