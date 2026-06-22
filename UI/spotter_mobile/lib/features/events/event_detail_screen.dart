import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/event_provider.dart';
import '../../core/providers/favorite_provider.dart';
import '../../core/providers/review_provider.dart';
import '../../core/providers/friendship_provider.dart';
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
  String? _distanceKm;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEvent();
    });
  }

  Future<void> _loadEvent() async {
    final eventProvider = context.read<EventProvider>();
    final event = await eventProvider.getEventById(widget.eventId);
    if (!mounted) return;
    if (event != null) {
      await eventProvider.loadTicketTypes(widget.eventId);
      if (!mounted) return;
      await context.read<ReviewProvider>().loadReviewsForEvent(widget.eventId);
      if (!mounted) return;
      await context.read<FriendshipProvider>().loadFriendsAttending(widget.eventId);
      if (!mounted) return;
      _calculateDistance(event);
    }
    if (!mounted) return;
    setState(() {
      _event = event;
      _isLoading = false;
    });
  }

  Future<void> _calculateDistance(EventResponse event) async {
    if (event.venueLatitude == null || event.venueLongitude == null) return;

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      final distanceMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        event.venueLatitude!,
        event.venueLongitude!,
      );

      if (!mounted) return;
      setState(() {
        _distanceKm = (distanceMeters / 1000).toStringAsFixed(1);
      });
    } catch (_) {}
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('EEEE, MMMM d, yyyy · HH:mm').format(date);
  }

  Future<void> _showReservationDialog() async {
    final eventProvider = context.read<EventProvider>();
    final ticketTypes = eventProvider.ticketTypes;
    if (ticketTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No ticket types available for this event.')),
      );
      return;
    }
    int? selectedTicketTypeId = ticketTypes.first.id;
    int quantity = 1;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Reserve Spot'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ticket type:'),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: selectedTicketTypeId,
                isExpanded: true,
                items: ticketTypes.map((tt) {
                  return DropdownMenuItem(
                    value: tt.id,
                    child: Text('${tt.name} (${tt.price.toStringAsFixed(2)} BAM)'),
                  );
                }).toList(),
                onChanged: (val) => setDialogState(() => selectedTicketTypeId = val),
              ),
              const SizedBox(height: 16),
              const Text('Quantity:'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: quantity > 1 ? () => setDialogState(() => quantity--) : null,
                  ),
                  Text('$quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: quantity < 10 ? () => setDialogState(() => quantity++) : null,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'This reservation holds your spot for 15 minutes.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reserve')),
          ],
        ),
      ),
    );
    if (confirmed == true && mounted && selectedTicketTypeId != null) {
      _createReservation(selectedTicketTypeId!, quantity);
    }
  }

  Future<void> _createReservation(int ticketTypeId, int quantity) async {
    final reservationProvider = context.read<ReservationProvider>();
    final request = ReservationInsertRequest(
      eventId: widget.eventId,
      ticketTypeId: ticketTypeId,
      quantity: quantity,
    );
    final result = await reservationProvider.createReservation(request);
    if (!mounted) return;
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reservation created! Complete checkout within 15 minutes.'),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (reservationProvider.error != null) {
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
                            .withValues(alpha:0.3),
                        child: const Icon(Icons.event, size: 64),
                      ),
                    )
                  : Container(
                      color: AppColors.fromHex(event.categoryColorHex)
                          .withValues(alpha:0.3),
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
                  if (_distanceKm != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.near_me, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '$_distanceKm km away',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
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
                  Consumer<FriendshipProvider>(
                    builder: (context, friendProvider, _) {
                      if (friendProvider.friendsAttending.isEmpty) {
                        return const SizedBox();
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(height: 32),
                          Text(
                            '${friendProvider.friendsAttending.length} friend(s) attending',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 50,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: friendProvider.friendsAttending.length,
                              itemBuilder: (context, index) {
                                final friend = friendProvider.friendsAttending[index];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Tooltip(
                                    message: friend.fullName,
                                    child: CircleAvatar(
                                      radius: 22,
                                      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                                      child: Text(
                                        friend.fullName.isNotEmpty ? friend.fullName[0].toUpperCase() : '?',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
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
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              '${ticketType.availableQuantity} left',
                              style: TextStyle(
                                color: ticketType.availableQuantity > 0
                                    ? AppColors.success
                                    : AppColors.error,
                                fontSize: 7,
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
              OutlinedButton(
                onPressed: _showReservationDialog,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                child: const Text(
                  'Reserve',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
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
