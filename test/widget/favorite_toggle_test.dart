import 'package:favorite_service/data/repositories/service_repository_impl.dart';
import 'package:favorite_service/domain/entities/service.dart';
import 'package:favorite_service/domain/usecases/get_services.dart';
import 'package:favorite_service/domain/usecases/toggle_favorite.dart';
import 'package:favorite_service/presentation/pages/services_page.dart';
import 'package:favorite_service/presentation/providers/service_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// === Mock repository ===
class MockServiceRepository extends Mock implements ServiceRepositoryImpl {}

void main() {
  late MockServiceRepository mockRepository;
  late GetServices getServices;
  late ToggleFavorite toggleFavoriteUseCase;

  // Fake services
  final fakeServices = List.generate(
    5,
    (index) =>
        Service(id: index, title: 'Service $index', body: 'Description $index'),
  );

  // In-memory favorite IDs
  final favoriteIds = <int>{};

  setUp(() {
    mockRepository = MockServiceRepository();
    getServices = GetServices(mockRepository);
    toggleFavoriteUseCase = ToggleFavorite(mockRepository);

    // Mock getFavoriteIdsAsync to return current favoriteIds set
    when(
      () => mockRepository.getFavoriteIdsAsync(),
    ).thenAnswer((_) async => favoriteIds);

    // Mock toggleFavorite to update favoriteIds immediately
    when(() => mockRepository.toggleFavorite(any())).thenAnswer((
      invocation,
    ) async {
      final id = invocation.positionalArguments[0] as int;
      if (favoriteIds.contains(id)) {
        favoriteIds.remove(id);
      } else {
        favoriteIds.add(id);
      }
    });

    // Mock fetching services
    when(
      () => getServices(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => fakeServices);
  });

  testWidgets('Tapping heart toggles favorite and updates Favorites tab', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(mockRepository),
          getServicesProvider.overrideWithValue(getServices),
          toggleFavoriteProvider.overrideWithValue(toggleFavoriteUseCase),
        ],
        child: const MaterialApp(home: ServicesPage()),
      ),
    );

    // Wait for initial fetch
    await tester.pump(); // trigger microtask
    await tester.pumpAndSettle();

    // Verify first service exists in All Services tab
    expect(find.text('Service 0'), findsOneWidget);

    // Tap heart icon to add Service 0 to favorites
    final heartIcon = find.byKey(const Key('favorite_icon_0'));
    expect(heartIcon, findsOneWidget);
    await tester.tap(heartIcon);
    await tester.pumpAndSettle();

    // Switch to Favorites tab
    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();

    // Verify Service 0 appears in Favorites tab
    expect(find.text('Service 0'), findsOneWidget);

    // Tap heart again to remove from favorites
    final favHeart = find.byKey(const Key('favorite_icon_0'));
    await tester.tap(favHeart);
    await tester.pumpAndSettle();

    // Service should disappear from Favorites tab
    expect(find.text('Service 0'), findsNothing);
  });
}
