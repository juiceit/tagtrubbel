class Subscription {
  final String id;
  final String stationSignature;
  final String stationName;
  final String directionSignature;
  final String directionName;
  final String departureTime;
  final List<int> activeDays;
  final bool enabled;

  Subscription({
    required this.id,
    required this.stationSignature,
    required this.stationName,
    required this.directionSignature,
    required this.directionName,
    required this.departureTime,
    required this.activeDays,
    required this.enabled,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      stationSignature: json['station_signature'] as String,
      stationName: json['station_name'] as String,
      directionSignature: json['direction_signature'] as String,
      directionName: json['direction_name'] as String,
      departureTime: json['departure_time'] as String,
      activeDays: (json['active_days'] as List).cast<int>(),
      enabled: json['enabled'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'station_signature': stationSignature,
      'station_name': stationName,
      'direction_signature': directionSignature,
      'direction_name': directionName,
      'departure_time': departureTime,
      'active_days': activeDays,
      'enabled': enabled,
    };
  }

  Subscription copyWith({bool? enabled}) {
    return Subscription(
      id: id,
      stationSignature: stationSignature,
      stationName: stationName,
      directionSignature: directionSignature,
      directionName: directionName,
      departureTime: departureTime,
      activeDays: activeDays,
      enabled: enabled ?? this.enabled,
    );
  }
}
