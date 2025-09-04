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

  setUp(() {
    mockRepository = MockServiceRepository();
    getServices = GetServices(mockRepository);
    toggleFavoriteUseCase = ToggleFavorite(mockRepository);

    // Initial favorite IDs empty
    when(
      () => mockRepository.getFavoriteIdsAsync(),
    ).thenAnswer((_) async => <int>{});

    // toggleFavorite does nothing
    when(() => mockRepository.toggleFavorite(any())).thenAnswer((_) async {});
  });

  testWidgets('Pagination bottom loader shows and loads next page', (
    tester,
  ) async {
    // First page: 5 services
    final firstPage = List.generate(
      5,
      (index) => Service(
        id: index,
        title: 'Service $index',
        body: 'Description $index',
      ),
    );

    // Second page: 5 more services
    final secondPage = List.generate(
      5,
      (index) => Service(
        id: index,
        title: 'Service $index',
        body: 'Description $index',
      ),
    );

    // Mock getServices to return pages based on page number
    when(
      () => getServices(page: 1, limit: any(named: 'limit')),
    ).thenAnswer((_) async => firstPage);
    when(() => getServices(page: 2, limit: any(named: 'limit'))).thenAnswer((
      _,
    ) async {
      await Future.delayed(const Duration(milliseconds: 200));
      return secondPage;
    });

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
    await tester.pump();
    await tester.pumpAndSettle();

    // Verify first page services exist
    for (var service in firstPage) {
      expect(find.text(service.title), findsOneWidget);
    }

    // Scroll to bottom to trigger fetchNextPage
    final listFinder = find.byType(ListView).first;
    await tester.drag(listFinder, const Offset(0, -500)); // scroll up
    await tester.pump(); // start scroll animation

    await tester.pumpAndSettle(); // wait for second page to load

    // Verify second page services appear
    for (var service in secondPage) {
      expect(find.text(service.title), findsOneWidget);
    }

    // Bottom loader should disappear after load
    expect(find.byKey(const Key('bottom_loader')), findsNothing);
  });
}
