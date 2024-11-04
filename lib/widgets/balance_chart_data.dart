import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:kukuo/models/balance_data.dart';

class BalanceChart extends StatelessWidget {
  final List<BalanceData> data;

  const BalanceChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: data
                .map((e) => FlSpot(
                      e.date.difference(data[0].date).inDays.toDouble(),
                      e.balance,
                    ))
                .toList(),
            isCurved: false,
            color: const Color(0xFFD8FE00),
            barWidth: 2.16,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }
}
