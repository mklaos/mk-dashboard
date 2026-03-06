import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SalesMixPieChart extends StatelessWidget {
  final List<Map<String, dynamic>> salesMixData;

  const SalesMixPieChart({
    super.key,
    required this.salesMixData,
  });

  @override
  Widget build(BuildContext context) {
    if (salesMixData.isEmpty) {
      return const Center(
        child: Text(
          'No sales mix data available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Filter out categories with zero amount
    final validData = salesMixData
        .where((item) => (item['amount'] as num) > 0)
        .toList();

    if (validData.isEmpty) {
      return const Center(
        child: Text(
          'No sales data for this period',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: _generateSections(context),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              startDegreeOffset: -90,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildLegend(context, validData),
        ),
      ],
    );
  }

  List<PieChartSectionData> _generateSections(BuildContext context) {
    final colors = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).colorScheme.tertiary,
      Colors.orange,
      Colors.purple,
    ];

    return validData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final amount = data['amount'] as double;
      final percentage = data['percentage'] as double;
      final category = _getCategoryName(data, context);

      return PieChartSectionData(
        value: amount,
        title: '${percentage.toStringAsFixed(1)}%',
        color: colors[index % colors.length],
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegend(BuildContext context, List<Map<String, dynamic>> data) {
    final colors = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).colorScheme.tertiary,
      Colors.orange,
      Colors.purple,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: data.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final category = _getCategoryName(item, context);
        final amount = item['amount'] as double;
        final percentage = item['percentage'] as double;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: colors[index % colors.length],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatCurrency(amount),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getCategoryName(Map<String, dynamic> data, BuildContext context) {
    // Try to get localized name based on app locale
    // For now, use English as default
    return data['category'] ?? 'Unknown';
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M ₭';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K ₭';
    }
    return '${amount.toStringAsFixed(0)} ₭';
  }

  List<Map<String, dynamic>> get validData => salesMixData
      .where((item) => (item['amount'] as num) > 0)
      .toList();
}
