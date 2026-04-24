import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/departure.dart';
import '../models/station.dart';
import 'subscriptions_provider.dart';

final stationSearchProvider =
    FutureProvider.family<List<Station>, String>((ref, query) async {
  if (query.length < 2) return [];
  final api = ref.read(apiServiceProvider);
  return api.searchStations(query);
});

final departuresProvider = FutureProvider.family<List<Departure>,
    ({String station, String? direction})>((ref, params) async {
  final api = ref.read(apiServiceProvider);
  return api.getDepartures(
    station: params.station,
    direction: params.direction,
  );
});
