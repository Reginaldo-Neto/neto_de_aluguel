import 'package:flutter/material.dart';
import '../models/category.dart';

class CategoryChipGrid extends StatelessWidget {
  final String? activeCategory;
  final void Function(String?) onSelect;

  const CategoryChipGrid({
    super.key,
    required this.activeCategory,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: mockCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = mockCategories[index];
          final isActive = activeCategory == cat.name;
          return _CategoryItem(
            category: cat,
            isActive: isActive,
            onTap: () => onSelect(isActive ? null : cat.name),
          );
        },
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final CategoryModel category;
  final bool isActive;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.category,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? category.color : category.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(category.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              category.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isActive ? Colors.white : category.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
