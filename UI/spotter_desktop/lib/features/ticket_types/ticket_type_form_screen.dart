import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/ticket_type_provider.dart';
import '../../core/providers/event_provider.dart';
import '../../core/models/ticket_type_insert_request.dart';
import '../../core/models/ticket_type_update_request.dart';
import '../../core/models/event_response.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/loading_indicator.dart';

class TicketTypeFormScreen extends StatefulWidget {
  final int? ticketTypeId;
  final int? preselectedEventId;

  const TicketTypeFormScreen({super.key, this.ticketTypeId, this.preselectedEventId});

  @override
  State<TicketTypeFormScreen> createState() => _TicketTypeFormScreenState();
}

class _TicketTypeFormScreenState extends State<TicketTypeFormScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();

  List<EventResponse> _events = [];
  int? _selectedEventId;
  int _selectedTypeEnum = 0;
  bool _isLoading = false;
  bool _isInitLoading = true;

  String? _nameError;
  String? _priceError;
  String? _quantityError;
  String? _eventError;

  bool get _isEditing => widget.ticketTypeId != null;

  final List<Map<String, dynamic>> _ticketTypes = [
    {'value': 0, 'label': 'General'},
    {'value': 1, 'label': 'VIP'},
    {'value': 2, 'label': 'Early Bird'},
    {'value': 3, 'label': 'Student'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      _events = await context.read<EventProvider>().loadForDropdown();

      if (_isEditing) {
        final ticketType = await context
            .read<TicketTypeProvider>()
            .getById(widget.ticketTypeId!);
        _nameController.text = ticketType.name;
        _priceController.text = ticketType.price.toString();
        _quantityController.text = ticketType.totalQuantity.toString();
        _selectedEventId = ticketType.eventId;
        _selectedTypeEnum = ticketType.typeEnum;
      } else if (widget.preselectedEventId != null) {
        _selectedEventId = widget.preselectedEventId;
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
      _nameError = null;
      _priceError = null;
      _quantityError = null;
      _eventError = null;
    });

    if (_nameController.text.isEmpty) {
      setState(() => _nameError = 'Name is required');
      isValid = false;
    }
    if (_priceController.text.isEmpty) {
      setState(() => _priceError = 'Price is required');
      isValid = false;
    } else if (double.tryParse(_priceController.text) == null ||
        double.parse(_priceController.text) < 0) {
      setState(() => _priceError = 'Invalid price');
      isValid = false;
    }
    if (_quantityController.text.isEmpty) {
      setState(() => _quantityError = 'Quantity is required');
      isValid = false;
    } else if (int.tryParse(_quantityController.text) == null ||
        int.parse(_quantityController.text) <= 0) {
      setState(() => _quantityError = 'Invalid quantity');
      isValid = false;
    }
    if (!_isEditing && _selectedEventId == null) {
      setState(() => _eventError = 'Event is required');
      isValid = false;
    }

    return isValid;
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    setState(() => _isLoading = true);

    try {
      final provider = context.read<TicketTypeProvider>();

      if (_isEditing) {
        final request = TicketTypeUpdateRequest(
          name: _nameController.text,
          price: double.parse(_priceController.text),
          totalQuantity: int.parse(_quantityController.text),
        );
        await provider.update(widget.ticketTypeId!, request);
      } else {
        final request = TicketTypeInsertRequest(
          eventId: _selectedEventId!,
          name: _nameController.text,
          price: double.parse(_priceController.text),
          totalQuantity: int.parse(_quantityController.text),
          typeEnum: _selectedTypeEnum,
        );
        await provider.insert(request);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Ticket Type' : 'Add Ticket Type'),
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
                  if (!_isEditing)
                    DropdownButtonFormField<int>(
                      value: _selectedEventId,
                      decoration: InputDecoration(
                        labelText: 'Event',
                        border: const OutlineInputBorder(),
                        errorText: _eventError,
                      ),
                      items: _events
                          .map((event) => DropdownMenuItem(
                                value: event.id,
                                child: Text(event.title),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedEventId = value);
                      },
                    ),
                  if (!_isEditing) const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      border: const OutlineInputBorder(),
                      errorText: _nameError,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!_isEditing)
                    DropdownButtonFormField<int>(
                      value: _selectedTypeEnum,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                      ),
                      items: _ticketTypes
                          .map((type) => DropdownMenuItem<int>(
                                value: type['value'] as int,
                                child: Text(type['label'] as String),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedTypeEnum = value ?? 0);
                      },
                    ),
                  if (!_isEditing) const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Price (BAM)',
                            border: const OutlineInputBorder(),
                            errorText: _priceError,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Total Quantity',
                            border: const OutlineInputBorder(),
                            errorText: _quantityError,
                          ),
                        ),
                      ),
                    ],
                  ),
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
