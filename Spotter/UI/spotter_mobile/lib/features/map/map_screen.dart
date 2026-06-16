import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/event_provider.dart';
import '../../core/models/event_response.dart';
import '../events/event_detail_screen.dart';
import '../events/event_list_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  bool _isMapView = true;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final eventProvider = context.read<EventProvider>();
      eventProvider.loadMapEvents();
      eventProvider.loadCategories();
    });
  }

  Future<void> _centerOnUser() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied ||
            requested == LocationPermission.deniedForever) {
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition();
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        13,
      );
    } catch (_) {}
  }

  List<EventResponse> _filterEvents(List<EventResponse> events) {
    if (_selectedCategoryId == null) return events;
    return events.where((e) => e.categoryId == _selectedCategoryId).toList();
  }

  void _showEventBottomSheet(EventResponse event) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                ],
              ),
              const SizedBox(height: 12),
              Text(
                event.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${event.venueName}${event.cityName != null ? ', ${event.cityName}' : ''}',
                      style: TextStyle(color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(event.startsAt),
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventDetailScreen(eventId: event.id),
                      ),
                    );
                  },
                  child: const Text('View Details'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day} · $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();
    final filteredEvents = _filterEvents(eventProvider.mapItems);

    if (!_isMapView) {
      return const EventListScreen(embedded: true);
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: const LatLng(43.9, 17.6),
            initialZoom: 7,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.spotter.mobile',
            ),
            MarkerLayer(
              markers: filteredEvents.where((event) => 
          event.venueLatitude != null && 
          event.venueLongitude != null).map((event) {
                return Marker(
                  point: LatLng(event.venueLatitude!, event.venueLongitude!),
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onTap: () => _showEventBottomSheet(event),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.fromHex(event.categoryColorHex),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha:0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.event,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Column(
            children: [
              if (eventProvider.categories.isNotEmpty)
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildCategoryChip(null, 'All'),
                      ...eventProvider.categories.map((category) {
                        return _buildCategoryChip(
                          category.id,
                          category.name,
                          color: AppColors.fromHex(category.colorHex),
                        );
                      }),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              const SizedBox(height: 44),
              FloatingActionButton.small(
                heroTag: 'toggle',
                onPressed: () => setState(() => _isMapView = !_isMapView),
                backgroundColor: Colors.white,
                child: Icon(
                  _isMapView ? Icons.list : Icons.map,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'location',
            onPressed: _centerOnUser,
            backgroundColor: Colors.white,
            child: const Icon(
              Icons.my_location,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(int? categoryId, String label, {Color? color}) {
    final isSelected = _selectedCategoryId == categoryId;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _selectedCategoryId = categoryId);
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
