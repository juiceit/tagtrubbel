import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tagtrubbel/l10n/generated/app_localizations.dart';
import '../models/subscription.dart';
import '../models/station.dart';
import '../providers/subscriptions_provider.dart';
import '../widgets/station_picker.dart';
import '../widgets/day_selector.dart';

class AddSubscriptionScreen extends ConsumerStatefulWidget {
  final Subscription? existing;

  const AddSubscriptionScreen({super.key, this.existing});

  @override
  ConsumerState<AddSubscriptionScreen> createState() =>
      _AddSubscriptionScreenState();
}

class _AddSubscriptionScreenState
    extends ConsumerState<AddSubscriptionScreen> {
  Station? _station;
  Station? _direction;
  TimeOfDay _time = const TimeOfDay(hour: 7, minute: 0);
  List<int> _days = [1, 2, 3, 4, 5];
  bool _enabled = true;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final sub = widget.existing!;
      _station = Station(signature: sub.stationSignature, name: sub.stationName);
      _direction =
          Station(signature: sub.directionSignature, name: sub.directionName);
      final parts = sub.departureTime.split(':');
      _time = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
      _days = List<int>.from(sub.activeDays);
      _enabled = sub.enabled;
    }
  }

  Future<void> _save() async {
    if (_station == null || _direction == null || _days.isEmpty) return;

    setState(() => _saving = true);

    final timeStr =
        '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';

    final sub = Subscription(
      id: widget.existing?.id ?? '',
      stationSignature: _station!.signature,
      stationName: _station!.name,
      directionSignature: _direction!.signature,
      directionName: _direction!.name,
      departureTime: timeStr,
      activeDays: _days,
      enabled: _enabled,
    );

    try {
      if (_isEditing) {
        await ref.read(subscriptionsProvider.notifier).updateSubscription(sub);
      } else {
        await ref.read(subscriptionsProvider.notifier).add(sub);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.editSubscription : l10n.addSubscription),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: l10n.delete,
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(l10n.delete),
                    content: Text(l10n.confirmDelete),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(l10n.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(l10n.delete),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && mounted) {
                  await ref
                      .read(subscriptionsProvider.notifier)
                      .remove(widget.existing!.id);
                  if (mounted) Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StationPicker(
              initial: _station,
              onSelected: (s) => setState(() => _station = s),
            ),
            const SizedBox(height: 24),
            Text(l10n.direction,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            StationPicker(
              initial: _direction,
              onSelected: (s) => setState(() => _direction = s),
            ),
            const SizedBox(height: 24),
            Text(l10n.departureTime,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _time,
                );
                if (picked != null) setState(() => _time = picked);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule),
                    const SizedBox(width: 8),
                    Text(
                      '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(l10n.activeDays,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            DaySelector(
              selectedDays: _days,
              onChanged: (days) => setState(() => _days = days),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 24),
              SwitchListTile(
                title: Text(_enabled ? l10n.enabled : l10n.paused),
                value: _enabled,
                onChanged: (v) => setState(() => _enabled = v),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (_station != null &&
                        _direction != null &&
                        _days.isNotEmpty &&
                        !_saving)
                    ? _save
                    : null,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
