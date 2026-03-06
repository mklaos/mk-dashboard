import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class HourlyChart extends StatelessWidget {
  final List<dynamic> hourlyData;

  const HourlyChart({super.key, required this.hourlyData});

  @override
  Widget build(BuildContext context) {
    if (hourlyData.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxSales() * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final hour = hourlyData[groupIndex]['hour'];
              final sales = hourlyData[groupIndex]['sales'];
              return BarTooltipItem(
                '${hour}:00\n${_formatCurrency(sales)}',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final hour = value.toInt();
                if (hour % 3 == 0) {
                  return Text('$hour', style: const TextStyle(fontSize: 9));
                }
                return const Text('');
              },
              reservedSize: 20,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  _formatCompact(value),
                  style: const TextStyle(fontSize: 9),
                );
              },
              reservedSize: 32,
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: _buildBarGroups(),
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 5000000,
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return hourlyData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final sales = (data['sales'] as num?)?.toDouble() ?? 0.0;

      return BarChartGroupData(
        x: data['hour'] ?? index,
        barRods: [
          BarChartRodData(
            toY: sales,
            color: _getColorForHour(data['hour'] ?? 0),
            width: 8,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(2),
              topRight: Radius.circular(2),
            ),
          ),
        ],
      );
    }).toList();
  }

  double _getMaxSales() {
    if (hourlyData.isEmpty) return 1000000;
    return hourlyData
        .map((e) => (e['sales'] as num?)?.toDouble() ?? 0.0)
        .reduce((a, b) => a > b ? a : b);
  }

  Color _getColorForHour(int hour) {
    if (hour >= 17 && hour <= 20) {
      return Colors.red; // Peak hours
    } else if (hour >= 11 && hour <= 14) {
      return Colors.orange; // Lunch hours
    }
    return Colors.blue;
  }

  String _formatCurrency(dynamic amount) {
    final value = (amount is num ? amount : 0).toDouble();
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M ₭';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K ₭';
    }
    return '$value ₭';
  }

  String _formatCompact(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(0)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }
}
