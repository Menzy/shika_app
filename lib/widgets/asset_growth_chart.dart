import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:iconsax/iconsax.dart';

class AssetGrowthChart extends StatelessWidget {
  final String currencyCode;
  final List<double> amounts;
  final List<DateTime> timestamps;

  const AssetGrowthChart({
    super.key,
    required this.currencyCode,
    required this.amounts,
    required this.timestamps,
  });

  @override
  Widget build(BuildContext context) {
    if (amounts.isEmpty || timestamps.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    double growthPercentage = _calculateGrowthPercentage();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${growthPercentage.toStringAsFixed(2)}%',
              style: const TextStyle(
                fontSize: 20,
                color: Color(0xFFFAFFB5),
              ),
            ),
            Icon(
              growthPercentage >= 0 ? Iconsax.arrow_up : Iconsax.arrow_down,
              color: growthPercentage >= 0 ? Colors.green : Colors.red,
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: _createSpots(),
                  isCurved: false,
                  color: growthPercentage >= 0
                      ? const Color(0xFFD8FE00)
                      : const Color(0xFFFF5E00),
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: (growthPercentage >= 0
                            ? const Color(0xFFD8FE00)
                            : const Color(0xFFFF5E00))
                        .withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  double _calculateGrowthPercentage() {
    if (amounts.length < 2) return 0;
    double firstValue = amounts.first;
    double lastValue = amounts.last;
    return ((lastValue - firstValue) / firstValue) * 100;
  }

  List<FlSpot> _createSpots() {
    if (timestamps.isEmpty) return [];

    final firstTimestamp = timestamps.first.millisecondsSinceEpoch.toDouble();
    final maxAmount = amounts.reduce((max, value) => max > value ? max : value);

    return List.generate(timestamps.length, (index) {
      final x = (timestamps[index].millisecondsSinceEpoch - firstTimestamp) /
          (24 * 60 * 60 * 1000); // Convert to days
      final y = amounts[index] / maxAmount; // Normalize values between 0 and 1
      return FlSpot(x, y);
    });
  }
}
