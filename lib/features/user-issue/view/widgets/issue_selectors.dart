import 'package:batti_nala/features/shared-issue/models/issue_type_model.dart';
import 'package:flutter/material.dart';

/// Widget for selecting issue types using FilterChips
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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((type) {
        final isSelected = selectedType?.issueTypeId == type.issueTypeId;
        return FilterChip(
          label: Text(type.issueType),
          selected: isSelected,
          onSelected: (_) => onTypeSelected(type),
          backgroundColor: Colors.grey[100],
          selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
        );
      }).toList(),
    );
  }
}

/// Widget for selecting issue priority level
class PrioritySelector extends StatelessWidget {
  final String selectedPriority;
  final Function(String) onPrioritySelected;

  const PrioritySelector({
    super.key,
    required this.selectedPriority,
    required this.onPrioritySelected,
  });

  final List<Map<String, dynamic>> priorities = const [
    {'label': 'LOW', 'color': Colors.green},
    {'label': 'NORMAL', 'color': Colors.blue},
    {'label': 'HIGH', 'color': Colors.red},
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: priorities.map((priority) {
        final label = priority['label'] as String;
        final isSelected = label == selectedPriority;
        final color = priority['color'] as Color;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: InkWell(
              onTap: () => onPrioritySelected(label),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.2)
                      : Colors.grey[100],
                  border: Border.all(
                    color: isSelected ? color : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? color : Colors.grey[600],
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
