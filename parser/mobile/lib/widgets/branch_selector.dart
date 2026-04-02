import 'package:flutter/material.dart';
import '../models/branch.dart';

class BranchSelector extends StatelessWidget {
  final List<Branch> branches;
  final String selectedBranchCode;
  final Function(String) onBranchSelected;

  const BranchSelector({
    super.key,
    required this.branches,
    required this.selectedBranchCode,
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
              children: [
                _buildBranchChip(context, 'ALL', 'All Branches', 'ທຸກສາຂາ', null),
                ...branches.map((branch) => _buildBranchChip(
                  context,
                  branch.code,
                  branch.nameEn ?? branch.name,
                  branch.nameLao,
                  null,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchChip(
    BuildContext context,
    String code,
    String nameEn,
    String? nameLao,
    Color? chipColor,
  ) {
    final isSelected = code == selectedBranchCode;
    final displayName = nameLao != null && nameLao.isNotEmpty ? nameLao : nameEn;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              nameEn,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (nameLao != null && nameLao.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                nameLao,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? Colors.white70 : Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) onBranchSelected(code);
        },
        selectedColor: chipColor ?? Theme.of(context).colorScheme.primaryContainer,
        backgroundColor: Colors.grey[200],
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
          vertical: 12,
        ),
      ),
    );
  }
}