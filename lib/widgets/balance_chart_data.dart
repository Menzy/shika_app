import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:kukuo/models/balance_data.dart';

class BalanceChart extends StatelessWidget {
  final List<BalanceData> data;

  const BalanceChart({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
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
            color: Color(0xFFD8FE00),
            barWidth: 2.16,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }
}
