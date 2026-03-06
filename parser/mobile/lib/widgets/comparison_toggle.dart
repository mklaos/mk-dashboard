import 'package:flutter/material.dart';

class ComparisonToggle extends StatelessWidget {
  final bool showComparison;
  final VoidCallback onToggle;

  const ComparisonToggle({
    super.key,
    required this.showComparison,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            showComparison ? Icons.compare_arrows : Icons.view_list,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            showComparison ? 'Comparison View' : 'Totals View',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.swap_horiz,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: onToggle,
            tooltip: 'Toggle View',
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}