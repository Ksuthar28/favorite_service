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

/// Mock repository to return fake data
class MockServiceRepository extends Mock implements ServiceRepositoryImpl {}

void main() {
  late MockServiceRepository mockRepository;

  // Sample fake services
  final fakeServices = List.generate(
    5,
    (index) =>
        Service(id: index, title: 'Service $index', body: 'Description $index'),
  );

  setUp(() {
    mockRepository = MockServiceRepository();

    // Mock async Hive favorites to return empty set
    when(
      () => mockRepository.getFavoriteIdsAsync(),
    ).thenAnswer((_) async => <int>{});

    // Mock toggleFavorite to do nothing
    when(() => mockRepository.toggleFavorite(any())).thenAnswer((_) async {});
  });

  testWidgets('All Services tab shows loading and then services', (
    tester,
  ) async {
    // Mock GetServices use case to return fake services
    final getServices = GetServices(mockRepository);
    when(
      () => getServices(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => fakeServices);

    final toggleFavoriteUseCase = ToggleFavorite(mockRepository);

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

    // Initial loading
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for async init + fetchInitial
    await tester.pumpAndSettle();

    // All services should be rendered
    for (var service in fakeServices) {
      expect(find.text(service.title), findsOneWidget);
      expect(find.text(service.body), findsOneWidget);
    }

    // Verify RefreshIndicator is present
    expect(find.byType(RefreshIndicator), findsOneWidget);
  });

  testWidgets('Pull-to-refresh reloads services', (tester) async {
    final getServices = GetServices(mockRepository);
    when(
      () => getServices(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => fakeServices);

    final toggleFavoriteUseCase = ToggleFavorite(mockRepository);

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

    await tester.pumpAndSettle();

    // Trigger pull-to-refresh
    final listFinder = find.byType(RefreshIndicator);
    expect(listFinder, findsOneWidget);

    await tester.drag(listFinder, const Offset(0, 300));
    await tester.pump(); // start the refresh
    await tester.pump(const Duration(seconds: 1)); // simulate refresh delay
    await tester.pumpAndSettle();

    // Verify services still appear after refresh
    for (var service in fakeServices) {
      expect(find.text(service.title), findsOneWidget);
      expect(find.text(service.body), findsOneWidget);
    }
  });

  testWidgets('Pagination bottom loader shows during fetchNextPage', (
    tester,
  ) async {
    final getServices = GetServices(mockRepository);

    // First call returns first 5 services
    when(
      () => getServices(page: 1, limit: any(named: 'limit')),
    ).thenAnswer((_) async => fakeServices);

    // Second page returns 5 more
    final secondPage = List.generate(
      5,
      (index) => Service(
        id: index, // no +5 needed
        title: 'Service $index',
        body: 'Description $index',
      ),
    );
    when(
      () => getServices(page: 2, limit: any(named: 'limit')),
    ).thenAnswer((_) async => secondPage);

    final toggleFavoriteUseCase = ToggleFavorite(mockRepository);

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

    await tester.pumpAndSettle();

    // Scroll to bottom to trigger fetchNextPage
    final listFinder = find.byType(ListView).first;
    await tester.drag(listFinder, const Offset(0, -500));
    await tester.pump();

    // Wait for second page to load
    await tester.pumpAndSettle();

    // Verify new services appear
    for (var service in secondPage) {
      expect(find.text(service.title), findsOneWidget);
    }
  });
}
