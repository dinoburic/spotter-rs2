import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/ticket_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/spotter_drawer.dart';
import '../../widgets/pagination_controls.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/confirm_dialog.dart';

class TicketListScreen extends StatefulWidget {
  const TicketListScreen({super.key});

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  int? _selectedStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final provider = context.read<TicketProvider>();
    provider.loadAll(status: _selectedStatus);
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.green;
      case 1:
        return Colors.blue;
      case 2:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _useTicket(String qrCodePayload) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Use Ticket',
      message: 'Are you sure you want to mark this ticket as used?',
      confirmText: 'Confirm',
    );

    if (confirmed && mounted) {
      try {
        await context.read<TicketProvider>().useTicket(qrCodePayload);
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
    final provider = context.watch<TicketProvider>();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tickets'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      drawer: const SpotterDrawer(currentRoute: 'tickets'),
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
                DropdownMenuItem(value: 0, child: Text('Active')),
                DropdownMenuItem(value: 1, child: Text('Used')),
                DropdownMenuItem(value: 2, child: Text('Cancelled')),
              ],
              onChanged: (value) {
                setState(() => _selectedStatus = value);
                final provider = context.read<TicketProvider>();
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
                        icon: Icons.local_activity,
                        message: 'No tickets found',
                      )
                    : SingleChildScrollView(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Event')),
                            DataColumn(label: Text('User')),
                            DataColumn(label: Text('Type')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Issued')),
                            DataColumn(label: Text('Used')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: provider.items.map((ticket) {
                            return DataRow(cells: [
                              DataCell(
                                SizedBox(
                                  width: 200,
                                  child: Text(
                                    ticket.eventTitle,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              DataCell(Text(ticket.userFullName)),
                              DataCell(Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(ticket.ticketTypeName),
                                  Text(
                                    ticket.typeName,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              )),
                              DataCell(Chip(
                                label: Text(
                                  ticket.statusName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                backgroundColor:
                                    _getStatusColor(ticket.status),
                              )),
                              DataCell(
                                  Text(dateFormat.format(ticket.issuedAt))),
                              DataCell(Text(ticket.usedAt != null
                                  ? dateFormat.format(ticket.usedAt!)
                                  : '-')),
                              DataCell(
                                ticket.status == 0
                                    ? IconButton(
                                        icon: const Icon(Icons.qr_code_scanner),
                                        tooltip: 'Mark as Used',
                                        onPressed: () =>
                                            _useTicket(ticket.qrCodePayload),
                                      )
                                    : const SizedBox.shrink(),
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
