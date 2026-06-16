import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import '../../core/providers/venue_provider.dart';
import '../../core/providers/city_provider.dart';
import '../../core/models/venue_insert_request.dart';
import '../../core/models/venue_update_request.dart';
import '../../core/models/city_response.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/loading_indicator.dart';
import 'venue_map_picker.dart';

class VenueFormScreen extends StatefulWidget {
  final int? venueId;

  const VenueFormScreen({super.key, this.venueId});

  @override
  State<VenueFormScreen> createState() => _VenueFormScreenState();
}

class _VenueFormScreenState extends State<VenueFormScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();

  List<CityResponse> _cities = [];
  int? _selectedCityId;
  double? _latitude;
  double? _longitude;
  bool _isLoading = false;
  bool _isInitLoading = true;

  String? _nameError;
  String? _addressError;
  String? _cityError;

  bool get _isEditing => widget.venueId != null;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      _cities = await context.read<CityProvider>().loadForDropdown();

      if (_isEditing) {
        final venue =
            await context.read<VenueProvider>().getById(widget.venueId!);
        _nameController.text = venue.name;
        _addressController.text = venue.address;
        _selectedCityId = venue.cityId;
        _latitude = venue.latitude;
        _longitude = venue.longitude;
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
      _addressError = null;
      _cityError = null;
    });

    if (_nameController.text.isEmpty) {
      setState(() => _nameError = 'Name is required');
      isValid = false;
    }
    if (_addressController.text.isEmpty) {
      setState(() => _addressError = 'Address is required');
      isValid = false;
    }
    if (_selectedCityId == null) {
      setState(() => _cityError = 'City is required');
      isValid = false;
    }

    return isValid;
  }

  Future<void> _pickLocation() async {
    final result = await showDialog<LatLng>(
      context: context,
      builder: (context) => VenueMapPicker(
        initialLatitude: _latitude,
        initialLongitude: _longitude,
      ),
    );

    if (result != null) {
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
      });
    }
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    setState(() => _isLoading = true);

    try {
      final provider = context.read<VenueProvider>();

      if (_isEditing) {
        final request = VenueUpdateRequest(
          name: _nameController.text,
          address: _addressController.text,
          cityId: _selectedCityId!,
          latitude: _latitude,
          longitude: _longitude,
        );
        await provider.update(widget.venueId!, request);
      } else {
        final request = VenueInsertRequest(
          name: _nameController.text,
          address: _addressController.text,
          cityId: _selectedCityId!,
          latitude: _latitude,
          longitude: _longitude,
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
        title: Text(_isEditing ? 'Edit Venue' : 'Add Venue'),
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
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      border: const OutlineInputBorder(),
                      errorText: _nameError,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Address',
                      border: const OutlineInputBorder(),
                      errorText: _addressError,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _selectedCityId,
                    decoration: InputDecoration(
                      labelText: 'City',
                      border: const OutlineInputBorder(),
                      errorText: _cityError,
                    ),
                    items: _cities
                        .map((city) => DropdownMenuItem(
                              value: city.id,
                              child: Text('${city.name}, ${city.country}'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedCityId = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on),
                              const SizedBox(width: 8),
                              const Text(
                                'Location',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const Spacer(),
                              OutlinedButton.icon(
                                onPressed: _pickLocation,
                                icon: const Icon(Icons.map),
                                label: const Text('Pick on Map'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_latitude != null && _longitude != null)
                            Text(
                              'Lat: ${_latitude!.toStringAsFixed(6)}, '
                              'Lng: ${_longitude!.toStringAsFixed(6)}',
                              style: const TextStyle(fontFamily: 'monospace'),
                            )
                          else
                            Text(
                              'No coordinates set (will be geocoded from address)',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                        ],
                      ),
                    ),
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
