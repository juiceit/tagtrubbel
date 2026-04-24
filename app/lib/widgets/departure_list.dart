import 'package:flutter/material.dart';
import '../models/departure.dart';
import 'status_indicator.dart';

class DepartureList extends StatelessWidget {
  final List<Departure> departures;

  const DepartureList({super.key, required this.departures});

  @override
  Widget build(BuildContext context) {
    if (departures.isEmpty) {
      return const Center(child: Text('—'));
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: departures.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final dep = departures[i];
        return ListTile(
          leading: Text(
            dep.scheduledTime.substring(11, 16),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          title: Text('Tåg ${dep.trainIdent} → ${dep.destination}'),
          trailing: StatusIndicator(
            status: dep.status,
            delayMinutes: dep.delayMinutes,
          ),
        );
      },
    );
  }
}
