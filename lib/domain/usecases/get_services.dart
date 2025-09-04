import '../entities/service.dart';
import '../repositories/service_repository.dart';

/// Use case for fetching services from the repository.
/// Keeps application logic separate from UI and data sources.
class GetServices {
  final ServiceRepository repository;

  GetServices(this.repository);

  /// Executes the use case.
  /// Returns a paginated list of [Service].
  Future<List<Service>> call({int page = 1, int limit = 20}) {
    return repository.getServices(page: page, limit: limit);
  }
}
