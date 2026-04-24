import 'package:flutter/material.dart';
import 'package:tagtrubbel/l10n/generated/app_localizations.dart';

class DaySelector extends StatelessWidget {
  final List<int> selectedDays;
  final ValueChanged<List<int>> onChanged;

  const DaySelector({
    super.key,
    required this.selectedDays,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dayLabels = [
      l10n.monday,
      l10n.tuesday,
      l10n.wednesday,
      l10n.thursday,
      l10n.friday,
      l10n.saturday,
      l10n.sunday,
    ];

    return Wrap(
      spacing: 8,
      children: List.generate(7, (index) {
        final day = index + 1;
        final selected = selectedDays.contains(day);
        return Semantics(
          label: dayLabels[index],
          toggled: selected,
          child: FilterChip(
            label: Text(dayLabels[index]),
            selected: selected,
            onSelected: (value) {
              final updated = List<int>.from(selectedDays);
              if (value) {
                updated.add(day);
              } else {
                updated.remove(day);
              }
              updated.sort();
              onChanged(updated);
            },
          ),
        );
      }),
    );
  }
}
