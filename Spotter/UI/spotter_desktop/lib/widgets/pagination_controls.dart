import 'package:flutter/material.dart';

class PaginationControls extends StatelessWidget {
  final int currentPage;
  final int? totalCount;
  final int pageSize;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const PaginationControls({
    super.key,
    required this.currentPage,
    this.totalCount,
    required this.pageSize,
    this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final totalPages =
        totalCount != null ? (totalCount! / pageSize).ceil() : 1;
    final hasMore = currentPage < totalPages;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: currentPage > 1 ? onPrevious : null,
            icon: const Icon(Icons.chevron_left),
          ),
          const SizedBox(width: 16),
          Text(
            'Page $currentPage of $totalPages',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (totalCount != null) ...[
            const SizedBox(width: 8),
            Text(
              '($totalCount total)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
          const SizedBox(width: 16),
          IconButton(
            onPressed: hasMore ? onNext : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
