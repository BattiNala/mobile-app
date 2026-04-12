import 'package:batti_nala/features/shared-issue/models/issue_type_model.dart';
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
