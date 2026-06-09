import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/favorite_provider.dart';
import '../events/event_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<FavoriteProvider>().loadFavorites();
  }

  Future<void> _removeFavorite(int eventId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Favorite'),
        content: const Text('Are you sure you want to remove this event from your favorites?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<FavoriteProvider>().toggleFavorite(eventId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final favoriteProvider = context.watch<FavoriteProvider>();

    if (favoriteProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (favoriteProvider.favorites.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_outline,
                size: 64,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                'No favorites yet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Explore events to add some!',
                style: TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => favoriteProvider.loadFavorites(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: favoriteProvider.favorites.length,
        itemBuilder: (context, index) {
          final favorite = favoriteProvider.favorites[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EventDetailScreen(eventId: favorite.eventId),
                  ),
                );
              },
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: favorite.eventCoverImageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: favorite.eventCoverImageUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              color: AppColors.fromHex(favorite.categoryColorHex)
                                  .withOpacity(0.2),
                              child: const Icon(Icons.event),
                            ),
                          )
                        : Container(
                            color: AppColors.fromHex(favorite.categoryColorHex)
                                .withOpacity(0.2),
                            child: Icon(
                              Icons.event,
                              color: AppColors.fromHex(favorite.categoryColorHex),
                            ),
                          ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.fromHex(favorite.categoryColorHex),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              favorite.categoryName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            favorite.eventTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('EEE, MMM d · HH:mm')
                                .format(favorite.eventStartsAt),
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.favorite, color: AppColors.error),
                    onPressed: () => _removeFavorite(favorite.eventId),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
