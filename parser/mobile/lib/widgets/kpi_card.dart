import 'package:flutter/material.dart';

class KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final double? growthPercentage; // Optional growth percentage for indicator
  final String? previousValue; // Optional previous value for display

  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.growthPercentage,
    this.previousValue,
  });

  @override
  Widget build(BuildContext context) {
    final hasGrowth = growthPercentage != null;
    final isPositive = hasGrowth && growthPercentage! >= 0;

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            // Growth indicator
            const SizedBox(height: 2),
            Row(
              children: [
                if (hasGrowth) ...[
                  Icon(
                    isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: isPositive ? Colors.green : Colors.red,
                    size: 16,
                  ),
                  Text(
                    '${growthPercentage!.abs().toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                  ),
                ] else ...[
                  Icon(
                    Icons.horizontal_rule,
                    color: Colors.grey[400],
                    size: 14,
                  ),
                  Text(
                    'N/A',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
