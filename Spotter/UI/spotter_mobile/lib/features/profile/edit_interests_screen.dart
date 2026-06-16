import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/providers/event_provider.dart';
import '../../core/constants/app_colors.dart';

class EditInterestsScreen extends StatefulWidget {
  const EditInterestsScreen({super.key});

  @override
  State<EditInterestsScreen> createState() => _EditInterestsScreenState();
}

class _EditInterestsScreenState extends State<EditInterestsScreen> {
  List<int> _selected = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final profile = context.read<ProfileProvider>();
      final eventProvider = context.read<EventProvider>();
      await profile.loadInterests();
      if (eventProvider.categories.isEmpty) {
        await eventProvider.loadCategories();
      }
      if (!mounted) return;
      setState(() => _selected = List.from(profile.selectedInterestIds));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Interests'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Consumer<EventProvider>(
        builder: (context, eventProvider, _) {
          final categories = eventProvider.categories;
          if (categories.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select categories you are interested in.\nThis helps us recommend relevant events.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories.map((cat) {
                    final isSelected = _selected.contains(cat.id);
                    return FilterChip(
                      label: Text(cat.name),
                      selected: isSelected,
                      selectedColor: AppColors.fromHex(cat.colorHex).withValues(alpha: 0.3),
                      checkmarkColor: AppColors.fromHex(cat.colorHex),
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _selected.add(cat.id);
                          } else {
                            _selected.remove(cat.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    final success = await context.read<ProfileProvider>().updateInterests(_selected);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Interests updated!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<ProfileProvider>().error ?? 'Error')),
      );
    }
  }
}
