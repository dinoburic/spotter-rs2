import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/auth_provider.dart';
import '../core/constants/app_colors.dart';
import '../features/auth/login_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/users/user_list_screen.dart';
import '../features/cities/city_list_screen.dart';
import '../features/categories/category_list_screen.dart';
import '../features/venues/venue_list_screen.dart';
import '../features/events/event_list_screen.dart';
import '../features/ticket_types/ticket_type_list_screen.dart';
import '../features/orders/order_list_screen.dart';
import '../features/tickets/ticket_list_screen.dart';
import '../features/tickets/ticket_scanner_screen.dart';
import '../features/reservations/reservation_list_screen.dart';
import '../features/reviews/review_list_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/settings/settings_screen.dart';
import 'confirm_dialog.dart';

class SpotterDrawer extends StatelessWidget {
  final String currentRoute;

  const SpotterDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Drawer(
      child: Column(
        children: [
          Container(
          width: double.infinity,
          decoration: const BoxDecoration(color: AppColors.primary),
          padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
          child: Column(
            children: [
              Image.asset(
                'assets/images/spotter_logo.jpg',
                height: 72,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 12),
              Text(
                auth.username,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                auth.role,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildSectionHeader(context, 'Overview'),
                _buildNavItem(
                  context,
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  route: 'dashboard',
                  screen: const DashboardScreen(),
                ),
                const Divider(),
                _buildSectionHeader(context, 'Management'),
                _buildNavItem(
                  context,
                  icon: Icons.people,
                  title: 'Users',
                  route: 'users',
                  screen: const UserListScreen(),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.location_city,
                  title: 'Cities',
                  route: 'cities',
                  screen: const CityListScreen(),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.category,
                  title: 'Categories',
                  route: 'categories',
                  screen: const CategoryListScreen(),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.place,
                  title: 'Venues',
                  route: 'venues',
                  screen: const VenueListScreen(),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.event,
                  title: 'Events',
                  route: 'events',
                  screen: const EventListScreen(),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.confirmation_number,
                  title: 'Ticket Types',
                  route: 'ticket_types',
                  screen: const TicketTypeListScreen(),
                ),
                const Divider(),
                _buildSectionHeader(context, 'Operations'),
                _buildNavItem(
                  context,
                  icon: Icons.shopping_cart,
                  title: 'Orders',
                  route: 'orders',
                  screen: const OrderListScreen(),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.local_activity,
                  title: 'Tickets',
                  route: 'tickets',
                  screen: const TicketListScreen(),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.qr_code_scanner,
                  title: 'Ticket Scanner',
                  route: 'scanner',
                  screen: const TicketScannerScreen(),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.book_online,
                  title: 'Reservations',
                  route: 'reservations',
                  screen: const ReservationListScreen(),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.star,
                  title: 'Reviews',
                  route: 'reviews',
                  screen: const ReviewListScreen(),
                ),
                const Divider(),
                _buildSectionHeader(context, 'Reports'),
                _buildNavItem(
                  context,
                  icon: Icons.assessment,
                  title: 'Reports',
                  route: 'reports',
                  screen: const ReportsScreen(),
                ),
                const Divider(),
                _buildSectionHeader(context, 'Configuration'),
                _buildNavItem(
                  context,
                  icon: Icons.settings,
                  title: 'Settings',
                  route: 'settings',
                  screen: const SettingsScreen(),
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              final confirmed = await showConfirmDialog(
                context,
                title: 'Logout',
                message: 'Are you sure you want to logout?',
                confirmText: 'Logout',
                isDestructive: true,
              );
              if (confirmed && context.mounted) {
                await auth.logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              }
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    required Widget screen,
  }) {
    final isSelected = currentRoute == route;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primary : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primary : null,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
      onTap: () {
        Navigator.pop(context);
        if (!isSelected) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => screen),
          );
        }
      },
    );
  }
}
