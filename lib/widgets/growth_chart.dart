import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:kukuo/providers/exchange_rate_provider.dart';
import 'package:kukuo/common/section_heading.dart';
import 'dart:math';
import 'package:kukuo/models/currency_model.dart';

enum TimeInterval {
  oneDay('1D', 1),
  oneWeek('1W', 7),
  oneMonth('1M', 30),
  sixMonths('6M', 180),
  oneYear('1Y', 365);

  const TimeInterval(this.label, this.days);
  final String label;
  final int days;
}

class GrowthChart extends StatefulWidget {
  final String selectedLocalCurrency;

  const GrowthChart({
    super.key,
    required this.selectedLocalCurrency,
  });

  @override
  State<GrowthChart> createState() => _GrowthChartState();
}

class _GrowthChartState extends State<GrowthChart> {
  TimeInterval _selectedInterval = TimeInterval.oneMonth;
  static const double _chartHeight = 400.0;
  static const double _maxReasonableGrowthPercentage = 1000.0;

  @override
  Widget build(BuildContext context) {
    return Consumer<ExchangeRateProvider>(
      builder: (context, exchangeRateProvider, child) {
        return Container(
          height: _chartHeight,
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: Color(0xFF00312F),
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          child: _buildChartContent(exchangeRateProvider),
        );
      },
    );
  }

