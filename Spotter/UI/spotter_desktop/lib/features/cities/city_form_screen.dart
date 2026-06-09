import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/city_provider.dart';
import '../../core/models/city_request.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/loading_indicator.dart';

class CityFormScreen extends StatefulWidget {
  final int? cityId;

  const CityFormScreen({super.key, this.cityId});

  @override
  State<CityFormScreen> createState() => _CityFormScreenState();
}

class _CityFormScreenState extends State<CityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _countryController = TextEditingController();
  bool _isLoading = false;
  bool _isInitLoading = true;
  String? _nameError;
  String? _countryError;

  bool get _isEditing => widget.cityId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadCity();
    } else {
      _isInitLoading = false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _loadCity() async {
    try {
      final city = await context.read<CityProvider>().getById(widget.cityId!);
      _nameController.text = city.name;
      _countryController.text = city.country;
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
      _countryError = null;
    });

    if (_nameController.text.isEmpty) {
      setState(() => _nameError = 'Name is required');
      isValid = false;
    }
    if (_countryController.text.isEmpty) {
      setState(() => _countryError = 'Country is required');
      isValid = false;
    }

    return isValid;
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    setState(() => _isLoading = true);

    try {
      final request = CityRequest(
        name: _nameController.text,
        country: _countryController.text,
      );

      final provider = context.read<CityProvider>();
      if (_isEditing) {
        await provider.update(widget.cityId!, request);
      } else {
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
        title: Text(_isEditing ? 'Edit City' : 'Add City'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isInitLoading
          ? const LoadingIndicator()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
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
                      controller: _countryController,
                      decoration: InputDecoration(
                        labelText: 'Country',
                        border: const OutlineInputBorder(),
                        errorText: _countryError,
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
            ),
    );
  }
}
