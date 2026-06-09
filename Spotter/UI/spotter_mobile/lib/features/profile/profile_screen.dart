import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/profile_provider.dart';
import '../auth/login_screen.dart';
import '../orders/order_history_screen.dart';
import '../reservations/my_reservations_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final profileProvider = context.read<ProfileProvider>();
    profileProvider.loadProfile(auth.userId);
    profileProvider.loadBadges(auth.userId);
    profileProvider.loadPointsBalance();
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final profile = profileProvider.profile;

    if (profileProvider.isLoading && profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.primary.withOpacity(0.2),
            child: profile != null
                ? Text(
                    '${profile.firstName[0]}${profile.lastName[0]}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(Icons.person, size: 50, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          if (profile != null) ...[
            Text(
              profile.fullName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '@${profile.username}',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              profile.email,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              profile.cityName,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 24),
          Card(
            color: AppColors.primary.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
  mainAxisAlignment: MainAxisAlignment.center,
  mainAxisSize: MainAxisSize.min,
  children: [
    const Icon(
      Icons.stars,
      color: AppColors.primary,
      size: 32,
    ),
    const SizedBox(width: 12),
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${profileProvider.pointsBalance?.balance ?? 0}',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const Text(
          'Spotter Points',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ],
    ),
  ],
),
            ),
          ),
          if (profileProvider.badges.isNotEmpty) ...[
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Badges',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: profileProvider.badges.length,
                itemBuilder: (context, index) {
                  final badge = profileProvider.badges[index];
                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.military_tech,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          badge.badgeName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 24),
          _buildActionButton(
            icon: Icons.edit,
            label: 'Edit Profile',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EditProfileScreen(),
                ),
              );
            },
          ),
          _buildActionButton(
            icon: Icons.receipt_long,
            label: 'My Orders',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OrderHistoryScreen(),
                ),
              );
            },
          ),
          _buildActionButton(
            icon: Icons.event_note,
            label: 'My Reservations',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MyReservationsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
