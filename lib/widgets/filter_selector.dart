import 'package:flutter/material.dart';
import '../core/theme/aura_theme.dart';
import '../models/aura_image.dart';

class FilterSelector extends StatelessWidget {
  final String? currentFilter;
  final ValueChanged<ImageFilter> onFilterSelected;

  const FilterSelector({
    super.key,
    this.currentFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      scrollDirection: Axis.horizontal,
      itemCount: ImageFilter.presets.length,
      separatorBuilder: (context, index) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        final filter = ImageFilter.presets[index];
        final isSelected = currentFilter == filter.id ||
            (currentFilter == null && filter.id == 'original');

        return GestureDetector(
          onTap: () => onFilterSelected(filter),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AuraColors.primaryPurple
                        : Colors.transparent,
                    width: 2,
                  ),
                  gradient: _getFilterGradient(filter.id),
                ),
                child: Center(
                  child: Icon(
                    _getFilterIcon(filter.id),
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                filter.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? AuraColors.primaryPurple
                      : AuraColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  LinearGradient _getFilterGradient(String filterId) {
    switch (filterId) {
      case 'original':
        return LinearGradient(
          colors: [Colors.grey.shade700, Colors.grey.shade800],
        );
      case 'vivid':
        return const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
        );
      case 'warm':
        return const LinearGradient(
          colors: [Color(0xFFFF9A56), Color(0xFFFFB347)],
        );
      case 'cool':
        return const LinearGradient(
          colors: [Color(0xFF4E8EF7), Color(0xFF6BDBF8)],
        );
      case 'dramatic':
        return const LinearGradient(
          colors: [Color(0xFF2C3E50), Color(0xFF4A5568)],
        );
      case 'noir':
        return const LinearGradient(
          colors: [Color(0xFF1A1A1A), Color(0xFF4A4A4A)],
        );
      default:
        return LinearGradient(
          colors: [Colors.grey.shade600, Colors.grey.shade700],
        );
    }
  }

  IconData _getFilterIcon(String filterId) {
    switch (filterId) {
      case 'original':
        return Icons.image_rounded;
      case 'vivid':
        return Icons.auto_awesome_rounded;
      case 'warm':
        return Icons.wb_sunny_rounded;
      case 'cool':
        return Icons.ac_unit_rounded;
      case 'dramatic':
        return Icons.contrast_rounded;
      case 'noir':
        return Icons.monochrome_photos_rounded;
      default:
        return Icons.filter_rounded;
    }
  }
}
