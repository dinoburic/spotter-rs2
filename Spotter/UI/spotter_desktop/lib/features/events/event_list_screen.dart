import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/event_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/spotter_drawer.dart';
import '../../widgets/pagination_controls.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/confirm_dialog.dart';
import 'event_form_screen.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
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
    final provider = context.read<EventProvider>();
    provider.loadAll(title: _searchController.text);
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final provider = context.read<EventProvider>();
      provider.setPage(1);
      _loadData();
    });
  }

  Future<void> _deleteEvent(int id) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Event',
      message: 'Are you sure you want to delete this event?',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (confirmed && mounted) {
      try {
        await context.read<EventProvider>().delete(id);
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

  Color _getStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.grey;
      case 1:
        return Colors.green;
      case 2:
        return Colors.red;
      case 3:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventProvider>();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EventFormScreen()),
              );
              if (result == true) _loadData();
            },
          ),
        ],
      ),
      drawer: const SpotterDrawer(currentRoute: 'events'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search by title',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const LoadingIndicator()
                : provider.items.isEmpty
                    ? const EmptyState(
                        icon: Icons.event,
                        message: 'No events found',
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Title')),
                            DataColumn(label: Text('Category')),
                            DataColumn(label: Text('Venue')),
                            DataColumn(label: Text('Starts')),
                            DataColumn(label: Text('Capacity')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: provider.items.map((event) {
                            return DataRow(cells: [
                              DataCell(
                                SizedBox(
                                  width: 200,
                                  child: Text(
                                    event.title,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color:
                                          _parseColor(event.categoryColorHex),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(event.categoryName),
                                ],
                              )),
                              DataCell(Text(event.venueName)),
                              DataCell(Text(dateFormat.format(event.startsAt))),
                              DataCell(Text(
                                  '${event.availableCapacity}/${event.totalCapacity}')),
                              DataCell(Chip(
                                label: Text(
                                  event.statusName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                backgroundColor: _getStatusColor(event.status),
                              )),
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EventFormScreen(
                                              eventId: event.id),
                                        ),
                                      );
                                      if (result == true) _loadData();
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _deleteEvent(event.id),
                                  ),
                                ],
                              )),
                            ]);
                          }).toList(),
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
