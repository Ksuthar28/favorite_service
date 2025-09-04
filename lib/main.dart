import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/constants/strings.dart';
import 'data/repositories/service_repository_impl.dart';
import 'presentation/pages/services_page.dart';
import 'presentation/providers/service_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Must be awaited — sets up Hive base directory
  await Hive.initFlutter();

  // Open box asynchronously in a microtask (doesn’t block app launch)
  await Hive.openBox('favorites_box');

  runApp(const ProviderScope(child: MyApp()));
}

/// Root widget of the app.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Strings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: ProviderScope(
        overrides: [
          // Repository dependency injection
          repositoryProvider.overrideWithValue(ServiceRepositoryImpl()),
        ],
        child: const ServicesPage(),
      ),
    );
  }
}
