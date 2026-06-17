import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/city_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/spotter_drawer.dart';
import '../../widgets/pagination_controls.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/confirm_dialog.dart';
import 'city_form_screen.dart';

class CityListScreen extends StatefulWidget {
  const CityListScreen({super.key});

  @override
  State<CityListScreen> createState() => _CityListScreenState();
}

class _CityListScreenState extends State<CityListScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _loadData() {
    final provider = context.read<CityProvider>();
    provider.loadAll(name: _searchController.text);
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final provider = context.read<CityProvider>();
      provider.setPage(1);
      _loadData();
    });
  }

  Future<void> _deleteCity(int id) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete City',
      message: 'Are you sure you want to delete this city?',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (confirmed && mounted) {
      try {
        await context.read<CityProvider>().delete(id);
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CityProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cities'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CityFormScreen()),
              );
              if (result == true) _loadData();
            },
          ),
        ],
      ),
      drawer: const SpotterDrawer(currentRoute: 'cities'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search by name',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const LoadingIndicator()
                : provider.items.isEmpty
                    ? const EmptyState(
                        icon: Icons.location_city,
                        message: 'No cities found',
                      )
                    : SingleChildScrollView(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Name')),
                              DataColumn(label: Text('Country')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: provider.items.map((city) {
                              return DataRow(cells: [
                                DataCell(Text(city.name)),
                                DataCell(Text(city.country)),
                                DataCell(Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                CityFormScreen(cityId: city.id),
                                          ),
                                        );
                                        if (result == true) _loadData();
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () => _deleteCity(city.id),
                                    ),
                                  ],
                                )),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ),
          ),
          PaginationControls(
            currentPage: provider.currentPage,
            totalCount: provider.totalCount,
            pageSize: provider.pageSize,
            onPrevious: () {
              provider.setPage(provider.currentPage - 1);
              _loadData();
            },
            onNext: () {
              provider.setPage(provider.currentPage + 1);
              _loadData();
            },
          ),
        ],
      ),
    );
  }
}
