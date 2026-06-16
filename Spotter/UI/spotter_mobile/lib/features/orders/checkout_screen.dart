import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/event_provider.dart';
import '../../core/providers/order_provider.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/providers/payment_provider.dart';
import '../../core/models/event_response.dart';
import '../../core/models/order_insert_request.dart';
import '../home/home_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final EventResponse event;

  const CheckoutScreen({super.key, required this.event});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final Map<int, int> _quantities = {};
  bool _usePoints = false;
  int _pointsBalance = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPointsBalance();
    });
  }

  Future<void> _loadPointsBalance() async {
    final profileProvider = context.read<ProfileProvider>();
    await profileProvider.loadPointsBalance();
    if (mounted && profileProvider.pointsBalance != null) {
      setState(() {
        _pointsBalance = profileProvider.pointsBalance!.balance;
      });
    }
  }

  double get _subtotal {
    final eventProvider = context.read<EventProvider>();
    double total = 0;
    for (final entry in _quantities.entries) {
      final ticketType = eventProvider.ticketTypes
          .firstWhere((t) => t.id == entry.key);
      total += ticketType.price * entry.value;
    }
    return total;
  }

  double get _discount {
    if (!_usePoints || _pointsBalance == 0) return 0;
    final maxDiscount = _pointsBalance * 0.1;
    return maxDiscount > _subtotal ? _subtotal : maxDiscount;
  }

  double get _total => _subtotal - _discount;

  int get _totalItems {
    return _quantities.values.fold(0, (sum, qty) => sum + qty);
  }

  Future<void> _processOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Order'),
        content: Text(
          'Total: ${_total.toStringAsFixed(2)} BAM\n\nProceed to payment?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Pay Now'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final items = _quantities.entries
        .where((e) => e.value > 0)
        .map((e) => OrderItemRequest(
              ticketTypeId: e.key,
              quantity: e.value,
            ))
        .toList();

    final request = OrderInsertRequest(
      eventId: widget.event.id,
      items: items,
      spotterPointsToRedeem: _usePoints ? _pointsBalance : 0,
    );

    final orderProvider = context.read<OrderProvider>();
    final paymentProvider = context.read<PaymentProvider>();

    final order = await orderProvider.createOrder(request);
    if (order == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(orderProvider.error ?? 'Failed to create order'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    final paymentSuccess = await paymentProvider.processPayment(order.id);

    if (!mounted) return;

    if (paymentSuccess) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment successful! Your tickets have been issued.'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(paymentProvider.error ?? 'Payment failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.event.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.event.venueName,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select Tickets',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...eventProvider.ticketTypes.map((ticketType) {
                  final quantity = _quantities[ticketType.id] ?? 0;
                  final maxQuantity = ticketType.availableQuantity > 10
                      ? 10
                      : ticketType.availableQuantity;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ticketType.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${ticketType.price.toStringAsFixed(2)} BAM',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${ticketType.availableQuantity} available',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: quantity > 0
                                    ? () {
                                        setState(() {
                                          _quantities[ticketType.id] =
                                              quantity - 1;
                                        });
                                      }
                                    : null,
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              SizedBox(
                                width: 32,
                                child: Text(
                                  '$quantity',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: quantity < maxQuantity
                                    ? () {
                                        setState(() {
                                          _quantities[ticketType.id] =
                                              quantity + 1;
                                        });
                                      }
                                    : null,
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                if (_pointsBalance > 0) ...[
                  const Divider(height: 32),
                  Card(
                    color: AppColors.primary.withValues(alpha:0.1),
                    child: SwitchListTile(
                      title: const Text('Use Spotter Points'),
                      subtitle: Text(
                        'Balance: $_pointsBalance points (${(_pointsBalance * 0.1).toStringAsFixed(2)} BAM)',
                      ),
                      value: _usePoints,
                      onChanged: _totalItems > 0
                          ? (value) => setState(() => _usePoints = value)
                          : null,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal'),
                      Text('${_subtotal.toStringAsFixed(2)} BAM'),
                    ],
                  ),
                  if (_discount > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Points Discount',
                          style: TextStyle(color: AppColors.success),
                        ),
                        Text(
                          '-${_discount.toStringAsFixed(2)} BAM',
                          style: const TextStyle(color: AppColors.success),
                        ),
                      ],
                    ),
                  ],
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        '${_total.toStringAsFixed(2)} BAM',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Consumer<PaymentProvider>(
                    builder: (context, paymentProvider, child) {
                      final isProcessing = orderProvider.isLoading || paymentProvider.isLoading;
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _totalItems > 0 && !isProcessing
                              ? _processOrder
                              : null,
                          child: isProcessing
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Pay Now'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
