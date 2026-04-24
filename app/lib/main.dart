import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase.initializeApp() should be called here once firebase_options.dart
  // is generated via `flutterfire configure`.
  runApp(const ProviderScope(child: TagtrubbelApp()));
}
