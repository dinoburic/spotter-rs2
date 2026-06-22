import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/city_provider.dart';
import '../../core/models/user_insert_request.dart';
import '../../core/models/user_update_request.dart';
import '../../core/models/city_response.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/loading_indicator.dart';

class UserFormScreen extends StatefulWidget {
  final int? userId;

  const UserFormScreen({super.key, this.userId});

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  List<CityResponse> _cities = [];
  int? _selectedCityId;
  int? _selectedRoleId;
  bool _isLoading = false;
  bool _isInitLoading = true;

  String? _firstNameError;
  String? _lastNameError;
  String? _usernameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _cityError;
  String? _roleError;

  static const List<Map<String, dynamic>> _roles = [
    {'id': 1, 'name': 'Admin'},
    {'id': 2, 'name': 'Organizer'},
    {'id': 3, 'name': 'User'},
  ];

  bool get _isEditing => widget.userId != null;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      _cities = await context.read<CityProvider>().loadForDropdown();

      if (_isEditing) {
        final user = await context.read<UserProvider>().getById(widget.userId!);
        _firstNameController.text = user.firstName;
        _lastNameController.text = user.lastName;
        _usernameController.text = user.username;
        _emailController.text = user.email;
        _phoneController.text = user.phoneNumber ?? '';
        _selectedCityId = user.cityId;
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
      _firstNameError = null;
      _lastNameError = null;
      _usernameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
      _cityError = null;
      _roleError = null;
    });

    if (_firstNameController.text.isEmpty) {
      setState(() => _firstNameError = 'First name is required');
      isValid = false;
    }
    if (_lastNameController.text.isEmpty) {
      setState(() => _lastNameError = 'Last name is required');
      isValid = false;
    }
    if (_usernameController.text.isEmpty) {
      setState(() => _usernameError = 'Username is required');
      isValid = false;
    }
    if (_emailController.text.isEmpty) {
      setState(() => _emailError = 'Email is required');
      isValid = false;
    } else if (!_emailController.text.contains('@')) {
      setState(() => _emailError = 'Invalid email format');
      isValid = false;
    }

    if (!_isEditing) {
      if (_passwordController.text.isEmpty) {
        setState(() => _passwordError = 'Password is required');
        isValid = false;
      } else if (_passwordController.text.length < 6) {
        setState(() => _passwordError = 'Password must be at least 6 characters');
        isValid = false;
      }
      if (_confirmPasswordController.text != _passwordController.text) {
        setState(() => _confirmPasswordError = 'Passwords do not match');
        isValid = false;
      }
      if (_selectedCityId == null) {
        setState(() => _cityError = 'City is required');
        isValid = false;
      }
      if (_selectedRoleId == null) {
        setState(() => _roleError = 'Role is required');
        isValid = false;
      }
    }

    return isValid;
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    setState(() => _isLoading = true);

    try {
      final provider = context.read<UserProvider>();

      if (_isEditing) {
        final request = UserUpdateRequest(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          email: _emailController.text,
          phoneNumber: _phoneController.text.isEmpty ? null : _phoneController.text,
          cityId: _selectedCityId,
        );
        await provider.update(widget.userId!, request);
      } else {
        final request = UserInsertRequest(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          username: _usernameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
          phoneNumber: _phoneController.text.isEmpty ? null : _phoneController.text,
          cityId: _selectedCityId!,
          roleId: _selectedRoleId!,
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
        title: Text(_isEditing ? 'Edit User' : 'Add User'),
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
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _firstNameController,
                          decoration: InputDecoration(
                            labelText: 'First Name',
                            border: const OutlineInputBorder(),
                            errorText: _firstNameError,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _lastNameController,
                          decoration: InputDecoration(
                            labelText: 'Last Name',
                            border: const OutlineInputBorder(),
                            errorText: _lastNameError,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _usernameController,
                    enabled: !_isEditing,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      border: const OutlineInputBorder(),
                      errorText: _usernameError,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: const OutlineInputBorder(),
                      errorText: _emailError,
                    ),
                  ),
                  if (!_isEditing) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(),
                        errorText: _passwordError,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        border: const OutlineInputBorder(),
                        errorText: _confirmPasswordError,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _selectedCityId,
                    decoration: InputDecoration(
                      labelText: _isEditing ? 'City (optional)' : 'City *',
                      border: const OutlineInputBorder(),
                      errorText: _cityError,
                    ),
                    items: [
                      if (_isEditing)
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('No city selected'),
                        ),
                      ..._cities.map((city) => DropdownMenuItem(
                            value: city.id,
                            child: Text('${city.name}, ${city.country}'),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCityId = value;
                        _cityError = null;
                      });
                    },
                  ),
                  if (!_isEditing) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _selectedRoleId,
                      decoration: InputDecoration(
                        labelText: 'Role *',
                        border: const OutlineInputBorder(),
                        errorText: _roleError,
                      ),
                      items: _roles.map((role) => DropdownMenuItem(
                            value: role['id'] as int,
                            child: Text(role['name'] as String),
                          )).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedRoleId = value;
                          _roleError = null;
                        });
                      },
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
