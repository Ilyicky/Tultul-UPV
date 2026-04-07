import 'package:flutter/material.dart';

class FilterBottomSheet extends StatelessWidget {
  final String title;
  final List<String> selectedFilters;
  final List<String> availableFilters;
  final Function(String) onFilterToggle;
  final VoidCallback onReset;
  final VoidCallback onApply;
  final bool hasActiveFilters;

  const FilterBottomSheet({
    super.key,
    required this.title,
    required this.selectedFilters,
    required this.availableFilters,
    required this.onFilterToggle,
    required this.onReset,
    required this.onApply,
    this.hasActiveFilters = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                if (hasActiveFilters)
                  TextButton.icon(
                    onPressed: onReset,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    availableFilters.map((filter) {
                      final isSelected = selectedFilters.contains(filter);
                      return FilterChip(
                        label: filter,
                        selected: isSelected,
                        onSelected: (selected) => onFilterToggle(filter),
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        selectedColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        checkmarkColor:
                            Theme.of(context).colorScheme.onPrimaryContainer,
                        labelStyle: TextStyle(
                          color:
                              isSelected
                                  ? Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer
                                  : Theme.of(context).colorScheme.onSurface,
                        ),
                      );
                    }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onApply,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final Color? backgroundColor;
  final Color? selectedColor;
  final Color? checkmarkColor;
  final TextStyle? labelStyle;

  const FilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.backgroundColor,
    this.selectedColor,
    this.checkmarkColor,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      backgroundColor: backgroundColor,
      selectedColor: selectedColor,
      checkmarkColor: checkmarkColor,
      labelStyle: labelStyle,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color:
              selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline.withOpacity(0.5),
        ),
      ),
    );
  }
}
