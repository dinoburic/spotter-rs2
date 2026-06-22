import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/event_provider.dart';
import '../ticket_types/create_ticket_type_screen.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _capacityController = TextEditingController();

  int? _selectedCategoryId;
  int? _selectedVenueId;
  DateTime? _startsAt;
  DateTime? _endsAt;
  XFile? _coverImage;

  String? _categoryError;
  String? _venueError;
  String? _startsAtError;
  String? _endsAtError;

  bool _isSubmitting = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
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

  Future<void> _pickCoverImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() {
        _coverImage = image;
      });
    }
  }

  Future<void> _pickDateTime(bool isStart) async {
    final initialDate = DateTime.now().add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? initialDate : (_startsAt?.add(const Duration(hours: 2)) ?? initialDate),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
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
      } else if (_startsAt!.isBefore(DateTime.now())) {
        _startsAtError = 'Start time must be in the future';
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

    final createdEventId = await eventProvider.createEvent(request);

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (createdEventId != null) {
      if (_coverImage != null) {
        await eventProvider.uploadCoverImage(createdEventId, _coverImage!.path);
      }

      final addTickets = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Event Created!'),
          content: const Text(
            'Event created successfully as Draft.\n\n'
            'You need at least one ticket type before the event can be activated.\n\n'
            'Would you like to add ticket types now?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add Ticket Types'),
            ),
          ],
        ),
      );

      if (!mounted) return;

      if (addTickets == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CreateTicketTypeScreen(eventId: createdEventId),
          ),
        );
      } else {
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(eventProvider.error ?? 'Failed to create event'),
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
        title: const Text('New Event'),
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
                initialValue: _selectedCategoryId,
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
                initialValue: _selectedVenueId,
                isExpanded: true,
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
              const SizedBox(height: 16),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cover Image (optional)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickCoverImage,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[100],
                      ),
                      child: _coverImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(_coverImage!.path),
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 48,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to select image',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  if (_coverImage != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => setState(() => _coverImage = null),
                        icon: const Icon(Icons.clear, size: 18),
                        label: const Text('Remove'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                      ),
                    ),
                ],
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
                          height: 30,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Create Event',style: TextStyle(fontSize: 8),),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
