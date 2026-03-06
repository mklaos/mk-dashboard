import 'package:flutter/material.dart';

class BranchSelector extends StatelessWidget {
  final List<String> branchCodes;
  final String selectedBranch;
  final Function(String) onBranchSelected;

  const BranchSelector({
    super.key,
    required this.branchCodes,
    required this.selectedBranch,
    required this.onBranchSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Branch',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: branchCodes.map((code) {
                final isSelected = code == selectedBranch;
                final isAll = code == 'ALL';

                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      isAll ? 'All Branches' : code,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        onBranchSelected(code);
                      }
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: Theme.of(context).colorScheme.primaryContainer,
                    checkmarkColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}