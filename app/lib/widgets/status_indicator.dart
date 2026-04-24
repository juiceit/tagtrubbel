import 'package:flutter/material.dart';
import 'package:tagtrubbel/l10n/generated/app_localizations.dart';
import '../models/departure.dart';

class StatusIndicator extends StatelessWidget {
  final TrainStatus status;
  final int? delayMinutes;

  const StatusIndicator({
    super.key,
    required this.status,
    this.delayMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (icon, color, label) = _statusData(l10n);

    return Semantics(
      label: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color, String) _statusData(AppLocalizations l10n) {
    return switch (status) {
      TrainStatus.onTime => (Icons.check_circle, Colors.green, l10n.statusOnTime),
      TrainStatus.warning => (Icons.warning, Colors.amber.shade700, l10n.statusWarning),
      TrainStatus.delayed => (
          Icons.error,
          Colors.red,
          delayMinutes != null
              ? l10n.delayedMinutes(delayMinutes!)
              : l10n.statusDelayed
        ),
      TrainStatus.cancelled => (Icons.cancel, Colors.red.shade900, l10n.statusCancelled),
      TrainStatus.unknown => (Icons.help_outline, Colors.grey, l10n.statusUnknown),
    };
  }
}

class PausedIndicator extends StatelessWidget {
  const PausedIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.statusPaused,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.pause_circle, color: Colors.grey, size: 20),
          const SizedBox(width: 4),
          Text(
            l10n.statusPaused,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
