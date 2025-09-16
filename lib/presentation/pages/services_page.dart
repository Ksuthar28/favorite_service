import 'package:favorite_service/core/utils/debouncer.dart';
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
  late Debouncer _debouncer;

  @override
  void initState() {
    super.initState();

    _debouncer = Debouncer();
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
    _debouncer.dispose();
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
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: Strings.searchService,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (query) {
                    _debouncer.run(() {
                      ref
                          .read(servicesNotifierProvider.notifier)
                          .applyFilter(query);
                    });
                  },
                ),
                const SizedBox(height: 8),
                // Recent searches list
                Consumer(
                  builder: (context, ref, _) {
                    final recent = ref
                        .watch(servicesNotifierProvider.notifier)
                        .recentSearches;

                    if (recent.isEmpty) return const SizedBox.shrink();

                    return Wrap(
                      spacing: 8,
                      children: recent.map((term) {
                        return ActionChip(
                          label: Text(term),
                          onPressed: () {
                            // When clicked, re-apply filter
                            ref
                                .read(servicesNotifierProvider.notifier)
                                .applyFilter(term);
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: All services with bottom loader for pagination
                servicesState.when(
                  data: (services) {
                    // 👇 Ensure first item category is set
                    final notifier = ref.read(
                      servicesNotifierProvider.notifier,
                    );
                    if (notifier.searchQuery.trim().isEmpty &&
                        services.isEmpty) {
                      return const Center(child: Text(Strings.loadingMessage));
                    }
                    if (notifier.searchQuery.trim().isNotEmpty &&
                        services.isEmpty) {
                      return const Center(child: Text(Strings.noServiceFound));
                    }
                    //handle category header
                    final grouped = <String, List<Service>>{};
                    for (final service in services) {
                      grouped.putIfAbsent(service.body, () => []);
                      grouped[service.body]!.add(service);
                    }

                    return RefreshIndicator(
                      onRefresh: () =>
                          ref.read(servicesNotifierProvider.notifier).refresh(),
                      child: CustomScrollView(
                        slivers: [
                          for (final entry in grouped.entries) ...[
                            SliverMainAxisGroup(
                              slivers: [
                                PinnedHeaderSliver(
                                  child: Container(
                                    color: Theme.of(
                                      context,
                                    ).scaffoldBackgroundColor,
                                    // height: 80,
                                    padding: const EdgeInsets.all(16),
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      entry.key,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                SliverList(
                                  delegate: SliverChildBuilderDelegate((
                                    context,
                                    index,
                                  ) {
                                    return ServiceTile(
                                      service: entry.value[index],
                                    );
                                  }, childCount: entry.value.length),
                                ),
                              ],
                            ),
                          ],
                        ],
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
          ),
        ],
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _StickyHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
