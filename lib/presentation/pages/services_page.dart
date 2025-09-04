import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/strings.dart';
import '../../domain/entities/service.dart';
import '../providers/service_provider.dart';
import '../widgets/service_tile.dart';

/// Main screen showing tabbed view of all services and favorites
class ServicesPage extends ConsumerStatefulWidget {
  const ServicesPage({super.key});

  @override
  ConsumerState<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends ConsumerState<ServicesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);

    // Listen for scroll to trigger pagination
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(servicesNotifierProvider.notifier).fetchNextPage();
      }
    });

    // Initial fetch handled by ServicesNotifier constructor
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final servicesState = ref.watch(servicesNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(Strings.appTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: Strings.tabAll),
            Tab(text: Strings.tabFavorites),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: All services with bottom loader for pagination
          servicesState.when(
            data: (services) {
              if (services.isEmpty) {
                return const Center(child: Text(Strings.loadingMessage));
              }

              return RefreshIndicator(
                onRefresh: () =>
                    ref.read(servicesNotifierProvider.notifier).refresh(),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: services.length + 1, // extra item for loader
                  itemBuilder: (context, index) {
                    final notifier = ref.read(
                      servicesNotifierProvider.notifier,
                    );

                    if (index < services.length) {
                      // Normal service item
                      final Service service = services[index];
                      return ServiceTile(service: service);
                    } else {
                      // Bottom loader item
                      return notifier.isFetching
                          ? const Padding(
                              key: Key('bottom_loader'),
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: CircularProgressIndicator.adaptive(),
                              ),
                            )
                          : const SizedBox.shrink();
                    }
                  },
                ),
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator.adaptive()),
            error: (error, _) =>
                Center(child: Text('${Strings.errorMessage}\n$error')),
          ),

          // Tab 2: Favorites (filtered locally)
          servicesState.when(
            data: (services) {
              final favorites = ref
                  .read(servicesNotifierProvider.notifier)
                  .getFavoriteServices(services);

              if (favorites.isEmpty) {
                return const Center(child: Text(Strings.noFavorites));
              }
              return ListView.builder(
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final Service service = favorites[index];
                  return ServiceTile(service: service);
                },
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator.adaptive()),
            error: (error, _) =>
                Center(child: Text('${Strings.errorMessage}\n$error')),
          ),
        ],
      ),
    );
  }
}
