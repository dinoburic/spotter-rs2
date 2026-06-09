import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/order_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/spotter_drawer.dart';
import '../../widgets/pagination_controls.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import 'order_detail_screen.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  int? _selectedStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final provider = context.read<OrderProvider>();
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
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      drawer: const SpotterDrawer(currentRoute: 'orders'),
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
                DropdownMenuItem(value: 1, child: Text('Paid')),
                DropdownMenuItem(value: 2, child: Text('Refunded')),
              ],
              onChanged: (value) {
                setState(() => _selectedStatus = value);
                final provider = context.read<OrderProvider>();
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
                        icon: Icons.shopping_cart,
                        message: 'No orders found',
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Order #')),
                            DataColumn(label: Text('Event')),
                            DataColumn(label: Text('User')),
                            DataColumn(label: Text('Amount')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Created')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: provider.items.map((order) {
                            return DataRow(cells: [
                              DataCell(Text('#${order.id}')),
                              DataCell(
                                SizedBox(
                                  width: 200,
                                  child: Text(
                                    order.eventTitle,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              DataCell(Text(order.userFullName)),
                              DataCell(Text(
                                  '${order.totalAmount.toStringAsFixed(2)} BAM')),
                              DataCell(Chip(
                                label: Text(
                                  order.statusName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                backgroundColor: _getStatusColor(order.status),
                              )),
                              DataCell(
                                  Text(dateFormat.format(order.createdAt))),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.visibility),
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            OrderDetailScreen(orderId: order.id),
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
