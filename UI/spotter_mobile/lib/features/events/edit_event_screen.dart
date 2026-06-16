import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/event_response.dart';
import '../../core/providers/event_provider.dart';

class EditEventScreen extends StatefulWidget {
  final EventResponse event;

  const EditEventScreen({super.key, required this.event});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _capacityController;

  int? _selectedCategoryId;
  int? _selectedVenueId;
  DateTime? _startsAt;
  DateTime? _endsAt;

  String? _categoryError;
  String? _venueError;
  String? _startsAtError;
  String? _endsAtError;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title);
    _descriptionController = TextEditingController(text: widget.event.description ?? '');
    _capacityController = TextEditingController(text: widget.event.totalCapacity.toString());
    _selectedCategoryId = widget.event.categoryId;
    _selectedVenueId = widget.event.venueId;
    _startsAt = widget.event.startsAt;
    _endsAt = widget.event.endsAt;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final eventProvider = context.read<EventProvider>();
      eventProvider.loadCategories();
      eventProvider.loadVenues();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(bool isStart) async {
    final initialDate = isStart
        ? (_startsAt ?? DateTime.now().add(const Duration(days: 1)))
        : (_endsAt ?? _startsAt?.add(const Duration(hours: 2)) ?? DateTime.now().add(const Duration(days: 1)));

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (time == null || !mounted) return;

    final combined = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _startsAt = combined;
        _startsAtError = null;
        if (_endsAt != null && _endsAt!.isBefore(combined)) {
          _endsAt = null;
        }
      } else {
        _endsAt = combined;
        _endsAtError = null;
      }
    });
  }

  bool _validateDropdowns() {
    bool isValid = true;

    setState(() {
      if (_selectedCategoryId == null) {
        _categoryError = 'Please select a category';
        isValid = false;
      } else {
        _categoryError = null;
      }

      if (_selectedVenueId == null) {
        _venueError = 'Please select a venue';
        isValid = false;
      } else {
        _venueError = null;
      }

      if (_startsAt == null) {
        _startsAtError = 'Please select start date and time';
        isValid = false;
      } else {
        _startsAtError = null;
      }

      if (_endsAt == null) {
        _endsAtError = 'Please select end date and time';
        isValid = false;
      } else if (_startsAt != null && _endsAt!.isBefore(_startsAt!)) {
        _endsAtError = 'End time must be after start time';
        isValid = false;
      } else {
        _endsAtError = null;
      }
    });

    return isValid;
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState?.validate() ?? false;
    final dropdownsValid = _validateDropdowns();

    if (!formValid || !dropdownsValid) return;

    setState(() => _isSubmitting = true);

    final eventProvider = context.read<EventProvider>();
    final request = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      'categoryId': _selectedCategoryId,
      'venueId': _selectedVenueId,
      'startsAt': _startsAt!.toIso8601String(),
      'endsAt': _endsAt!.toIso8601String(),
      'totalCapacity': int.parse(_capacityController.text.trim()),
    };

    final success = await eventProvider.updateEvent(widget.event.id, request);

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event updated!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(eventProvider.error ?? 'Failed to update event'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Event'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  if (value.trim().length < 3) {
                    return 'Title must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                decoration: InputDecoration(
                  labelText: 'Category *',
                  border: const OutlineInputBorder(),
                  errorText: _categoryError,
                ),
                items: eventProvider.categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat.id,
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.fromHex(cat.colorHex),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(cat.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                    _categoryError = null;
                  });
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<int>(
                value: _selectedVenueId,
                decoration: InputDecoration(
                  labelText: 'Venue *',
                  border: const OutlineInputBorder(),
                  errorText: _venueError,
                ),
                items: eventProvider.venues.map((venue) {
                  return DropdownMenuItem(
                    value: venue.id,
                    child: Text('${venue.name} - ${venue.cityName}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedVenueId = value;
                    _venueError = null;
                  });
                },
              ),
              const SizedBox(height: 16),

              InkWell(
                onTap: () => _pickDateTime(true),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Starts At *',
                    border: const OutlineInputBorder(),
                    errorText: _startsAtError,
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _startsAt != null ? dateFormat.format(_startsAt!) : 'Select date and time',
                    style: TextStyle(
                      color: _startsAt != null ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              InkWell(
                onTap: () => _pickDateTime(false),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Ends At *',
                    border: const OutlineInputBorder(),
                    errorText: _endsAtError,
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _endsAt != null ? dateFormat.format(_endsAt!) : 'Select date and time',
                    style: TextStyle(
                      color: _endsAt != null ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _capacityController,
                decoration: const InputDecoration(
                  labelText: 'Total Capacity *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Capacity is required';
                  }
                  final parsed = int.tryParse(value.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Capacity must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