  Widget _buildChartContent(ExchangeRateProvider provider) {
    final growthData = _calculateGrowthPercentage(provider, _selectedInterval);
    final chartData = _prepareChartData(provider);

    if (!chartData.isValid) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(growthData, _selectedInterval.label),
        if (chartData.isValid) _buildChartView(chartData, provider),
      ],
    );
  }

  Widget _buildHeader(
      ({bool showPercentage, double percentage}) growthData, String dateRange) {
    final bool showPercentage = growthData.showPercentage;
    final double percentage = growthData.percentage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TSectionHeading(
          title: 'Growth %',
          showActionButton: true,
          buttonTitle: dateRange,
          onPressed: _showIntervalSelectionModal,
        ),
        if (showPercentage) ...[
          Row(
            children: [
              Text(
                '${percentage.toStringAsFixed(2)}%',
                style: const TextStyle(
                  fontSize: 25,
                  color: Color(0xFFFAFFB5),
                ),
              ),
              Icon(
                percentage >= 0 ? Iconsax.arrow_up_3 : Iconsax.arrow_down,
                color: percentage >= 0 ? Colors.green : Colors.red,
              )
            ],
          ),
        ] else ...[
          const Text(
            'First Entry',
            style: TextStyle(
              fontSize: 20,
              color: Color(0xFFFAFFB5),
            ),
          ),
        ],
        const SizedBox(height: 10),
      ],
    );
  }

  String _formatNumber(double value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(0)}B';
    } else if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(0)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}k';
    } else {
      return value.toStringAsFixed(0);
    }
  }

  Widget _buildChartView(
      ({
        bool isValid,
        double highest,
        double lowest,
        double interval
      }) chartData,
      ExchangeRateProvider provider) {
    final double startTime =
        provider.timeHistory.first.millisecondsSinceEpoch.toDouble();
    final exchangeRate =
        provider.exchangeRates[widget.selectedLocalCurrency] ?? 1.0;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              horizontalInterval: chartData.interval,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.white.withOpacity(0.1),
                  strokeWidth: 0.5,
                );
              },
            ),
            titlesData: FlTitlesData(
              rightTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: chartData.interval,
                  getTitlesWidget: (value, meta) {
                    if (value == chartData.highest + chartData.interval) {
                      return const SizedBox.shrink();
                    }
                    final currencySymbol =
                        Currency.getSymbolForCode(widget.selectedLocalCurrency);

                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        '$currencySymbol${_formatNumber(value)}',
                        style: const TextStyle(
                          color: Color(0xFF008F8A),
                          fontSize: 8,
                        ),
                      ),
                    );
                  },
                  reservedSize: 30,
                ),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            minY: chartData.lowest > 0 ? 0 : chartData.lowest,
            maxY: chartData.highest,
            backgroundColor: Colors.transparent,
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(
                  provider.balanceHistory.length,
                  (index) {
                    double xValue =
                        (provider.timeHistory[index].millisecondsSinceEpoch -
                                startTime) /
                            (1000 * 60 * 60 * 24);
                    double yValue =
                        provider.balanceHistory[index] * exchangeRate;
                    return FlSpot(xValue, yValue);
                  },
                ),
                isCurved: false,
                color: _calculateGrowthPercentage(provider, _selectedInterval)
                            .percentage >=
                        0
                    ? const Color(0xFFD8FE00)
                    : const Color(0xFFFF5E00),
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      _calculateGrowthPercentage(provider, _selectedInterval)
                                  .percentage >=
                              0
                          ? const Color(0xFFD8FE00).withOpacity(0.2)
                          : const Color(0xFFFF5E00).withOpacity(0.2),
                      _calculateGrowthPercentage(provider, _selectedInterval)
                                  .percentage >=
                              0
                          ? const Color(0xFFD8FE00).withOpacity(0.0)
                          : const Color(0xFFFF5E00).withOpacity(0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                tooltipRoundedRadius: 8,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((LineBarSpot touchedSpot) {
                    final currencySymbol =
                        Currency.getSymbolForCode(widget.selectedLocalCurrency);

                    return LineTooltipItem(
                      '$currencySymbol${_formatNumber(touchedSpot.y)}',
                      const TextStyle(
                        color: Color(0xFFD8FE00),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  ({bool showPercentage, double percentage}) _calculateGrowthPercentage(
      ExchangeRateProvider exchangeRateProvider, TimeInterval interval) {
    if (exchangeRateProvider.balanceHistory.length < 2) {
      return (showPercentage: false, percentage: 0.0);
    }

    final exchangeRate =
        exchangeRateProvider.exchangeRates[widget.selectedLocalCurrency] ?? 1.0;

    // Find the comparison point based on the selected interval
    final DateTime targetDate =
        DateTime.now().subtract(Duration(days: interval.days));

    // Get the latest value (most recent)
    double latest = exchangeRateProvider.balanceHistory.last * exchangeRate;

    // Find the closest historical value to the target date
    double previous = 0.0;
    int closestIndex = -1;
    Duration smallestDiff = const Duration(days: 999999);

    for (int i = 0; i < exchangeRateProvider.timeHistory.length; i++) {
      final timeDiff =
          exchangeRateProvider.timeHistory[i].difference(targetDate).abs();
      if (timeDiff < smallestDiff) {
        smallestDiff = timeDiff;
        closestIndex = i;
      }
    }

    if (closestIndex == -1 ||
        closestIndex == exchangeRateProvider.balanceHistory.length - 1) {
      // If we can't find a good comparison point or it's the same as latest, fall back to previous method
      if (exchangeRateProvider.balanceHistory.length < 2) {
        return (showPercentage: false, percentage: 0.0);
      }
      previous = exchangeRateProvider
              .balanceHistory[exchangeRateProvider.balanceHistory.length - 2] *
          exchangeRate;
    } else {
      previous =
          exchangeRateProvider.balanceHistory[closestIndex] * exchangeRate;
    }

    if (previous == 0 || previous.abs() < 0.000001) {
      return (showPercentage: false, percentage: 0.0);
    }

    double percentage = ((latest - previous) / previous) * 100;

    if (percentage.abs() > _maxReasonableGrowthPercentage) {
      return (showPercentage: false, percentage: 0.0);
    }

    return (showPercentage: true, percentage: percentage);
  }

  ({bool isValid, double highest, double lowest, double interval})
      _prepareChartData(ExchangeRateProvider provider) {
    // Check for minimum required data points
    if (provider.balanceHistory.isEmpty || provider.timeHistory.isEmpty) {
      return (isValid: false, highest: 0, lowest: 0, interval: 0);
    }

    final exchangeRate =
        provider.exchangeRates[widget.selectedLocalCurrency] ?? 1.0;
    final convertedHistory =
        provider.balanceHistory.map((amount) => amount * exchangeRate).toList();

    if (convertedHistory.isEmpty) {
      return (isValid: false, highest: 0, lowest: 0, interval: 0);
    }

    final highest = convertedHistory.reduce(max);
    final lowest = convertedHistory.reduce(min);
    final interval =
        (highest <= lowest || highest == 0) ? 1.0 : (highest - lowest) / 4;

    return (
      isValid: true,
      highest: highest,
      lowest: lowest,
      interval: interval
    );
  }

  void _showIntervalSelectionModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF00312F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Time Interval',
                style: TextStyle(
                  color: Color(0xFFFAFFB5),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ...TimeInterval.values.map((interval) {
                return ListTile(
                  title: Text(
                    interval.label,
                    style: TextStyle(
                      color: _selectedInterval == interval
                          ? const Color(0xFFD8FE00)
                          : const Color(0xFF008F8A),
                      fontWeight: _selectedInterval == interval
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: _selectedInterval == interval
                      ? const Icon(
                          Icons.check,
                          color: Color(0xFFD8FE00),
                        )
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedInterval = interval;
                    });
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
