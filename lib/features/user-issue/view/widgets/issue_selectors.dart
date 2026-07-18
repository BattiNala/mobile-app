import 'package:batti_nala/core/constants/colors.dart';
import 'package:batti_nala/features/shared/issue/models/issue_type_model.dart';
import 'package:flutter/material.dart';

class IssueTypeSelector extends StatelessWidget {
  final List<IssueType> types;
  final IssueType? selectedType;
  final Function(IssueType) onTypeSelected;

  const IssueTypeSelector({
    super.key,
    required this.types,
    required this.selectedType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((type) {
        final isSelected = selectedType?.issueTypeId == type.issueTypeId;
        return FilterChip(
          label: Text(type.issueType),
          selected: isSelected,
          onSelected: (_) => onTypeSelected(type),
          backgroundColor: isDark
              ? AppColors.darkSurface2
              : const Color(0xFFEEF2FF),
          selectedColor: primary.withValues(alpha: 0.18),
          labelStyle: TextStyle(
            color: isSelected
                ? primary
                : (isDark ? AppColors.darkTextMain : AppColors.textSecondary),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
          side: BorderSide(
            color: isSelected
                ? primary.withValues(alpha: 0.5)
                : (isDark ? AppColors.darkBorder : AppColors.border),
            width: isSelected ? 1.5 : 1,
          ),
          checkmarkColor: primary,
          showCheckmark: false,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        );
      }).toList(),
    );
  }
}

class PrioritySelector extends StatelessWidget {
  final String selectedPriority;
  final Function(String) onPrioritySelected;

  const PrioritySelector({
    super.key,
    required this.selectedPriority,
    required this.onPrioritySelected,
  });

  final List<Map<String, dynamic>> priorities = const [
    {'label': 'LOW', 'color': Color(0xFF059669)},
    {'label': 'NORMAL', 'color': Color(0xFF2563EB)},
    {'label': 'HIGH', 'color': Color(0xFFDC2626)},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: priorities.map((priority) {
        final label = priority['label'] as String;
        final isSelected = label == selectedPriority;
        final color = priority['color'] as Color;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: InkWell(
              onTap: () => onPrioritySelected(label),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.15)
                      : (isDark
                            ? AppColors.darkSurface2
                            : const Color(0xFFF8FAFF)),
                  border: Border.all(
                    color: isSelected
                        ? color
                        : (isDark ? AppColors.darkBorder : AppColors.border),
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected
                        ? color
                        : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
