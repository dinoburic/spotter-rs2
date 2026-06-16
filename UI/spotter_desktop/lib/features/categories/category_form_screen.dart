import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/category_provider.dart';
import '../../core/models/category_request.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/loading_indicator.dart';

class CategoryFormScreen extends StatefulWidget {
  final int? categoryId;

  const CategoryFormScreen({super.key, this.categoryId});

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final _nameController = TextEditingController();
  final _colorController = TextEditingController();
  final _iconController = TextEditingController();
  bool _isLoading = false;
  bool _isInitLoading = true;
  String? _nameError;
  String? _colorError;

  bool get _isEditing => widget.categoryId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadCategory();
    } else {
      _colorController.text = '#7C3AED';
      _isInitLoading = false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _colorController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  Future<void> _loadCategory() async {
    try {
      final category =
          await context.read<CategoryProvider>().getById(widget.categoryId!);
      _nameController.text = category.name;
      _colorController.text = category.colorHex;
      _iconController.text = category.iconSlug ?? '';
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
      _colorError = null;
    });

    if (_nameController.text.isEmpty) {
      setState(() => _nameError = 'Name is required');
      isValid = false;
    }
    if (_colorController.text.isEmpty) {
      setState(() => _colorError = 'Color is required');
      isValid = false;
    } else if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(_colorController.text)) {
      setState(() => _colorError = 'Invalid color format (use #RRGGBB)');
      isValid = false;
    }

    return isValid;
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    setState(() => _isLoading = true);

    try {
      final request = CategoryRequest(
        name: _nameController.text,
        colorHex: _colorController.text,
        iconSlug:
            _iconController.text.isEmpty ? null : _iconController.text,
      );

      final provider = context.read<CategoryProvider>();
      if (_isEditing) {
        await provider.update(widget.categoryId!, request);
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

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Category' : 'Add Category'),
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
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _colorController,
                          decoration: InputDecoration(
                            labelText: 'Color (Hex)',
                            hintText: '#7C3AED',
                            border: const OutlineInputBorder(),
                            errorText: _colorError,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _parseColor(_colorController.text),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _iconController,
                    decoration: const InputDecoration(
                      labelText: 'Icon Slug (optional)',
                      hintText: 'e.g., music, sports, food',
                      border: OutlineInputBorder(),
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
