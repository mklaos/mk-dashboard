import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SalesChart extends StatelessWidget {
  final List<dynamic> data;
  final String chartType; // 'comparison' or 'trend'

  const SalesChart({
    super.key,
    required this.data,
    this.chartType = 'comparison',
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 200,
            child: Center(
              child: Text(
                'No data available for chart',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              chartType == 'comparison'
                  ? 'Sales Comparison by Branch'
                  : 'Hourly Sales Trend',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: chartType == 'comparison'
                  ? _buildComparisonChart(context)
                  : _buildTrendChart(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonChart(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxValue() * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final branchName = _getBranchName(group.x.toInt());
              return BarTooltipItem(
                '$branchName\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: _formatCurrency(rod.toY),
                    style: const TextStyle(
                      color: Colors.yellow,
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _getBranchName(value.toInt()),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const Text('');
                return Text(
                  _formatShortCurrency(value),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _getMaxValue() / 4,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
        ),
        barGroups: _buildBarGroups(context),
      ),
    );
  }

  Widget _buildTrendChart(BuildContext context) {
    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(enabled: true),
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: _buildLineSpots(),
            isCurved: true,
            barWidth: 3,
            color: Theme.of(context).primaryColor,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).primaryColor.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(BuildContext context) {
    final List<Color> branchColors = [
      const Color(0xFFE53935), // Red (MK)
      const Color(0xFFFB8C00), // Orange
      const Color(0xFF1E88E5), // Blue
      const Color(0xFF43A047), // Green
    ];

    return List.generate(
      data.length,
      (index) {
        final item = data[index];
        final sales = (item['net_sales'] ?? 0).toDouble();

        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: sales,
              color: branchColors[index % branchColors.length],
              width: 24,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: _getMaxValue() * 1.2,
                color: Colors.grey.withOpacity(0.05),
              ),
            ),
          ],
        );
      },
    );
  }

  List<FlSpot> _buildLineSpots() {
    return data
        .map<FlSpot>((item) => FlSpot(
              (item['hour'] ?? 0).toDouble(),
              (item['sales'] ?? 0).toDouble(),
            ))
        .toList();
  }

  String _getBranchName(int index) {
    if (data.isEmpty) return '';
    if (index >= 0 && index < data.length) {
      final item = data[index];
      return item['branch_code'] ?? 'Br ${index + 1}';
    }
    return '';
  }

  double _getMaxValue() {
    if (data.isEmpty) return 1000;
    double max = 0;
    for (final item in data) {
      double value = 0;
      if (chartType == 'comparison') {
        value = (item['net_sales'] ?? 0).toDouble();
      } else {
        value = (item['sales'] ?? 0).toDouble();
      }
      if (value > max) max = value;
    }
    return max > 0 ? max : 1000;
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }

  String _formatShortCurrency(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(0)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }
}
