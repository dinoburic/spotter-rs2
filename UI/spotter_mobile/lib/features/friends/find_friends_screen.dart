import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/friendship_provider.dart';
import '../../core/models/user_suggestion_response.dart';
import '../../core/models/friendship_response.dart';

class FindFriendsScreen extends StatefulWidget {
  const FindFriendsScreen({super.key});

  @override
  State<FindFriendsScreen> createState() => _FindFriendsScreenState();
}

class _FindFriendsScreenState extends State<FindFriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<FriendshipProvider>();
      provider.loadSuggestions(refresh: true);
      provider.loadPendingRequests(refresh: true);
      provider.loadFriends(refresh: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<FriendshipProvider>().searchUsers(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FriendshipProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Friends'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Suggestions',style: TextStyle(fontSize: 8),),
                  if (provider.suggestions.isNotEmpty) ...[
                    const SizedBox(width: 3),
                    _buildBadge(provider.suggestions.length),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Requests',style: TextStyle(fontSize: 8),),
                  if (provider.pendingRequests.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    _buildBadge(provider.pendingRequests.length),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Friends',style: TextStyle(fontSize: 8),),
                  if (provider.friends.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    _buildBadge(provider.friends.length),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or username...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          provider.clearSearch();
                        },
                      )
                    : null,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          if (provider.searchResults.isNotEmpty ||
              _searchController.text.isNotEmpty)
            Expanded(child: _buildSearchResults(provider))
          else
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSuggestionsTab(provider),
                  _buildPendingRequestsTab(provider),
                  _buildFriendsTab(provider),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSearchResults(FriendshipProvider provider) {
    if (provider.isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: provider.searchResults.length,
      itemBuilder: (context, index) {
        final user = provider.searchResults[index];
        return _buildUserSuggestionCard(user, provider);
      },
    );
  }

  Widget _buildSuggestionsTab(FriendshipProvider provider) {
    if (provider.isLoading && provider.suggestions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.suggestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'No suggestions available',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Use the search bar to find friends',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadSuggestions(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: provider.suggestions.length,
        itemBuilder: (context, index) {
          final user = provider.suggestions[index];
          return _buildUserSuggestionCard(user, provider);
        },
      ),
    );
  }

  Widget _buildPendingRequestsTab(FriendshipProvider provider) {
    if (provider.isLoading && provider.pendingRequests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.pendingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mail_outline, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'No pending requests',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadPendingRequests(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: provider.pendingRequests.length,
        itemBuilder: (context, index) {
          final request = provider.pendingRequests[index];
          return _buildPendingRequestCard(request, provider);
        },
      ),
    );
  }

  Widget _buildFriendsTab(FriendshipProvider provider) {
    if (provider.isLoading && provider.friends.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'No friends yet',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Find friends in the Suggestions tab',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadFriends(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: provider.friends.length,
        itemBuilder: (context, index) {
          final friend = provider.friends[index];
          return _buildFriendCard(friend);
        },
      ),
    );
  }

  Widget _buildUserSuggestionCard(
      UserSuggestionResponse user, FriendshipProvider provider) {
    final isPending = provider.isPendingAction(user.userId);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.2),
          child: Text(
            user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(user.fullName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('@${user.username}'),
            if (user.cityName != null)
              Text(
                user.cityName!,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            if (user.mutualFriendsCount > 0)
              Text(
                '${user.mutualFriendsCount} mutual friend${user.mutualFriendsCount > 1 ? 's' : ''}',
                style: TextStyle(fontSize: 12, color: AppColors.primary),
              ),
          ],
        ),
        trailing: isPending
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : IconButton(
                icon: const Icon(Icons.person_add),
                color: AppColors.primary,
                onPressed: () => _sendFriendRequest(user.userId),
              ),
      ),
    );
  }

  Widget _buildPendingRequestCard(
      FriendshipResponse request, FriendshipProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              child: Text(
                request.requesterName.isNotEmpty
                    ? request.requesterName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.requesterName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Wants to be your friend',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              color: AppColors.error,
              onPressed: () => _rejectRequest(request.id),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.check),
              color: AppColors.success,
              onPressed: () => _acceptRequest(request.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendCard(UserSuggestionResponse friend) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.2),
          child: Text(
            friend.fullName.isNotEmpty ? friend.fullName[0].toUpperCase() : '?',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(friend.fullName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('@${friend.username}'),
            if (friend.cityName != null)
              Text(
                friend.cityName!,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Future<void> _sendFriendRequest(int userId) async {
    final provider = context.read<FriendshipProvider>();
    final success = await provider.sendRequest(userId);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Friend request sent!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error!),
          backgroundColor: AppColors.error,
        ),
      );
      provider.clearError();
    }
  }

  Future<void> _acceptRequest(int friendshipId) async {
    final provider = context.read<FriendshipProvider>();
    final success = await provider.acceptRequest(friendshipId);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Friend request accepted!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error!),
          backgroundColor: AppColors.error,
        ),
      );
      provider.clearError();
    }
  }

  Future<void> _rejectRequest(int friendshipId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Request'),
        content: const Text('Are you sure you want to decline this friend request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Decline'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final provider = context.read<FriendshipProvider>();
    final success = await provider.rejectRequest(friendshipId);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Friend request declined'),
          backgroundColor: AppColors.textSecondary,
        ),
      );
    } else if (provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error!),
          backgroundColor: AppColors.error,
        ),
      );
      provider.clearError();
    }
  }
}
