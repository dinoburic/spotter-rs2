import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/event_provider.dart';
import '../../core/providers/category_provider.dart';
import '../../core/providers/venue_provider.dart';
import '../../core/models/event_insert_request.dart';
import '../../core/models/event_update_request.dart';
import '../../core/models/event_response.dart';
import '../../core/models/category_response.dart';
import '../../core/models/venue_response.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/confirm_dialog.dart';
import '../ticket_types/ticket_type_form_screen.dart';

class EventFormScreen extends StatefulWidget {
  final int? eventId;

  const EventFormScreen({super.key, this.eventId});

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _capacityController = TextEditingController();
  final _coverUrlController = TextEditingController();

  List<CategoryResponse> _categories = [];
  List<VenueResponse> _venues = [];
  int? _selectedCategoryId;
  int? _selectedVenueId;
  DateTime? _startsAt;
  DateTime? _endsAt;
  EventResponse? _existingEvent;

  bool _isLoading = false;
  bool _isInitLoading = true;

  String? _titleError;
  String? _categoryError;
  String? _venueError;
  String? _capacityError;
  String? _startsAtError;
  String? _endsAtError;

  bool get _isEditing => widget.eventId != null;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _capacityController.dispose();
    _coverUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      _categories = await context.read<CategoryProvider>().loadForDropdown();
      _venues = await context.read<VenueProvider>().loadForDropdown();

