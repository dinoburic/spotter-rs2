import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/recommendation_provider.dart';
import '../../core/constants/app_colors.dart';
import '../events/event_detail_screen.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecommendationProvider>().loadRecommendations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommended for You'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<RecommendationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(provider.error!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadRecommendations(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.recommendations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No recommendations yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Purchase tickets or set your interests\nto get personalized recommendations',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadRecommendations(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.recommendations.length,
              itemBuilder: (context, index) {
                final rec = provider.recommendations[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventDetailScreen(eventId: rec.eventId),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (rec.coverImageUrl != null)
                          Image.network(
                            rec.coverImageUrl!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 100,
                              height: 100,
                              color: AppColors.fromHex(rec.categoryColorHex).withValues(alpha: 0.3),
                              child: const Icon(Icons.event, size: 40),
                            ),
                          ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.fromHex(rec.categoryColorHex),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    rec.categoryName,
                                    style: const TextStyle(color: Colors.white, fontSize: 10),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  rec.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  rec.venueName,
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  rec.explanation,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.fromHex(rec.categoryColorHex),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
