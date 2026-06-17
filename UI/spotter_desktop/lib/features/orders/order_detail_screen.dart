import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/order_provider.dart';
import '../../core/models/order_response.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/confirm_dialog.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  OrderResponse? _order;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      _order = await context.read<OrderProvider>().getById(widget.orderId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markAsPaid() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Mark as Paid',
      message: 'Are you sure you want to mark this order as paid?',
      confirmText: 'Confirm',
    );

    if (confirmed && mounted) {
      try {
        await context.read<OrderProvider>().markAsPaid(widget.orderId);
        Navigator.pop(context, true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
  }

  Future<void> _refund() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Refund Order',
      message: 'Are you sure you want to refund this order?',
      confirmText: 'Refund',
      isDestructive: true,
    );

    if (confirmed && mounted) {
      try {
        await context.read<OrderProvider>().refund(widget.orderId);
        Navigator.pop(context, true);
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
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${widget.orderId}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _order == null
              ? const Center(child: Text('Order not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Order Details',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const Spacer(),
                                  Chip(
                                    label: Text(
                                      _order!.statusName,
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor:
                                        _getStatusColor(_order!.status),
                                  ),
                                ],
                              ),
                              const Divider(),
                              _buildInfoRow('Event', _order!.eventTitle),
                              _buildInfoRow('User', _order!.userFullName),
                              _buildInfoRow('Created',
                                  dateFormat.format(_order!.createdAt)),
                              _buildInfoRow('Total Amount',
                                  '${_order!.totalAmount.toStringAsFixed(2)} BAM'),
                              if (_order!.spotterPointsRedeemed > 0)
                                _buildInfoRow('Points Redeemed',
                                    '${_order!.spotterPointsRedeemed}'),
                              if (_order!.discountApplied > 0)
                                _buildInfoRow('Discount Applied',
                                    '${_order!.discountApplied.toStringAsFixed(2)} BAM'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order Items',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const Divider(),
                              ..._order!.items.map((item) => Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.ticketTypeName,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              Text(
                                                item.typeName,
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            'x${item.quantity}',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            '${item.unitPrice.toStringAsFixed(2)} BAM',
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            '${item.subtotal.toStringAsFixed(2)} BAM',
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_order!.status == 0)
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _markAsPaid,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text('Mark as Paid'),
                              ),
                            ),
                          ],
                        ),
                      if (_order!.status == 1)
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _refund,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text('Refund Order'),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
