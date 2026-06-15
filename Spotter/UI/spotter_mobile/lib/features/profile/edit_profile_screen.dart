import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/models/user_update_request.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  int? _selectedCityId;
  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  String? _cityError;

  @override
  void initState() {
    super.initState();
    final profileProvider = context.read<ProfileProvider>();
    final profile = profileProvider.profile;
    if (profile != null) {
      _firstNameController.text = profile.firstName;
      _lastNameController.text = profile.lastName;
      _emailController.text = profile.email;
      _phoneController.text = profile.phoneNumber ?? '';
      _selectedCityId = profile.cityId;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      profileProvider.loadCities();
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool _validate() {
    bool isValid = true;

    setState(() {
      _firstNameError = null;
      _lastNameError = null;
      _emailError = null;
      _cityError = null;
    });

    if (_firstNameController.text.isEmpty) {
      setState(() => _firstNameError = 'First name is required');
      isValid = false;
    }
    if (_lastNameController.text.isEmpty) {
      setState(() => _lastNameError = 'Last name is required');
      isValid = false;
    }
    if (_emailController.text.isEmpty) {
      setState(() => _emailError = 'Email is required');
      isValid = false;
    } else if (!_emailController.text.contains('@')) {
      setState(() => _emailError = 'Invalid email format');
      isValid = false;
    }
    if (_selectedCityId == null) {
      setState(() => _cityError = 'Please select a city');
      isValid = false;
    }

    return isValid;
  }

  Future<void> _save() async {
    if (!_validate()) return;

    final profileProvider = context.read<ProfileProvider>();

    final request = UserUpdateRequest(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      email: _emailController.text,
      phoneNumber:
          _phoneController.text.isNotEmpty ? _phoneController.text : null,
      cityId: _selectedCityId!,
    );

    final success = await profileProvider.updateProfile(request);

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else if (mounted && profileProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(profileProvider.error!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _firstNameController,
              decoration: InputDecoration(
                labelText: 'First Name',
                labelStyle: const TextStyle(fontSize: 10),
                errorText: _firstNameError,
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _lastNameController,
              decoration: InputDecoration(
                labelText: 'Last Name',
                labelStyle: const TextStyle(fontSize: 10),
                errorText: _lastNameError,
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: const TextStyle(fontSize: 10),
                errorText: _emailError,
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number (optional)',
                labelStyle: const TextStyle(fontSize: 10),
              ),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              isExpanded: true,
              value: _selectedCityId,
              decoration: InputDecoration(
                labelText: 'City',
                labelStyle: const TextStyle(fontSize: 10),
                errorText: _cityError,
              ),
              items: profileProvider.cities.map((city) {
                return DropdownMenuItem(
                  value: city.id,
                  child: Text('${city.name}, ${city.country}'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCityId = value;
                  _cityError = null;
                });
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: profileProvider.isLoading ? null : _save,
              child: profileProvider.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
