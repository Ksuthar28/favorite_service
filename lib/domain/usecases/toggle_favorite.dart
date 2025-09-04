import '../repositories/service_repository.dart';

/// Use case for toggling a service as favorite or unfavorite.
/// Keeps domain logic independent of data storage (Hive, API, etc.).
class ToggleFavorite {
  final ServiceRepository repository;

  ToggleFavorite(this.repository);

  /// Executes the use case by toggling the given [serviceId].
  Future<void> call(int serviceId) {
    return repository.toggleFavorite(serviceId);
  }
}
