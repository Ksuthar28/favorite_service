import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/service_repository_impl.dart';
import '../../domain/entities/service.dart';
import '../../domain/usecases/get_services.dart';
import '../../domain/usecases/toggle_favorite.dart';

/// StateNotifier responsible for:
/// - Fetching services (pagination, refresh)
/// - Managing favorites (persisted in Hive)
/// - Handling loading/error/data states
class ServicesNotifier extends StateNotifier<AsyncValue<List<Service>>> {
  final GetServices getServices;
  final ToggleFavorite toggleFavoriteUseCase;
  final ServiceRepositoryImpl repository;

  int _page = 1; // Current page for pagination
  final int _limit = 20; // Items per page
  bool _isFetching = false; // Tracks pagination fetch
  Set<int> favoriteIds = {}; // Cached favorite IDs

  /// Public getter for UI to show bottom loader
  bool get isFetching => _isFetching;

  /// Constructor
  /// Starts asynchronous initialization
  ServicesNotifier({
    required this.getServices,
    required this.toggleFavoriteUseCase,
    required this.repository,
  }) : super(const AsyncValue.loading()) {
    // Run async init after provider is ready
    Future.microtask(_init);
  }

  /// Async initialization:
  /// - Load favorites from Hive
  /// - Fetch initial services after favorites are ready
  Future<void> _init() async {
    favoriteIds = await repository.getFavoriteIdsAsync();

    if (mounted) {
      await fetchInitial();
    }
  }

  /// Fetch the first page of services
  Future<void> fetchInitial() async {
    _page = 1;
    state = const AsyncValue.loading();
    await _fetch();
  }

  /// Fetch next page for pagination / infinite scroll
  Future<void> fetchNextPage() async {
    if (_isFetching) return;
    _page++;
    await _fetch(append: true);
  }

  /// Refresh the service list (pull-to-refresh)
  Future<void> refresh() async {
    _page = 1;
    await _fetch();
  }

  /// Toggle favorite/unfavorite a service
  /// - Updates Hive and local favoriteIds cache
  /// - Updates state so UI rebuilds immediately
  Future<void> toggleFavorite(int id) async {
    await toggleFavoriteUseCase.call(id);

    // Reload favorites from Hive to stay in sync
    favoriteIds = await repository.getFavoriteIdsAsync();

    // Refresh state so UI updates immediately
    state.whenData((services) {
      if (mounted) state = AsyncValue.data(List.from(services));
    });
  }

  /// Filters only favorite services from a given list
  List<Service> getFavoriteServices(List<Service> services) {
    return services.where((s) => favoriteIds.contains(s.id)).toList();
  }

  /// Internal fetch method
  /// - [append] = true → append to existing list for pagination
  /// - Otherwise replaces the list (initial/refresh)
  Future<void> _fetch({bool append = false}) async {
    if (_isFetching) return;
    _isFetching = true;

    // Trigger UI rebuild to show bottom loader
    state = state.whenData((services) => List.from(services));

    try {
      final newServices = await getServices(page: _page, limit: _limit);

      if (!mounted) return;

      state = state.when(
        data: (existing) => AsyncValue.data(
          append ? [...existing, ...newServices] : newServices,
        ),
        loading: () => AsyncValue.data(newServices),
        error: (_, __) => AsyncValue.data(newServices),
      );
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    } finally {
      _isFetching = false;

      // Rebuild UI to remove loader after fetch finishes
      if (mounted) state = state.whenData((services) => List.from(services));
    }
  }
}
