import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants/strings.dart';
import '../../domain/entities/service.dart';
import '../../domain/repositories/service_repository.dart';
import '../remote/service_api.dart';

/// Concrete implementation of [ServiceRepository].
/// - Fetches services from API
/// - Persists favorites locally using Hive
class ServiceRepositoryImpl implements ServiceRepository {
  final ServiceApi _api = ServiceApi();

  /// Ensures the favorites box is open before using it.
  Future<Box<int>> _openFavoritesBox() async {
    if (!Hive.isBoxOpen(Strings.favorites)) {
      return await Hive.openBox<int>(Strings.favorites);
    }
    return Hive.box<int>(Strings.favorites);
  }

  /// Fetch services from API and convert to entity
  @override
  Future<List<Service>> getServices({int page = 1, int limit = 20}) async {
    final models = await _api.fetchServices(page: page, limit: limit);
    return models.map((m) => m.toEntity()).toList();
  }

  /// Toggle favorite/unfavorite for a given service ID
  /// - Stores the ID as key & value for simplicity
  @override
  Future<void> toggleFavorite(int id) async {
    final box = await _openFavoritesBox();

    if (box.containsKey(id)) {
      await box.delete(id);
    } else {
      await box.put(id, id);
    }
  }

  /// Async version of getFavoriteIds
  /// - Ensures Hive box is opened
  Future<Set<int>> getFavoriteIdsAsync() async {
    final box = await _openFavoritesBox();
    return box.values.toSet();
  }

  /// Synchronous version (kept for backward compatibility)
  /// - Returns empty set if box is not opened yet
  @override
  Set<int> getFavoriteIds() {
    if (!Hive.isBoxOpen(Strings.favorites)) return {};
    final box = Hive.box<int>(Strings.favorites);
    return box.values.toSet();
  }
}
