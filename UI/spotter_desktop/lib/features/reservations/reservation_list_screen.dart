import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/reservation_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/spotter_drawer.dart';
import '../../widgets/pagination_controls.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import 'reservation_detail_screen.dart';

class ReservationListScreen extends StatefulWidget {
  const ReservationListScreen({super.key});

  @override
  State<ReservationListScreen> createState() => _ReservationListScreenState();
}

class _ReservationListScreenState extends State<ReservationListScreen> {
  int? _selectedStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final provider = context.read<ReservationProvider>();
    provider.loadAll(status: _selectedStatus);
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.orange;
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReservationProvider>();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservations'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      drawer: const SpotterDrawer(currentRoute: 'reservations'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<int?>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Filter by status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: 0, child: Text('Pending')),
                DropdownMenuItem(value: 1, child: Text('Confirmed')),
                DropdownMenuItem(value: 2, child: Text('Cancelled')),
                DropdownMenuItem(value: 3, child: Text('Completed')),
              ],
              onChanged: (value) {
                setState(() => _selectedStatus = value);
                final provider = context.read<ReservationProvider>();
                provider.setPage(1);
                _loadData();
              },
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const LoadingIndicator()
                : provider.items.isEmpty
                    ? const EmptyState(
                        icon: Icons.book_online,
                        message: 'No reservations found',
                      )
                    : SingleChildScrollView(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Event')),
                            DataColumn(label: Text('User')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Approved By')),
                            DataColumn(label: Text('Created')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: provider.items.map((reservation) {
                            return DataRow(cells: [
                              DataCell(
                                SizedBox(
                                  width: 200,
                                  child: Text(
                                    reservation.eventTitle,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              DataCell(Text(reservation.userFullName)),
                              DataCell(Chip(
                                label: Text(
                                  reservation.statusName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                backgroundColor:
                                    _getStatusColor(reservation.status),
                              )),
                              DataCell(
                                  Text(reservation.approvedByName ?? '-')),
                              DataCell(Text(
                                  dateFormat.format(reservation.createdAt))),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.visibility),
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ReservationDetailScreen(
                                            reservationId: reservation.id),
                                      ),
                                    );
                                    if (result == true) _loadData();
                                  },
                                ),
                              ),
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
