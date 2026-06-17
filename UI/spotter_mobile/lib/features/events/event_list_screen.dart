import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/event_provider.dart';
import '../../core/providers/favorite_provider.dart';
import '../../core/providers/recommendation_provider.dart';
import '../../core/models/recommendation_response.dart';
import 'event_card.dart';
import 'event_detail_screen.dart';

class EventListScreen extends StatefulWidget {
  final bool embedded;

  const EventListScreen({super.key, this.embedded = false});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final eventProvider = context.read<EventProvider>();
      eventProvider.loadEvents(refresh: true);
      eventProvider.loadCategories();
      context.read<FavoriteProvider>().loadFavorites();
      context.read<RecommendationProvider>().loadRecommendations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final eventProvider = context.read<EventProvider>();
      if (!eventProvider.isLoading && eventProvider.hasMore) {
        eventProvider.loadEvents();
      }
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<EventProvider>().setSearchQuery(value.isEmpty ? null : value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search events...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        eventProvider.setSearchQuery(null);
                      },
                    )
                  : null,
            ),
            onChanged: _onSearchChanged,
          ),
        ),
        if (eventProvider.categories.isNotEmpty)
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryChip(eventProvider, null, 'All'),
                ...eventProvider.categories.map((category) {
                  return _buildCategoryChip(
                    eventProvider,
                    category.id,
                    category.name,
                    color: AppColors.fromHex(category.colorHex),
                  );
                }),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await eventProvider.loadEvents(refresh: true);
              if (!mounted) return;
              context.read<RecommendationProvider>().loadRecommendations();
            },
            child: eventProvider.items.isEmpty && !eventProvider.isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No events found',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      Consumer<RecommendationProvider>(
                        builder: (context, recProvider, _) {
                          if (recProvider.recommendations.isEmpty) {
                            return const SliverToBoxAdapter(child: SizedBox.shrink());
                          }
                          return SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                  child: Text(
                                    'Recommended for you',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 220,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    itemCount: recProvider.recommendations.length,
                                    itemBuilder: (context, index) {
                                      final rec = recProvider.recommendations[index];
                                      return _RecommendationCard(recommendation: rec);
                                    },
                                  ),
                                ),
                                const Divider(height: 24),
                              ],
                            ),
                          );
                        },
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index >= eventProvider.items.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            final event = eventProvider.items[index];
                            return EventCard(
                              event: event,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EventDetailScreen(eventId: event.id),
                                  ),
                                );
                              },
                            );
                          },
                          childCount: eventProvider.items.length +
                              (eventProvider.isLoading ? 1 : 0),
                        ),
                      ),
                      const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(
    EventProvider provider,
    int? categoryId,
    String label, {
    Color? color,
  }) {
    final isSelected = provider.selectedCategoryId == categoryId;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          provider.setSelectedCategory(categoryId);
        },
        backgroundColor: Colors.white,
        selectedColor: color ?? AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        side: BorderSide(
          color: color ?? AppColors.primary,
          width: isSelected ? 0 : 1,
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final RecommendationResponse recommendation;

  const _RecommendationCard({required this.recommendation});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EventDetailScreen(eventId: recommendation.eventId),
        ),
      ),
      child: Container(
        width: 180,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (recommendation.coverImageUrl != null)
                CachedNetworkImage(
                  imageUrl: recommendation.coverImageUrl!,
                  height: 110,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    height: 110,
                    color: AppColors.fromHex(recommendation.categoryColorHex)
                        .withValues(alpha:0.3),
                    child: const Icon(Icons.event),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      recommendation.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      recommendation.explanation,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.fromHex(recommendation.categoryColorHex),
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
