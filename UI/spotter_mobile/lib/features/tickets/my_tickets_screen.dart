import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/ticket_provider.dart';
import '../../core/models/ticket_response.dart';
import 'ticket_detail_screen.dart';

class MyTicketsScreen extends StatefulWidget {
  final bool standalone;

  const MyTicketsScreen({super.key, this.standalone = false});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _activeScrollController = ScrollController();
  final _usedScrollController = ScrollController();
  final _cancelledScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _activeScrollController.addListener(
      () => _onScroll(0, _activeScrollController),
    );
    _usedScrollController.addListener(
      () => _onScroll(1, _usedScrollController),
    );
    _cancelledScrollController.addListener(
      () => _onScroll(2, _cancelledScrollController),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TicketProvider>().loadTickets(refresh: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _activeScrollController.dispose();
    _usedScrollController.dispose();
    _cancelledScrollController.dispose();
    super.dispose();
  }

  void _onScroll(int status, ScrollController controller) {
    if (controller.position.pixels >=
        controller.position.maxScrollExtent - 200) {
      final provider = context.read<TicketProvider>();
      if (!provider.isLoadingStatus(status) &&
          provider.hasMoreForStatus(status)) {
        provider.loadTicketsByStatus(status);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketProvider = context.watch<TicketProvider>();

    final content = Column(
      children: [
        if (ticketProvider.isOffline)
          Container(
            color: Colors.orange,
            padding: const EdgeInsets.all(8),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text(
                  'Offline — showing cached tickets',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: 'Active (${ticketProvider.activeTickets.length})'),
            Tab(text: 'Used (${ticketProvider.usedTickets.length})'),
            Tab(text: 'Cancelled (${ticketProvider.cancelledTickets.length})'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTicketList(
                ticketProvider.activeTickets,
                ticketProvider,
                0,
                _activeScrollController,
              ),
              _buildTicketList(
                ticketProvider.usedTickets,
                ticketProvider,
                1,
                _usedScrollController,
              ),
              _buildTicketList(
                ticketProvider.cancelledTickets,
                ticketProvider,
                2,
                _cancelledScrollController,
              ),
            ],
          ),
        ),
      ],
    );

    if (widget.standalone) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Tickets')),
        body: content,
      );
    }

    return content;
  }

  Widget _buildTicketList(
    List<TicketResponse> tickets,
    TicketProvider provider,
    int status,
    ScrollController controller,
  ) {
    if (tickets.isEmpty && provider.isLoadingStatus(status)) {
      return const Center(child: CircularProgressIndicator());
    }

    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.confirmation_number_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No tickets',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadTicketsByStatus(status, refresh: true),
      child: ListView.builder(
        controller: controller,
        padding: const EdgeInsets.all(16),
        itemCount: tickets.length + (provider.isLoadingStatus(status) ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= tickets.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final ticket = tickets[index];
          return _buildTicketCard(ticket);
        },
      ),
    );
  }

  Widget _buildTicketCard(TicketResponse ticket) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TicketDetailScreen(ticketId: ticket.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ticket.eventTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusChip(ticket.status, ticket.statusName),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                ticket.ticketTypeName,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Issued: ${DateFormat('MMM d, yyyy').format(ticket.issuedAt)}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(int status, String statusName) {
    Color color;
    switch (status) {
      case 0:
        color = AppColors.success;
        break;
      case 1:
        color = Colors.blue;
        break;
      case 2:
        color = AppColors.error;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        statusName,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
