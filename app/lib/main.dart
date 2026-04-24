import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: Replace with your Supabase project URL and anon key
  await Supabase.initialize(
    url: 'https://YOUR_PROJECT.supabase.co',
    anonKey: 'YOUR_ANON_KEY',
  );

  // Firebase.initializeApp() should be called here once firebase_options.dart
  // is generated via `flutterfire configure`.

  runApp(const ProviderScope(child: TagtrubbelApp()));
}
