import 'package:flutter/material.dart';

class KPIComparisonCard extends StatelessWidget {
  final List<Map<String, dynamic>> branchData;

  const KPIComparisonCard({
    super.key,
    required this.branchData,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Branch Comparison',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: branchData.map((data) {
                final branchCode = data['branch_code'] as String;
                final sales = (data['net_sales'] as num?)?.toDouble() ?? 0;
                final receipts = (data['receipt_count'] as int?) ?? 0;
                final customers = (data['customer_count'] as int?) ?? 0;
                final voidAmount = (data['void_amount'] as num?)?.toDouble() ?? 0;
                
                final avgTicket = receipts > 0 ? sales / receipts : 0;
                final voidRate = (sales + voidAmount) > 0 
                    ? (voidAmount / (sales + voidAmount)) * 100 
                    : 0.0;

                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          branchCode,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        _KPIItem(
                          label: 'Sales',
                          value: _formatCurrency(sales),
                        ),
                        const SizedBox(height: 4),
                        _KPIItem(
                          label: 'Receipts',
                          value: '$receipts',
                        ),
                        const SizedBox(height: 4),
                        _KPIItem(
                          label: 'Customers',
                          value: '$customers',
                        ),
                        const SizedBox(height: 4),
                        _KPIItem(
                          label: 'Avg Ticket',
                          value: _formatCurrency(avgTicket),
                        ),
                        const SizedBox(height: 4),
                        _KPIItem(
                          label: 'Void Rate',
                          value: '${voidRate.toStringAsFixed(1)}%',
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
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
}

class _KPIItem extends StatelessWidget {
  final String label;
  final String value;

  const _KPIItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}