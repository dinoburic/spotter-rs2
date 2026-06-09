import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/event_provider.dart';
import '../../core/providers/favorite_provider.dart';
import '../../core/providers/review_provider.dart';
import '../../core/models/event_response.dart';
import '../../core/models/reservation_insert_request.dart';
import '../../core/providers/reservation_provider.dart';
import '../orders/checkout_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final int eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  EventResponse? _event;
  bool _isLoading = true;
  bool _isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    final eventProvider = context.read<EventProvider>();
    final event = await eventProvider.getEventById(widget.eventId);
    if (event != null) {
      await eventProvider.loadTicketTypes(widget.eventId);
      await context.read<ReviewProvider>().loadReviewsForEvent(widget.eventId);
    }
    setState(() {
      _event = event;
      _isLoading = false;
    });
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('EEEE, MMMM d, yyyy · HH:mm').format(date);
  }

  Future<void> _createReservation() async {
    final reservationProvider = context.read<ReservationProvider>();
    final request = ReservationInsertRequest(eventId: widget.eventId);
    final result = await reservationProvider.createReservation(request);

    if (mounted && result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reservation created successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (mounted && reservationProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(reservationProvider.error!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();
    final favoriteProvider = context.watch<FavoriteProvider>();
    final reviewProvider = context.watch<ReviewProvider>();

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_event == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Event not found')),
      );
    }

    final event = _event!;
    final isFavorite = favoriteProvider.isFavorite(event.id);
    final isSoldOut = event.availableCapacity == 0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: event.coverImageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: event.coverImageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.fromHex(event.categoryColorHex)
                            .withOpacity(0.3),
                        child: const Icon(Icons.event, size: 64),
                      ),
                    )
                  : Container(
                      color: AppColors.fromHex(event.categoryColorHex)
                          .withOpacity(0.3),
                      child: const Center(
                        child: Icon(Icons.event, size: 64),
                      ),
                    ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? AppColors.error : Colors.white,
                ),
                onPressed: () => favoriteProvider.toggleFavorite(event.id),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.fromHex(event.categoryColorHex),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          event.categoryName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(event.status),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          event.statusName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Organized by ${event.organizerName}',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const Divider(height: 32),
                  _buildInfoRow(Icons.calendar_today_outlined, 'Date & Time',
                      _formatDateTime(event.startsAt)),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    Icons.location_on_outlined,
                    'Venue',
                    [
                      if (event.venueName.isNotEmpty) event.venueName,
                      if (event.cityName != null && event.cityName!.isNotEmpty) event.cityName!,
                    ].join(', '),
                  ),
                  if (event.venueLatitude != null &&
                      event.venueLongitude != null) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 150,
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(
                              event.venueLatitude!,
                              event.venueLongitude!,
                            ),
                            initialZoom: 15,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.none,
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.spotter.mobile',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(
                                    event.venueLatitude!,
                                    event.venueLongitude!,
                                  ),
                                  child: Icon(
                                    Icons.location_on,
                                    color: AppColors.primary,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (event.description != null) ...[
                    const Divider(height: 32),
                    Text(
                      'About',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.description!,
                      maxLines: _isDescriptionExpanded ? null : 4,
                      overflow: _isDescriptionExpanded
                          ? null
                          : TextOverflow.ellipsis,
                    ),
                    if (event.description!.length > 200)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isDescriptionExpanded = !_isDescriptionExpanded;
                          });
                        },
                        child: Text(
                          _isDescriptionExpanded ? 'Show less' : 'Show more',
                        ),
                      ),
                  ],
                  const Divider(height: 32),
                  Text(
                    'Tickets',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ...eventProvider.ticketTypes.map((ticketType) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(ticketType.name),
                        subtitle: Text(ticketType.typeName),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${ticketType.price.toStringAsFixed(2)} BAM',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${ticketType.availableQuantity} left',
                              style: TextStyle(
                                color: ticketType.availableQuantity > 0
                                    ? AppColors.success
                                    : AppColors.error,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  if (reviewProvider.reviews.isNotEmpty) ...[
                    const Divider(height: 32),
                    Text(
                      'Reviews',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    ...reviewProvider.reviews.take(3).map((review) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    review.userFullName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  ...List.generate(5, (i) {
                                    return Icon(
                                      i < review.rating
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Colors.amber,
                                      size: 16,
                                    );
                                  }),
                                ],
                              ),
                              if (review.comment != null) ...[
                                const SizedBox(height: 8),
                                Text(review.comment!),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _createReservation,
                  child: const Text('Reserve'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: isSoldOut
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CheckoutScreen(event: event),
                            ),
                          );
                        },
                  child: Text(isSoldOut ? 'Sold Out' : 'Buy Tickets'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.grey;
      case 1:
        return AppColors.success;
      case 2:
        return AppColors.error;
      case 3:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
