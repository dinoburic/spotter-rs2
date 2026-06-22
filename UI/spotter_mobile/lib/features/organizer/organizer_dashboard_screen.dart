import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/organizer_provider.dart';

class OrganizerDashboardScreen extends StatefulWidget {
  const OrganizerDashboardScreen({super.key});

  @override
  State<OrganizerDashboardScreen> createState() => _OrganizerDashboardScreenState();
}

class _OrganizerDashboardScreenState extends State<OrganizerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrganizerProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrganizerProvider>();
    final dashboard = provider.dashboard;
    final currencyFormat = NumberFormat.currency(symbol: '', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Organizer Dashboard'),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(provider.error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => provider.loadDashboard(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : dashboard == null
                  ? const Center(child: Text('No data available'))
                  : RefreshIndicator(
                      onRefresh: () => provider.loadDashboard(),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    icon: Icons.attach_money,
                                    label: 'Total Revenue',
                                    value: '${currencyFormat.format(dashboard.totalRevenue)} BAM',
                                    color: AppColors.success,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard(
                                    icon: Icons.confirmation_number,
                                    label: 'Tickets Sold',
                                    value: dashboard.totalTicketsSold.toString(),
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    icon: Icons.event_available,
                                    label: 'Active Events',
                                    value: dashboard.activeEventsCount.toString(),
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard(
                                    icon: Icons.event_note,
                                    label: 'Total Events',
                                    value: dashboard.totalEventsCount.toString(),
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Top Events',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            if (dashboard.topEvents.isEmpty)
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Center(
                                    child: Text(
                                      'No events with sales yet',
                                      style: TextStyle(color: AppColors.textSecondary),
                                    ),
                                  ),
                                ),
                              )
                            else
                              ...dashboard.topEvents.map((event) => Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                        child: const Icon(Icons.event, color: AppColors.primary),
                                      ),
                                      title: Text(
                                        event.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text('${event.ticketsSold} tickets sold'),
                                      trailing: Text(
                                        '${currencyFormat.format(event.revenue)} BAM',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ),
                                  )),
                            const SizedBox(height: 24),
                            Text(
                              'Monthly Revenue',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            if (dashboard.monthlyRevenue.isEmpty)
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Center(
                                    child: Text(
                                      'No revenue data yet',
                                      style: TextStyle(color: AppColors.textSecondary),
                                    ),
                                  ),
                                ),
                              )
                            else
                              Card(
                                child: Column(
                                  children: dashboard.monthlyRevenue.map((item) {
                                    final maxRevenue = dashboard.monthlyRevenue
                                        .map((e) => e.revenue)
                                        .reduce((a, b) => a > b ? a : b);
                                    final ratio = maxRevenue > 0 ? item.revenue / maxRevenue : 0.0;

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                item.monthName,
                                                style: const TextStyle(fontWeight: FontWeight.w500),
                                              ),
                                              Text(
                                                '${currencyFormat.format(item.revenue)} BAM',
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          LinearProgressIndicator(
                                            value: ratio,
                                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${item.ticketsSold} tickets',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
