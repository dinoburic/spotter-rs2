import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/reservation_provider.dart';
import '../../core/models/reservation_response.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/confirm_dialog.dart';

class ReservationDetailScreen extends StatefulWidget {
  final int reservationId;

  const ReservationDetailScreen({super.key, required this.reservationId});

  @override
  State<ReservationDetailScreen> createState() =>
      _ReservationDetailScreenState();
}

class _ReservationDetailScreenState extends State<ReservationDetailScreen> {
  ReservationResponse? _reservation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReservation();
  }

  Future<void> _loadReservation() async {
    try {
      _reservation = await context
          .read<ReservationProvider>()
          .getById(widget.reservationId);
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

  Future<void> _confirm() async {
    final note = await showInputDialog(
      context,
      title: 'Confirm Reservation',
      hint: 'Add a note (optional)',
      confirmText: 'Confirm',
    );

    if (note != null && mounted) {
      try {
        await context
            .read<ReservationProvider>()
            .confirm(widget.reservationId, note.isEmpty ? null : note);
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

  Future<void> _cancel() async {
    final note = await showInputDialog(
      context,
      title: 'Cancel Reservation',
      hint: 'Reason for cancellation (optional)',
      confirmText: 'Cancel Reservation',
    );

    if (note != null && mounted) {
      try {
        await context
            .read<ReservationProvider>()
            .cancel(widget.reservationId, note.isEmpty ? null : note);
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

  Future<void> _complete() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Complete Reservation',
      message: 'Are you sure you want to mark this reservation as completed?',
      confirmText: 'Complete',
    );

    if (confirmed && mounted) {
      try {
        await context
            .read<ReservationProvider>()
            .complete(widget.reservationId);
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
      case 3:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text('Reservation #${widget.reservationId}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _reservation == null
              ? const Center(child: Text('Reservation not found'))
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
                                    'Reservation Details',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const Spacer(),
                                  Chip(
                                    label: Text(
                                      _reservation!.statusName,
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor:
                                        _getStatusColor(_reservation!.status),
                                  ),
                                ],
                              ),
                              const Divider(),
                              _buildInfoRow('Event', _reservation!.eventTitle),
                              _buildInfoRow('User', _reservation!.userFullName),
                              _buildInfoRow('Created',
                                  dateFormat.format(_reservation!.createdAt)),
                              if (_reservation!.approvedByName != null)
                                _buildInfoRow(
                                    'Approved By', _reservation!.approvedByName!),
                              if (_reservation!.approvedAt != null)
                                _buildInfoRow('Approved At',
                                    dateFormat.format(_reservation!.approvedAt!)),
                              if (_reservation!.auditNote != null &&
                                  _reservation!.auditNote!.isNotEmpty)
                                _buildInfoRow('Note', _reservation!.auditNote!),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_reservation!.status == 0)
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _confirm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text('Confirm'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _cancel,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                          ],
                        ),
                      if (_reservation!.status == 1)
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _complete,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text('Complete'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _cancel,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text('Cancel'),
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
