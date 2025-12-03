import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../models/calibration_system.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseManagerScreen extends StatefulWidget {
  const DatabaseManagerScreen({Key? key}) : super(key: key);

  @override
  State<DatabaseManagerScreen> createState() => _DatabaseManagerScreenState();
}

class _DatabaseManagerScreenState extends State<DatabaseManagerScreen> {
  Database? _database;
  List<String> _vehicleMakes = [];
  List<String> _years = [];
  List<String> _models = [];
  List<Map<String, dynamic>> _currentSystems = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedVehicleMake;
  String? _selectedYear;
  String? _selectedModel;

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    try {
      final dbService = context.read<DatabaseService>();
      _database = dbService.databaseSync;
      if (_database != null) {
        await _loadVehicleMakes();
      } else {
        throw Exception('Database not initialized');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing database: $e')),
        );
      }
    }
  }

  String get _currentTitle {
    if (_selectedVehicleMake != null) {
      return '$_selectedVehicleMake Systems';
    }
    return 'Calibration Database';
  }

  Future<void> _loadVehicleMakes() async {
    setState(() => _isLoading = true);
    try {
      if (_database == null) throw Exception('Database not initialized');
      
      // Query all calibration systems
      final systems = await _database!.query('calibration_systems');
      
      print('🔍 Analyzing ${systems.length} systems for vehicle makes...');
      
      // Extract unique makes from system names AND adas_keywords
      final makeSet = <String>{};
      for (final system in systems) {
        final name = system['name']?.toString() ?? '';
        final keywords = system['adas_keywords']?.toString() ?? '';
        
        // Try to extract from name first
        String make = _extractVehicleMake(name);
        
        // If not found in name, try keywords (where Excel import stores the Make)
        if (make == 'UNKNOWN' && keywords.isNotEmpty) {
          make = _extractVehicleMake(keywords);
        }
        
        if (make != 'UNKNOWN') {
          makeSet.add(make);
        }
      }
      
      final makes = makeSet.toList()..sort();
      
      setState(() {
        _vehicleMakes = makes;
        _isLoading = false;
      });
      
      print('✅ Found ${makes.length} vehicle makes in calibration_systems table');
      if (makes.isEmpty && systems.isNotEmpty) {
        print('⚠️  Warning: Found ${systems.length} systems but no vehicle makes could be extracted');
        print('   Sample system name: ${systems.first['name']}');
        print('   Sample keywords: ${systems.first['adas_keywords']}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading vehicle makes: $e')),
        );
      }
    }
  }

  Future<void> _loadYearsForMake(String make) async {
    setState(() => _isLoading = true);
    try {
      if (_database == null) throw Exception('Database not initialized');
      
      // Query systems for this make
      final systems = await _database!.query('calibration_systems');
      
      // Extract unique years from system names that match this make
      final yearSet = <String>{};
      for (final system in systems) {
        final name = system['name']?.toString() ?? '';
        final keywords = system['adas_keywords']?.toString() ?? '';
        
        // Check if this system matches the make (check both name and keywords)
        String systemMake = _extractVehicleMake(name);
        if (systemMake == 'UNKNOWN') {
          systemMake = _extractVehicleMake(keywords);
        }
        
        if (systemMake == make) {
          // Extract year from name (most Excel files include year in a column that might be in name)
          final year = _extractYear(name);
          if (year.isNotEmpty) {
            yearSet.add(year);
          }
        }
      }
      
      final years = yearSet.toList()..sort((a, b) => b.compareTo(a)); // Descending
      
      setState(() {
        _years = years;
        _isLoading = false;
      });
      
      print('✅ Found ${years.length} years for $make');
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading years: $e')),
        );
      }
    }
  }

  Future<void> _loadModelsForMakeAndYear(String make, String year) async {
    setState(() => _isLoading = true);
    try {
      if (_database == null) throw Exception('Database not initialized');
      
      // Query systems for this make and year
      final systems = await _database!.query('calibration_systems');
      
      // Extract unique models from system names that match this make and year
      final modelSet = <String>{};
      for (final system in systems) {
        final name = system['name']?.toString() ?? '';
        final systemMake = _extractVehicleMake(name);
        final systemYear = _extractYear(name);
        if (systemMake == make && systemYear == year) {
          final model = _extractModel(name, make, year);
          if (model.isNotEmpty) {
            modelSet.add(model);
          }
        }
      }
      
      final models = modelSet.toList()..sort();
      
      setState(() {
        _models = models;
        _isLoading = false;
      });
      
      print('✅ Found ${models.length} models for $make $year');
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading models: $e')),
        );
      }
    }
  }

  Future<void> _loadSystemsForVehicle(String make, String year, String model) async {
    setState(() => _isLoading = true);
    try {
      if (_database == null) throw Exception('Database not initialized');
      
      // Query all systems and filter by make/year/model
      final systems = await _database!.query('calibration_systems');
      
      final matchingSystems = <Map<String, dynamic>>[];
      for (final system in systems) {
        final name = system['name']?.toString() ?? '';
        final systemMake = _extractVehicleMake(name);
        final systemYear = _extractYear(name);
        final systemModel = _extractModel(name, make, year);
        
        if (systemMake == make && systemYear == year && systemModel == model) {
          matchingSystems.add(system);
        }
      }
      
      setState(() {
        _currentSystems = matchingSystems;
        _isLoading = false;
      });
      
      print('✅ Found ${matchingSystems.length} systems for $make $year $model');
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading systems: $e')),
        );
      }
    }
  }

  String _extractVehicleMake(String name) {
    final makes = [
      'acura', 'alfa romeo', 'audi', 'bmw', 'buick', 'cadillac', 'chevrolet', 'chrysler',
      'dodge', 'fiat', 'ford', 'gmc', 'genesis', 'honda', 'hyundai', 'infiniti',
      'jaguar', 'jeep', 'kia', 'land rover', 'lexus', 'lincoln', 'mazda', 'mercedes',
      'mini', 'mitsubishi', 'nissan', 'porsche', 'ram', 'subaru', 'tesla', 'toyota',
      'volkswagen', 'volvo', 'gm',
    ];
    
    final lowerName = name.toLowerCase();
    for (final make in makes) {
      if (lowerName.contains(make)) {
        return make.toUpperCase();
      }
    }
    
    return 'UNKNOWN';
  }

  String _extractYear(String name) {
    // Look for 4-digit year (2015-2030)
    final yearRegex = RegExp(r'\b(20[1-3][0-9])\b');
    final match = yearRegex.firstMatch(name);
    return match?.group(1) ?? '';
  }

  String _extractModel(String name, String make, String year) {
    // Remove make and year from name to get model
    String model = name;
    model = model.replaceAll(RegExp(make, caseSensitive: false), '').trim();
    model = model.replaceAll(year, '').trim();
    
    // Extract the first word/phrase as model
    final modelMatch = RegExp(r'([A-Za-z0-9\-]+)').firstMatch(model);
    return modelMatch?.group(1)?.toUpperCase() ?? '';
  }

  void _goBack() {
    setState(() {
      if (_selectedVehicleMake != null) {
        // Go back from systems to makes
        _selectedVehicleMake = null;
        _currentSystems = [];
        _searchQuery = '';
      }
    });
  }

  List<Map<String, dynamic>> get _filteredSystems {
    if (_searchQuery.isEmpty) return _currentSystems;
    
    return _currentSystems.where((system) {
      final searchLower = _searchQuery.toLowerCase();
      return system.values.any((value) {
        return value?.toString().toLowerCase().contains(searchLower) ?? false;
      });
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final showBackButton = _selectedVehicleMake != null;
    
    return Scaffold(
      appBar: AppBar(
        leading: showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _goBack,
              )
            : null,
        title: Text(_currentTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_selectedVehicleMake != null) _buildSearchBar(),
          if (_selectedVehicleMake != null) _buildSystemCount(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildCurrentView(),
          ),
        ],
      ),
    );
  }

  void _refresh() {
    if (_selectedVehicleMake != null) {
      _loadSystemsForMake(_selectedVehicleMake!);
    } else {
      _loadVehicleMakes();
    }
  }

  Future<void> _loadSystemsForMake(String make) async {
    setState(() => _isLoading = true);
    try {
      if (_database == null) throw Exception('Database not initialized');
      
      // Query all systems and filter by make
      final systems = await _database!.query('calibration_systems');
      
      final matchingSystems = <Map<String, dynamic>>[];
      for (final system in systems) {
        final name = system['name']?.toString() ?? '';
        final keywords = system['adas_keywords']?.toString() ?? '';
        
        // Check if this system matches the make (check both name and keywords)
        String systemMake = _extractVehicleMake(name);
        if (systemMake == 'UNKNOWN') {
          systemMake = _extractVehicleMake(keywords);
        }
        
        if (systemMake == make) {
          matchingSystems.add(system);
        }
      }
      
      setState(() {
        _currentSystems = matchingSystems;
        _isLoading = false;
      });
      
      print('✅ Found ${matchingSystems.length} systems for $make');
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading systems: $e')),
        );
      }
    }
  }

  Widget _buildCurrentView() {
    if (_selectedVehicleMake != null) {
      // Level 2: Show systems for selected make
      return _filteredSystems.isEmpty
          ? _buildEmptyState()
          : _buildSystemsList();
    } else {
      // Level 1: Show vehicle makes
      return _buildVehicleList();
    }
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search systems...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildVehicleList() {
    if (_vehicleMakes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No vehicles found in NiccDB.db',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Make sure NiccDB.db is in the app root folder',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _vehicleMakes.length,
      itemBuilder: (context, index) {
        final make = _vehicleMakes[index];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue,
              child: const Icon(
                Icons.directions_car,
                color: Colors.white,
              ),
            ),
            title: Text(
              make,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: const Text('Tap to view systems'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              setState(() {
                _selectedVehicleMake = make;
              });
              await _loadSystemsForMake(make);
            },
          ),
        );
      },
    );
  }

  Widget _buildYearsList() {
    if (_years.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No years found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _years.length,
      itemBuilder: (context, index) {
        final year = _years[index];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green,
              child: const Icon(
                Icons.calendar_today,
                color: Colors.white,
              ),
            ),
            title: Text(
              year,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: const Text('Tap to view models'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              setState(() {
                _selectedYear = year;
              });
              await _loadModelsForMakeAndYear(_selectedVehicleMake!, year);
            },
          ),
        );
      },
    );
  }

  Widget _buildModelsList() {
    if (_models.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.car_rental, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No models found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _models.length,
      itemBuilder: (context, index) {
        final model = _models[index];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange,
              child: const Icon(
                Icons.car_rental,
                color: Colors.white,
              ),
            ),
            title: Text(
              model,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: const Text('Tap to view systems'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              setState(() {
                _selectedModel = model;
              });
              await _loadSystemsForVehicle(_selectedVehicleMake!, _selectedYear!, model);
            },
          ),
        );
      },
    );
  }

  Widget _buildSystemCount() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            '${_filteredSystems.length} ${_filteredSystems.length == 1 ? 'record' : 'records'}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          if (_searchQuery.isNotEmpty && _filteredSystems.length != _currentSystems.length)
            Text(
              ' (filtered from ${_currentSystems.length})',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.storage, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No systems found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredSystems.length,
      itemBuilder: (context, index) {
        final system = _filteredSystems[index];
        return _buildSystemCard(system);
      },
    );
  }

  Widget _buildSystemCard(Map<String, dynamic> system) {
    // Display using the calibration_systems table structure
    final title = system['name']?.toString() ?? 'System Record';
    final category = system['category']?.toString() ?? '';
    final description = system['description']?.toString() ?? '';
    
    String subtitle = category.isNotEmpty ? category : description;
    if (subtitle.isEmpty) {
      subtitle = '${system.length} fields';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple,
          child: const Icon(
            Icons.settings_input_component,
            color: Colors.white,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey[600]),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('ID', system['id']?.toString() ?? ''),
                _buildDetailRow('Name', system['name']?.toString() ?? ''),
                _buildDetailRow('Description', system['description']?.toString() ?? ''),
                _buildDetailRow('Category', system['category']?.toString() ?? ''),
                _buildDetailRow('Estimated Time', system['estimated_time']?.toString() ?? ''),
                _buildDetailRow('Estimated Cost', system['estimated_cost']?.toString() ?? ''),
                _buildDetailRow('Equipment Needed', system['equipment_needed']?.toString() ?? ''),
                _buildDetailRow('Required For', system['required_for']?.toString() ?? ''),
                _buildDetailRow('Pre-Qualifications', system['pre_qualifications']?.toString() ?? ''),
                if (system['hyperlink']?.toString().isNotEmpty ?? false)
                  _buildDetailRow('Hyperlink', system['hyperlink']!.toString()),
                _buildDetailRow('ADAS Keywords', system['adas_keywords']?.toString() ?? ''),
                _buildDetailRow('Priority', system['priority']?.toString() ?? ''),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: SelectableText(value.isEmpty ? '(empty)' : value),
          ),
        ],
      ),
    );
  }
}
