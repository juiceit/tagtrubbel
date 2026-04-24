import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subscription.dart';
import '../services/api_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(client: Supabase.instance.client);
});

final subscriptionsProvider =
    AsyncNotifierProvider<SubscriptionsNotifier, List<Subscription>>(
        SubscriptionsNotifier.new);

class SubscriptionsNotifier extends AsyncNotifier<List<Subscription>> {
  @override
  Future<List<Subscription>> build() async {
    final api = ref.read(apiServiceProvider);
    try {
      return await api.getSubscriptions();
    } catch (_) {
      return [];
    }
  }

  Future<void> add(Subscription sub) async {
    final api = ref.read(apiServiceProvider);
    final created = await api.createSubscription(sub);
    final current = state.valueOrNull ?? [];
    state = AsyncData([...current, created]);
  }

  Future<void> updateSubscription(Subscription sub) async {
    final api = ref.read(apiServiceProvider);
    final updated = await api.updateSubscription(sub);
    final current = state.valueOrNull ?? [];
    state = AsyncData(
      current.map((s) => s.id == updated.id ? updated : s).toList(),
    );
  }

  Future<void> toggleEnabled(String id) async {
    final current = state.valueOrNull ?? [];
    final sub = current.firstWhere((s) => s.id == id);
    await updateSubscription(sub.copyWith(enabled: !sub.enabled));
  }

  Future<void> remove(String id) async {
    final api = ref.read(apiServiceProvider);
    await api.deleteSubscription(id);
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((s) => s.id != id).toList());
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}
