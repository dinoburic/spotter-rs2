import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/event_provider.dart';
import '../../core/providers/favorite_provider.dart';
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
    final eventProvider = context.read<EventProvider>();
    eventProvider.loadEvents(refresh: true);
    eventProvider.loadCategories();
    context.read<FavoriteProvider>().loadFavorites();

    _scrollController.addListener(_onScroll);
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
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: eventProvider.items.length +
                        (eventProvider.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
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
                              builder: (_) =>
                                  EventDetailScreen(eventId: event.id),
                            ),
                          );
                        },
                      );
                    },
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
