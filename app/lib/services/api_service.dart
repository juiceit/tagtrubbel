import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/subscription.dart';
import '../models/station.dart';
import '../models/departure.dart';

class ApiService {
  // TODO: Update with your backend URL
  static const String _baseUrl = 'http://localhost:3000/api';
  final String? _deviceId;

  ApiService({String? deviceId}) : _deviceId = deviceId;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_deviceId case final id?) 'X-Device-Id': id,
      };

  Future<String> registerDevice({
    required String fcmToken,
    required String platform,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/devices'),
      headers: _headers,
      body: jsonEncode({'fcm_token': fcmToken, 'platform': platform}),
    );
    _checkResponse(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['id'] as String;
  }

  Future<void> deleteDevice(String deviceId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/devices/$deviceId'),
      headers: _headers,
    );
    _checkResponse(response);
  }

  Future<List<Subscription>> getSubscriptions() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/subscriptions'),
      headers: _headers,
    );
    _checkResponse(response);
    final list = jsonDecode(response.body) as List;
    return list
        .map((e) => Subscription.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Subscription> createSubscription(Subscription sub) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/subscriptions'),
      headers: _headers,
      body: jsonEncode(sub.toJson()),
    );
    _checkResponse(response);
    return Subscription.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Subscription> updateSubscription(Subscription sub) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/subscriptions/${sub.id}'),
      headers: _headers,
      body: jsonEncode(sub.toJson()),
    );
    _checkResponse(response);
    return Subscription.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> deleteSubscription(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/subscriptions/$id'),
      headers: _headers,
    );
    _checkResponse(response);
  }

  Future<List<Station>> searchStations(String query) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/stations?q=${Uri.encodeComponent(query)}'),
      headers: _headers,
    );
    _checkResponse(response);
    final list = jsonDecode(response.body) as List;
    return list
        .map((e) => Station.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Departure>> getDepartures({
    required String station,
    String? direction,
  }) async {
    var url = '$_baseUrl/departures?station=${Uri.encodeComponent(station)}';
    if (direction != null) {
      url += '&direction=${Uri.encodeComponent(direction)}';
    }
    final response = await http.get(Uri.parse(url), headers: _headers);
    _checkResponse(response);
    final list = jsonDecode(response.body) as List;
    return list
        .map((e) => Departure.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void _checkResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode, response.body);
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String body;
  ApiException(this.statusCode, this.body);

  @override
  String toString() => 'ApiException($statusCode): $body';
}
