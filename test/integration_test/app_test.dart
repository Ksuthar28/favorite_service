import 'dart:io';

import 'package:favorite_service/data/repositories/service_repository_impl.dart';
import 'package:favorite_service/domain/entities/service.dart';
import 'package:favorite_service/domain/usecases/get_services.dart';
import 'package:favorite_service/domain/usecases/toggle_favorite.dart';
import 'package:favorite_service/presentation/pages/services_page.dart';
import 'package:favorite_service/presentation/providers/service_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:integration_test/integration_test.dart';

/// A fake repository for deterministic integration tests
class FakeServiceRepository extends ServiceRepositoryImpl {
  final List<Service> _services;
  final Set<int> _favorites = {};

  FakeServiceRepository(this._services);

  @override
  Future<List<Service>> getServices({int page = 1, int limit = 20}) async {
    final start = (page - 1) * limit;
    final end = (start + limit).clamp(0, _services.length);
    if (start >= _services.length) return [];
    return _services.sublist(start, end);
  }

  @override
  Future<void> toggleFavorite(int id) async {
    if (_favorites.contains(id)) {
      _favorites.remove(id);
    } else {
      _favorites.add(id);
    }
  }

  @override
  Set<int> getFavoriteIds() {
    return _favorites;
  }

  @override
  Future<Set<int>> getFavoriteIdsAsync() async {
    return _favorites;
  }
}

class GetServicesRepository {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getApplicationDocumentsDirectory') {
            return tempDir.path;
          }
          return null;
        });
  });

  group('Favorite Services Integration Test', () {
    testWidgets(
      'Fetch services, toggle favorites, switch tabs, pagination loader',
      (tester) async {
        // --- Prepare fake services ---
        final fakeServices = List.generate(
          10,
          (index) => Service(
            id: index,
            title: 'Service $index',
            body: 'Description $index',
          ),
        );

        final fakeRepository = FakeServiceRepository(fakeServices);
        final getServicesUseCase = GetServices(fakeRepository);
        final toggleFavoriteUseCase = ToggleFavorite(fakeRepository);

        // --- Launch app with ProviderScope overrides ---
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              repositoryProvider.overrideWithValue(fakeRepository),
              getServicesProvider.overrideWithValue(getServicesUseCase),
              toggleFavoriteProvider.overrideWithValue(toggleFavoriteUseCase),
            ],
            child: const MaterialApp(home: ServicesPage()),
          ),
        );

        await tester.pumpAndSettle();

        // --- All Services Tab ---
        final service0Finder = find.text('Service 0');
        expect(service0Finder, findsOneWidget);

        // Tap favorite icon on first service
        final favoriteIcon = find.byKey(const Key('favorite_icon_0'));
        expect(favoriteIcon, findsOneWidget);
        await tester.tap(favoriteIcon);
        await tester.pumpAndSettle();

        // Switch to Favorites tab
        await tester.tap(find.text('Favorites'));
        await tester.pumpAndSettle();

        // Verify Service 0 appears in Favorites
        expect(find.text('Service 0'), findsOneWidget);

        // Remove Service 0 from favorites
        final favHeart = find.byKey(const Key('favorite_icon_0'));
        await tester.tap(favHeart);
        await tester.pumpAndSettle();

        // Service 0 should disappear
        expect(find.text('Service 0'), findsNothing);

        // --- Back to All Services Tab ---
        await tester.tap(find.text('All Services'));
        await tester.pumpAndSettle();

        // Scroll to bottom to trigger pagination
        final listFinder = find.byType(ListView).first;
        await tester.drag(listFinder, const Offset(0, -500));
        await tester.pump(); // start scroll animation
        await tester.pump(const Duration(milliseconds: 50)); // loader delay

        // Wait for next page to load completely
        await tester.pumpAndSettle();

        // Verify new services loaded (2nd page first item)
        final newService = find.text('Service 5');
        expect(newService, findsOneWidget);

        // Loader disappears after fetch
        expect(find.byKey(const Key('bottom_loader')), findsNothing);
      },
    );
  });
}
