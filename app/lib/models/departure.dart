enum TrainStatus { onTime, warning, delayed, cancelled, unknown }

class Departure {
  final String trainIdent;
  final String scheduledTime;
  final String? estimatedTime;
  final bool cancelled;
  final List<String> deviations;
  final String destination;

  Departure({
    required this.trainIdent,
    required this.scheduledTime,
    this.estimatedTime,
    required this.cancelled,
    required this.deviations,
    required this.destination,
  });

  factory Departure.fromJson(Map<String, dynamic> json) {
    return Departure(
      trainIdent: json['train_ident'] as String,
      scheduledTime: json['scheduled_time'] as String,
      estimatedTime: json['estimated_time'] as String?,
      cancelled: json['cancelled'] as bool,
      deviations: (json['deviations'] as List?)?.cast<String>() ?? [],
      destination: json['destination'] as String,
    );
  }

  TrainStatus get status {
    if (cancelled) return TrainStatus.cancelled;
    if (estimatedTime != null && estimatedTime != scheduledTime) {
      return TrainStatus.delayed;
    }
    return TrainStatus.onTime;
  }

  int? get delayMinutes {
    if (estimatedTime == null) return null;
    final scheduled = DateTime.parse(scheduledTime);
    final estimated = DateTime.parse(estimatedTime!);
    final diff = estimated.difference(scheduled).inMinutes;
    return diff > 0 ? diff : null;
  }
}
