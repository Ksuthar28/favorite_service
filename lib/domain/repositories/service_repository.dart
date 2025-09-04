import '../entities/service.dart';

/// Abstract repository that defines the contract for fetching services
/// and managing favorites.
/// Keeps domain layer independent from data sources (API, Hive, etc.).
abstract class ServiceRepository {
  /// Fetches a list of services from a data source.
  /// [page] = page number (for pagination).
  /// [limit] = number of items per page.
  Future<List<Service>> getServices({int page = 1, int limit = 20});

  /// Toggles a service as favorite/unfavorite.
  Future<void> toggleFavorite(int id);

  /// Returns the set of favorite service IDs persisted locally.
  /// This keeps UI and business logic in sync with Hive.
  Set<int> getFavoriteIds();
}
