import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/base_provider.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/models/register_request.dart';
import '../../core/models/city_response.dart';
import '../../core/models/category_response.dart';
import '../../core/models/page_result.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  List<CityResponse> _cities = [];
  List<CategoryResponse> _categories = [];
  List<int> _selectedInterests = [];
  int? _selectedCityId;
  bool _isLoadingCities = true;

  String? _firstNameError;
  String? _lastNameError;
  String? _usernameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _cityError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCities();
      _loadCategories();
    });
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

  Future<void> _loadCities() async {
    try {
      final baseProvider = BaseProvider();
      final result = await baseProvider.get<PageResult<CityResponse>>(
        ApiConstants.cities,
        queryParameters: {'page': 1, 'pageSize': 100},
        fromJson: (json) => PageResult.fromJson(
          json,
          (item) => CityResponse.fromJson(item),
        ),
      );
      if (!mounted) return;
      setState(() {
        _cities = result.items;
        _isLoadingCities = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingCities = false);
    }
  }

  Future<void> _loadCategories() async {
    try {
      final baseProvider = BaseProvider();
      final result = await baseProvider.get<PageResult<CategoryResponse>>(
        ApiConstants.categories,
        queryParameters: {'page': 1, 'pageSize': 100},
        fromJson: (json) => PageResult.fromJson(
          json,
          (item) => CategoryResponse.fromJson(item),
        ),
      );
      if (!mounted) return;
      setState(() {
        _categories = result.items;
      });
    } catch (_) {}
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
    } else if (_usernameController.text.length < 3) {
      setState(() => _usernameError = 'Username must be at least 3 characters');
      isValid = false;
    }
    if (_emailController.text.isEmpty) {
      setState(() => _emailError = 'Email is required');
      isValid = false;
    } else if (!_emailController.text.contains('@')) {
      setState(() => _emailError = 'Invalid email format');
      isValid = false;
    }
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
      setState(() => _cityError = 'Please select a city');
      isValid = false;
    }

    return isValid;
  }

  Future<void> _register() async {
    if (!_validate()) return;

    final auth = context.read<AuthProvider>();
    final request = RegisterRequest(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      username: _usernameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
      phoneNumber: _phoneController.text.isNotEmpty ? _phoneController.text : null,
      cityId: _selectedCityId!,
    );

    await auth.register(request);

    if (!mounted) return;
    if (auth.isLoggedIn) {
      if (_selectedInterests.isNotEmpty) {
        await context.read<ProfileProvider>().updateInterests(_selectedInterests);
      }
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _lastNameController,
                            decoration: InputDecoration(
                              labelText: 'Last Name',
                              labelStyle: const TextStyle(fontSize: 10),
                              errorText: _lastNameError,
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    labelStyle: const TextStyle(fontSize: 10),
                    prefixIcon: const Icon(Icons.person_outline),
                    errorText: _usernameError,
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: const TextStyle(fontSize: 10),
                    prefixIcon: const Icon(Icons.email_outlined),
                    errorText: _emailError,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(fontSize: 10),
                    prefixIcon: const Icon(Icons.lock_outline),
                    errorText: _passwordError,
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    labelStyle: const TextStyle(fontSize: 10),
                    prefixIcon: const Icon(Icons.lock_outline),
                    errorText: _confirmPasswordError,
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number (optional)',
                    labelStyle: TextStyle(fontSize: 10),
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                _isLoadingCities
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<int>(
                        value: _selectedCityId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'City',
                          labelStyle: const TextStyle(fontSize: 10),
                          prefixIcon: const Icon(Icons.location_city_outlined),
                          errorText: _cityError,
                        ),
                        items: _cities.map((city) {
                          return DropdownMenuItem(
                            value: city.id,
                            child: Text(
                              '${city.name}, ${city.country}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCityId = value;
                            _cityError = null;
                          });
                        },
                      ),
                const SizedBox(height: 24),
                if (_categories.isNotEmpty) ...[
                  const Text(
                    'Select your interests (optional):',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _categories.map((cat) {
                      final isSelected = _selectedInterests.contains(cat.id);
                      return FilterChip(
                        label: Text(cat.name, style: const TextStyle(fontSize: 12)),
                        selected: isSelected,
                        selectedColor: AppColors.fromHex(cat.colorHex).withValues(alpha: 0.3),
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _selectedInterests.add(cat.id);
                            } else {
                              _selectedInterests.remove(cat.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  height: 60,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _register,
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Register',
                            style: TextStyle(fontSize: 12),
                          ),
                  ),
                ),
                if (auth.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      auth.error!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
