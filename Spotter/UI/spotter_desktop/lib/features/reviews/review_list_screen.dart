import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/review_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/spotter_drawer.dart';
import '../../widgets/pagination_controls.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/confirm_dialog.dart';

class ReviewListScreen extends StatefulWidget {
  const ReviewListScreen({super.key});

  @override
  State<ReviewListScreen> createState() => _ReviewListScreenState();
}

class _ReviewListScreenState extends State<ReviewListScreen> {
  int? _selectedRating;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final provider = context.read<ReviewProvider>();
    provider.loadAll(rating: _selectedRating);
  }

  Future<void> _deleteReview(int id) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Review',
      message: 'Are you sure you want to delete this review?',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (confirmed && mounted) {
      try {
        await context.read<ReviewProvider>().delete(id);
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

  Widget _buildStars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 18,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReviewProvider>();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reviews'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      drawer: const SpotterDrawer(currentRoute: 'reviews'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<int?>(
              value: _selectedRating,
              decoration: const InputDecoration(
                labelText: 'Filter by rating',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: 5, child: Text('5 Stars')),
                DropdownMenuItem(value: 4, child: Text('4 Stars')),
                DropdownMenuItem(value: 3, child: Text('3 Stars')),
                DropdownMenuItem(value: 2, child: Text('2 Stars')),
                DropdownMenuItem(value: 1, child: Text('1 Star')),
              ],
              onChanged: (value) {
                setState(() => _selectedRating = value);
                final provider = context.read<ReviewProvider>();
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
                        icon: Icons.star,
                        message: 'No reviews found',
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Event')),
                            DataColumn(label: Text('User')),
                            DataColumn(label: Text('Rating')),
                            DataColumn(label: Text('Comment')),
                            DataColumn(label: Text('Created')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: provider.items.map((review) {
                            return DataRow(cells: [
                              DataCell(
                                SizedBox(
                                  width: 200,
                                  child: Text(
                                    review.eventTitle,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              DataCell(Text(review.userFullName)),
                              DataCell(_buildStars(review.rating)),
                              DataCell(
                                SizedBox(
                                  width: 250,
                                  child: Text(
                                    review.comment ?? '-',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                              ),
                              DataCell(
                                  Text(dateFormat.format(review.createdAt))),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _deleteReview(review.id),
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
