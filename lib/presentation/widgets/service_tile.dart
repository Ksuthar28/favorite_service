import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/service.dart';
import '../providers/service_provider.dart';
import 'favorite_icon.dart';

/// A single list item that displays a [Service] with title, body,
/// and a favorite toggle (using [FavoriteIcon]).
class ServiceTile extends ConsumerWidget {
  final Service service;

  const ServiceTile({super.key, required this.service});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(servicesNotifierProvider.notifier);
    final favorites = notifier.favoriteIds;
    final isFavorite = favorites.contains(service.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          service.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          service.body,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14),
        ),
        trailing: FavoriteIcon(
          key: Key('favorite_icon_${service.id}'),
          isFavorite: isFavorite,
          onPressed: () async {
            if (!context.mounted) return;
            await notifier.toggleFavorite(service.id);
          },
        ),
      ),
    );
  }
}
