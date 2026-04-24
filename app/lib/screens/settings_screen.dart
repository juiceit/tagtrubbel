import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tagtrubbel/l10n/generated/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../services/notification_service.dart';
import '../providers/subscriptions_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          _SectionHeader(l10n.language),
          settings.when(
            data: (s) => RadioGroup<String?>(
              groupValue: s.languageCode,
              onChanged: (v) =>
                  ref.read(settingsProvider.notifier).setLanguage(v),
              child: Column(
                children: [
                  RadioListTile<String?>(
                    title: Text(l10n.languageSystem),
                    value: null,
                  ),
                  RadioListTile<String?>(
                    title: Text(l10n.languageSwedish),
                    value: 'sv',
                  ),
                  RadioListTile<String?>(
                    title: Text(l10n.languageEnglish),
                    value: 'en',
                  ),
                ],
              ),
            ),
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const Divider(),
          _SectionHeader(l10n.privacy),
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: Text(l10n.deleteAllData),
            onTap: () => _confirmDeleteAllData(context, ref),
          ),
          const Divider(),
          _SectionHeader(l10n.about),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.appTitle),
            subtitle: Text(l10n.aboutDescription),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAllData(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAllData),
        content: Text(l10n.deleteAllDataConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final deviceId = await NotificationService.getStoredDeviceId();
      if (deviceId != null) {
        try {
          final api = ref.read(apiServiceProvider);
          await api.deleteDevice(deviceId);
          await NotificationService.clearStoredDeviceId();
        } catch (_) {
          // Best effort
        }
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
