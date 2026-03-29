import 'package:flutter/material.dart';
import '../models/brand.dart';

class BrandSelector extends StatelessWidget {
  final List<Brand> brands;
  final String selectedBrandId;
  final Function(String) onBrandSelected;

  const BrandSelector({
    super.key,
    required this.brands,
    required this.selectedBrandId,
    required this.onBrandSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Brand',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildBrandChip(context, 'ALL', 'All Brands', null),
                ...brands.map((brand) => _buildBrandChip(
                  context,
                  brand.id,
                  brand.displayName,
                  brand.primaryColor,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandChip(BuildContext context, String id, String label, String? colorHex) {
    final isSelected = id == selectedBrandId;
    Color? chipColor;
    if (colorHex != null) {
      try {
        chipColor = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
      } catch (e) {
        chipColor = Theme.of(context).primaryColor;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) onBrandSelected(id);
        },
        selectedColor: chipColor ?? Theme.of(context).primaryColor,
        backgroundColor: Colors.grey[200],
        checkmarkColor: Colors.white,
      ),
    );
  }
}