      if (_isEditing) {
        _existingEvent =
            await context.read<EventProvider>().getById(widget.eventId!);
        _titleController.text = _existingEvent!.title;
        _descriptionController.text = _existingEvent!.description ?? '';
        _capacityController.text = _existingEvent!.totalCapacity.toString();
        _coverUrlController.text = _existingEvent!.coverImageUrl ?? '';
        _selectedCategoryId = _existingEvent!.categoryId;
        _selectedVenueId = _existingEvent!.venueId;
        _startsAt = _existingEvent!.startsAt;
        _endsAt = _existingEvent!.endsAt;
      } else {
        _startsAt = DateTime.now().add(const Duration(days: 7));
        _endsAt = DateTime.now().add(const Duration(days: 7, hours: 3));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isInitLoading = false);
      }
    }
  }

  bool _validate() {
    bool isValid = true;
    setState(() {
      _titleError = null;
      _categoryError = null;
      _venueError = null;
      _capacityError = null;
      _startsAtError = null;
      _endsAtError = null;
    });

    if (_titleController.text.isEmpty) {
      setState(() => _titleError = 'Title is required');
      isValid = false;
    }
    if (_selectedCategoryId == null) {
      setState(() => _categoryError = 'Category is required');
      isValid = false;
    }
    if (_selectedVenueId == null) {
      setState(() => _venueError = 'Venue is required');
      isValid = false;
    }
    if (_capacityController.text.isEmpty) {
      setState(() => _capacityError = 'Capacity is required');
      isValid = false;
    } else if (int.tryParse(_capacityController.text) == null ||
        int.parse(_capacityController.text) <= 0) {
      setState(() => _capacityError = 'Invalid capacity');
      isValid = false;
    }
    if (_startsAt == null) {
      setState(() => _startsAtError = 'Start date is required');
      isValid = false;
    }
    if (_endsAt == null) {
      setState(() => _endsAtError = 'End date is required');
      isValid = false;
    }
    if (_startsAt != null && _endsAt != null && _endsAt!.isBefore(_startsAt!)) {
      setState(() => _endsAtError = 'End date must be after start date');
      isValid = false;
    }

    return isValid;
  }

  Future<void> _pickDateTime(bool isStart) async {
    final initial = isStart ? _startsAt : _endsAt;
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial ?? DateTime.now()),
    );
    if (time == null || !mounted) return;

    final dateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      if (isStart) {
        _startsAt = dateTime;
      } else {
        _endsAt = dateTime;
      }
    });
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    setState(() => _isLoading = true);

    try {
      final provider = context.read<EventProvider>();

      if (_isEditing) {
        final request = EventUpdateRequest(
          title: _titleController.text,
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          categoryId: _selectedCategoryId!,
          venueId: _selectedVenueId!,
          startsAt: _startsAt!,
          endsAt: _endsAt!,
          totalCapacity: int.parse(_capacityController.text),
          coverImageUrl: _coverUrlController.text.isEmpty
              ? null
              : _coverUrlController.text,
        );
        await provider.update(widget.eventId!, request);
      } else {
        final request = EventInsertRequest(
          title: _titleController.text,
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          categoryId: _selectedCategoryId!,
          venueId: _selectedVenueId!,
          startsAt: _startsAt!,
          endsAt: _endsAt!,
          totalCapacity: int.parse(_capacityController.text),
          coverImageUrl: _coverUrlController.text.isEmpty
              ? null
              : _coverUrlController.text,
        );
        final createdEvent = await provider.insert(request);

        if (mounted) {
          final addTicketTypes = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Event Created'),
              content: const Text(
                  'Would you like to add ticket types for this event now?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Not Now'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Add Ticket Types'),
                ),
              ],
            ),
          );

          if (addTicketTypes == true && mounted) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    TicketTypeFormScreen(preselectedEventId: createdEvent.id),
              ),
            );
          }
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleAction(String action) async {
    final provider = context.read<EventProvider>();
    try {
      switch (action) {
        case 'activate':
          final confirmed = await showConfirmDialog(
            context,
            title: 'Activate Event',
            message: 'Are you sure you want to activate this event?',
            confirmText: 'Activate',
          );
          if (confirmed) {
            await provider.activate(widget.eventId!);
          }
          break;
        case 'cancel':
          final confirmed = await showConfirmDialog(
            context,
            title: 'Cancel Event',
            message: 'Are you sure you want to cancel this event?',
            confirmText: 'Cancel Event',
            isDestructive: true,
          );
          if (confirmed) {
            await provider.cancel(widget.eventId!);
          }
          break;
        case 'complete':
          final confirmed = await showConfirmDialog(
            context,
            title: 'Complete Event',
            message: 'Are you sure you want to mark this event as completed?',
            confirmText: 'Complete',
          );
          if (confirmed) {
            await provider.complete(widget.eventId!);
          }
          break;
      }
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.grey;
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
        title: Text(_isEditing ? 'Edit Event' : 'Add Event'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isInitLoading
          ? const LoadingIndicator()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isEditing && _existingEvent != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Chip(
                              label: Text(
                                _existingEvent!.statusName,
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor:
                                  _getStatusColor(_existingEvent!.status),
                            ),
                            const Spacer(),
                            if (_existingEvent!.status == 0)
                              ElevatedButton(
                                onPressed: () => _handleAction('activate'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                child: const Text('Activate'),
                              ),
                            if (_existingEvent!.status == 0 ||
                                _existingEvent!.status == 1) ...[
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => _handleAction('cancel'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('Cancel'),
                              ),
                            ],
                            if (_existingEvent!.status == 1) ...[
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => _handleAction('complete'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                ),
                                child: const Text('Complete'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      border: const OutlineInputBorder(),
                      errorText: _titleError,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _selectedCategoryId,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: const OutlineInputBorder(),
                      errorText: _categoryError,
                    ),
                    items: _categories
                        .map((cat) => DropdownMenuItem(
                              value: cat.id,
                              child: Text(cat.name),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedCategoryId = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _selectedVenueId,
                    decoration: InputDecoration(
                      labelText: 'Venue',
                      border: const OutlineInputBorder(),
                      errorText: _venueError,
                    ),
                    items: _venues
                        .map((venue) => DropdownMenuItem(
                              value: venue.id,
                              child: Text('${venue.name} - ${venue.cityName}'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedVenueId = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickDateTime(true),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Starts At',
                              border: const OutlineInputBorder(),
                              errorText: _startsAtError,
                            ),
                            child: Text(
                              _startsAt != null
                                  ? dateFormat.format(_startsAt!)
                                  : 'Select date and time',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickDateTime(false),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Ends At',
                              border: const OutlineInputBorder(),
                              errorText: _endsAtError,
                            ),
                            child: Text(
                              _endsAt != null
                                  ? dateFormat.format(_endsAt!)
                                  : 'Select date and time',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _capacityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Total Capacity',
                      border: const OutlineInputBorder(),
                      errorText: _capacityError,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _coverUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Cover Image URL (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_coverUrlController.text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _coverUrlController.text,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 150,
                          color: Colors.grey[200],
                          child: const Center(
                            child: Text('Invalid image URL'),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_isEditing ? 'Update' : 'Create'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
