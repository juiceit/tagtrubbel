import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tagtrubbel/l10n/generated/app_localizations.dart';
import '../models/station.dart';
import '../providers/departures_provider.dart';

class StationPicker extends ConsumerStatefulWidget {
  final Station? initial;
  final ValueChanged<Station> onSelected;

  const StationPicker({
    super.key,
    this.initial,
    required this.onSelected,
  });

  @override
  ConsumerState<StationPicker> createState() => _StationPickerState();
}

class _StationPickerState extends ConsumerState<StationPicker> {
  late final TextEditingController _controller;
  Station? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
    _controller = TextEditingController(text: widget.initial?.name ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final query = _controller.text;
    final results = query.length >= 2
        ? ref.watch(stationSearchProvider(query))
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: l10n.station,
            hintText: l10n.searchStation,
            prefixIcon: const Icon(Icons.train),
            border: const OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        if (results != null && _selected == null)
          results.when(
            data: (stations) => stations.isEmpty
                ? const SizedBox.shrink()
                : Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: Card(
                      margin: const EdgeInsets.only(top: 4),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: stations.length,
                        itemBuilder: (ctx, i) => ListTile(
                          title: Text(stations[i].name),
                          subtitle: Text(stations[i].signature),
                          dense: true,
                          onTap: () {
                            setState(() {
                              _selected = stations[i];
                              _controller.text = stations[i].name;
                            });
                            widget.onSelected(stations[i]);
                          },
                        ),
                      ),
                    ),
                  ),
            loading: () => const Padding(
              padding: EdgeInsets.all(8),
              child: LinearProgressIndicator(),
            ),
            error: (_, _) => const SizedBox.shrink(),
          ),
      ],
    );
  }
}
