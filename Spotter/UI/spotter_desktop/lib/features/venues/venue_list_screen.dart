import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/venue_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/spotter_drawer.dart';
import '../../widgets/pagination_controls.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/confirm_dialog.dart';
import 'venue_form_screen.dart';

class VenueListScreen extends StatefulWidget {
  const VenueListScreen({super.key});

  @override
  State<VenueListScreen> createState() => _VenueListScreenState();
}

class _VenueListScreenState extends State<VenueListScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _loadData() {
    final provider = context.read<VenueProvider>();
    provider.loadAll(name: _searchController.text);
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final provider = context.read<VenueProvider>();
      provider.setPage(1);
      _loadData();
    });
  }

  Future<void> _deleteVenue(int id) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Venue',
      message: 'Are you sure you want to delete this venue?',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (confirmed && mounted) {
      try {
        await context.read<VenueProvider>().delete(id);
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VenueProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Venues'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VenueFormScreen()),
              );
              if (result == true) {
                final provider = context.read<VenueProvider>();
                provider.setPage(1);
                _searchController.clear();
                _loadData();
              }
            },
          ),
        ],
      ),
      drawer: const SpotterDrawer(currentRoute: 'venues'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search by name',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const LoadingIndicator()
                : provider.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(provider.error!),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadData,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : provider.items.isEmpty
                        ? const EmptyState(
                            icon: Icons.place,
                            message: 'No venues found',
                          )
                        : SingleChildScrollView(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Address')),
                            DataColumn(label: Text('City')),
                            DataColumn(label: Text('Coordinates')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: provider.items.map((venue) {
                            final hasCoords =
                                venue.latitude != null && venue.longitude != null;
                            return DataRow(cells: [
                              DataCell(Text(venue.name)),
                              DataCell(Text(venue.address)),
                              DataCell(Text(venue.cityName)),
                              DataCell(
                                hasCoords
                                    ? Text(
                                        '${venue.latitude!.toStringAsFixed(4)}, ${venue.longitude!.toStringAsFixed(4)}')
                                    : venue.geocodingPending
                                        ? const Chip(
                                            label: Text('Pending'),
                                            backgroundColor: Colors.orange,
                                            labelStyle:
                                                TextStyle(color: Colors.white),
                                          )
                                        : const Text('-'),
                              ),
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              VenueFormScreen(venueId: venue.id),
                                        ),
                                      );
                                      if (result == true) {
                                        _loadData();
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _deleteVenue(venue.id),
                                  ),
                                ],
                              )),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
          ),
          PaginationControls(
            currentPage: provider.currentPage,
            totalCount: provider.totalCount,
            pageSize: provider.pageSize,
            onPrevious: () {
              provider.setPage(provider.currentPage - 1);
              _loadData();
            },
            onNext: () {
              provider.setPage(provider.currentPage + 1);
              _loadData();
            },
          ),
        ],
      ),
    );
  }
}
