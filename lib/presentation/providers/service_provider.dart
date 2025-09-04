import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/service_repository_impl.dart';
import '../../domain/entities/service.dart';
import '../../domain/usecases/get_services.dart';
import '../../domain/usecases/toggle_favorite.dart';
import '../notifiers/services_notifier.dart';

/// ---------------------------------------------------------------------------
/// Repository Provider
/// - Provides the concrete repository implementation (API + Hive)
/// - Other providers depend on this
/// ---------------------------------------------------------------------------
final repositoryProvider = Provider<ServiceRepositoryImpl>((ref) {
  return ServiceRepositoryImpl();
});

/// ---------------------------------------------------------------------------
/// GetServices Use Case Provider
/// - Depends on [repositoryProvider]
/// - Handles fetching services from repository with pagination
/// ---------------------------------------------------------------------------
final getServicesProvider = Provider<GetServices>(
  (ref) {
    final repository = ref.watch(repositoryProvider);
    return GetServices(repository);
  },
  dependencies: [repositoryProvider], // ✅ explicitly declare dependency
);

/// ---------------------------------------------------------------------------
/// ToggleFavorite Use Case Provider
/// - Depends on [repositoryProvider]
/// - Handles adding/removing favorites in Hive
/// ---------------------------------------------------------------------------
final toggleFavoriteProvider = Provider<ToggleFavorite>(
  (ref) {
    final repository = ref.watch(repositoryProvider);
    return ToggleFavorite(repository);
  },
  dependencies: [repositoryProvider], // ✅ explicitly declare dependency
);

/// ---------------------------------------------------------------------------
/// ServicesNotifier Provider (StateNotifierProvider)
/// - Depends on [repositoryProvider], [getServicesProvider], [toggleFavoriteProvider]
/// - Exposes AsyncValue<List<Service>> to the UI
/// - Controls fetching, pagination, refreshing, and favorites
/// - Not autoDispose to survive hot restart
/// ---------------------------------------------------------------------------
final servicesNotifierProvider =
    StateNotifierProvider<ServicesNotifier, AsyncValue<List<Service>>>(
      (ref) {
        final getServices = ref.watch(getServicesProvider);
        final toggleFavoriteUseCase = ref.watch(toggleFavoriteProvider);
        final repository = ref.watch(repositoryProvider);

        return ServicesNotifier(
          getServices: getServices,
          toggleFavoriteUseCase: toggleFavoriteUseCase,
          repository: repository,
        );
      },
      dependencies: [
        repositoryProvider,
        getServicesProvider,
        toggleFavoriteProvider,
      ], // ✅ explicitly declare all dependencies
    );
