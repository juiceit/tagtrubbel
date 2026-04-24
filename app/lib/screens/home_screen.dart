import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tagtrubbel/l10n/generated/app_localizations.dart';
import '../providers/subscriptions_provider.dart';
import '../widgets/subscription_card.dart';
import 'add_subscription_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final subscriptions = ref.watch(subscriptionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: l10n.settings,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: subscriptions.when(
        data: (subs) {
          if (subs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.train, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noSubscriptions,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.noSubscriptionsHint,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(subscriptionsProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: subs.length,
              itemBuilder: (ctx, i) => SubscriptionCard(
                subscription: subs[i],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AddSubscriptionScreen(existing: subs[i]),
                  ),
                ),
                onToggleEnabled: () => ref
                    .read(subscriptionsProvider.notifier)
                    .toggleEnabled(subs[i].id),
                onDelete: () => ref
                    .read(subscriptionsProvider.notifier)
                    .remove(subs[i].id),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(l10n.errorNetwork),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(subscriptionsProvider.notifier).refresh(),
                child: Text(l10n.pullToRefresh),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.addSubscription,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddSubscriptionScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
