import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/calibration_provider.dart';
import '../widgets/animated_background.dart';
import '../widgets/calibration_system_card.dart';

class SystemsLibraryScreen extends StatefulWidget {
  const SystemsLibraryScreen({super.key});

  @override
  State<SystemsLibraryScreen> createState() => _SystemsLibraryScreenState();
}

class _SystemsLibraryScreenState extends State<SystemsLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalibrationProvider>();

    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                _buildSearchBar(),
                _buildCategoryFilter(provider),
                Expanded(
                  child: _buildSystemsList(provider),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.library_books,
            color: const Color(0xFF00B4D8),
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            'Systems Library',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ],
      ).animate().fadeIn().slideX(begin: -0.2, end: 0),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search calibration systems...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<CalibrationProvider>().searchSystems('');
                    setState(() {});
                  },
                )
              : null,
        ),
        onChanged: (value) {
          setState(() {});
          if (value.isEmpty) {
            context.read<CalibrationProvider>().clearResults();
          }
        },
        onSubmitted: (value) {
          context.read<CalibrationProvider>().searchSystems(value);
        },
      ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.2, end: 0),
    );
  }

  Widget _buildCategoryFilter(CalibrationProvider provider) {
    final categories = ['All', 'Camera Systems', 'Radar Systems', 
                       'Sensor Systems', 'Lighting Systems', 
                       'Chassis Systems', 'Safety Systems'];

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              backgroundColor: Colors.white.withOpacity(0.05),
              selectedColor: const Color(0xFF00B4D8).withOpacity(0.3),
              checkmarkColor: const Color(0xFF00B4D8),
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF00B4D8)
                    : Colors.white.withOpacity(0.2),
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildSystemsList(CalibrationProvider provider) {
    final systems = _searchController.text.isNotEmpty
        ? provider.requiredSystems
        : _getFilteredSystems(provider.allSystems);

    if (systems.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: systems.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: CalibrationSystemCard(system: systems[index]),
        );
      },
    );
  }

  List<dynamic> _getFilteredSystems(List systems) {
    if (_selectedCategory == 'All') {
      return systems;
    }
    return systems.where((s) => s.category == _selectedCategory).toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.white24,
          ),
          const SizedBox(height: 16),
          Text(
            'No systems found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term or category',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ).animate().fadeIn(),
    );
  }
}



