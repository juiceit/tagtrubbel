import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subscription.dart';
import '../models/station.dart';
import '../models/departure.dart';

class ApiService {
  final SupabaseClient _client;
  final String? _deviceId;

  ApiService({required SupabaseClient client, String? deviceId})
      : _client = client,
        _deviceId = deviceId;



  Future<String> registerDevice({
    required String fcmToken,
    required String platform,
  }) async {
    final result = await _client
        .from('devices')
        .upsert({'fcm_token': fcmToken, 'platform': platform},
            onConflict: 'fcm_token')
        .select('id')
        .single();
    return result['id'] as String;
  }

  Future<void> deleteDevice(String deviceId) async {
    await _client.from('devices').delete().eq('id', deviceId);
  }

  Future<List<Subscription>> getSubscriptions() async {
    final data = await _client
        .from('subscriptions')
        .select()
        .order('departure_time');
    return data.map((e) => Subscription.fromJson(e)).toList();
  }

  Future<Subscription> createSubscription(Subscription sub) async {
    final result = await _client
        .from('subscriptions')
        .insert({...sub.toJson(), 'device_id': _deviceId}).select().single();
    return Subscription.fromJson(result);
  }

  Future<Subscription> updateSubscription(Subscription sub) async {
    final result = await _client
        .from('subscriptions')
        .update(sub.toJson())
        .eq('id', sub.id)
        .select()
        .single();
    return Subscription.fromJson(result);
  }

  Future<void> deleteSubscription(String id) async {
    await _client.from('subscriptions').delete().eq('id', id);
  }

  Future<List<Station>> searchStations(String query) async {
    final res = await _client.functions.invoke(
      'search-stations',
      queryParameters: {'q': query},
      method: HttpMethod.get,
    );
    final list = jsonDecode(res.data as String) as List;
    return list.map((e) => Station.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Departure>> getDepartures({
    required String station,
    String? direction,
  }) async {
    final params = {'station': station};
    if (direction != null) params['direction'] = direction;

    final res = await _client.functions.invoke(
      'get-departures',
      queryParameters: params,
      method: HttpMethod.get,
    );
    final list = jsonDecode(res.data as String) as List;
    return list
        .map((e) => Departure.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
