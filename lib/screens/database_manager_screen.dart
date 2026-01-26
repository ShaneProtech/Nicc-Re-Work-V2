import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../models/calibration_system.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:url_launcher/url_launcher.dart';

class DatabaseManagerScreen extends StatefulWidget {
  const DatabaseManagerScreen({Key? key}) : super(key: key);

  @override
  State<DatabaseManagerScreen> createState() => _DatabaseManagerScreenState();
}

class _DatabaseManagerScreenState extends State<DatabaseManagerScreen> with WidgetsBindingObserver {
  Database? _database;
  List<String> _vehicleMakes = [];
  List<String> _years = [];
  List<String> _models = [];
  List<String> _systemTypes = [];  // Protech Generic System Names
  List<Map<String, dynamic>> _currentSystems = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedVehicleMake;
  String? _selectedYear;
  String? _selectedModel;
  String? _selectedSystemType;  // Selected Protech Generic System Name
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load on first display
    if (!_hasInitialized) {
      _hasInitialized = true;
      _initDatabase();
    }
  }

  @override
  void didUpdateWidget(DatabaseManagerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload when widget updates (e.g., returning from another screen)
    _initDatabase();
  }

  @override
  void activate() {
    super.activate();
    // Reload when screen becomes active again
    _initDatabase();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _initDatabase();
    }
  }

  Future<void> _initDatabase() async {
    try {
      final dbService = context.read<DatabaseService>();
      _database = dbService.databaseSync;
      if (_database != null) {
        // Always load fresh data from database
        await _loadVehicleMakes();
        
        // Reload based on current navigation level
        if (_selectedSystemType != null && _selectedModel != null && _selectedYear != null && _selectedVehicleMake != null) {
          await _loadSystemsForVehicleAndType(_selectedVehicleMake!, _selectedYear!, _selectedModel!, _selectedSystemType!);
        } else if (_selectedModel != null && _selectedYear != null && _selectedVehicleMake != null) {
          await _loadSystemTypesForVehicle(_selectedVehicleMake!, _selectedYear!, _selectedModel!);
        } else if (_selectedYear != null && _selectedVehicleMake != null) {
          await _loadModelsForMakeAndYear(_selectedVehicleMake!, _selectedYear!);
        } else if (_selectedVehicleMake != null) {
          await _loadYearsForMake(_selectedVehicleMake!);
        }
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
    if (_selectedSystemType != null) {
      return '$_selectedVehicleMake $_selectedYear $_selectedModel - $_selectedSystemType';
    }
    if (_selectedModel != null) {
      return '$_selectedVehicleMake $_selectedYear $_selectedModel - Systems';
    }
    if (_selectedYear != null) {
      return '$_selectedVehicleMake $_selectedYear - Models';
    }
    if (_selectedVehicleMake != null) {
      return '$_selectedVehicleMake - Years';
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
      
      // Extract unique makes from vehicle_make column (primary) or fallback to extraction
      final makeSet = <String>{};
      for (final system in systems) {
        // First try the dedicated vehicle_make column
        String make = system['vehicle_make']?.toString().trim() ?? '';
        
        // If vehicle_make is empty, try to extract from adas_keywords or name (legacy fallback)
        if (make.isEmpty) {
          final keywords = system['adas_keywords']?.toString() ?? '';
          final name = system['name']?.toString() ?? '';
          
          make = _extractVehicleMake(keywords);
          if (make == 'UNKNOWN') {
            make = _extractVehicleMake(name);
          }
        }
        
        if (make.isNotEmpty && make != 'UNKNOWN') {
          // Normalize to uppercase for consistency
          makeSet.add(make.toUpperCase());
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
        print('   Sample system: ${systems.first}');
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
      
      // Extract unique years from vehicle_year column that match this make
      final yearSet = <String>{};
      for (final system in systems) {
        // Get the system's make - use vehicle_make column first, then fallback to extraction
        String systemMake = system['vehicle_make']?.toString().trim().toUpperCase() ?? '';
        if (systemMake.isEmpty) {
          final keywords = system['adas_keywords']?.toString() ?? '';
          final name = system['name']?.toString() ?? '';
          systemMake = _extractVehicleMake(keywords);
          if (systemMake == 'UNKNOWN') {
            systemMake = _extractVehicleMake(name);
          }
        }
        
        if (systemMake == make) {
          // Use vehicle_year column directly
          final year = system['vehicle_year']?.toString().trim() ?? '';
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
      
      // Extract unique models from vehicle_model column that match this make and year
      final modelSet = <String>{};
      for (final system in systems) {
        final systemYear = system['vehicle_year']?.toString().trim() ?? '';
        
        // Get the system's make - use vehicle_make column first, then fallback to extraction
        String systemMake = system['vehicle_make']?.toString().trim().toUpperCase() ?? '';
        if (systemMake.isEmpty) {
          final keywords = system['adas_keywords']?.toString() ?? '';
          final name = system['name']?.toString() ?? '';
          systemMake = _extractVehicleMake(keywords);
          if (systemMake == 'UNKNOWN') {
            systemMake = _extractVehicleMake(name);
          }
        }
        
        if (systemMake == make && systemYear == year) {
          // Use vehicle_model column directly
          final model = system['vehicle_model']?.toString().trim() ?? '';
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

  /// Load unique system types (Protech Generic System Names) for a specific vehicle
  Future<void> _loadSystemTypesForVehicle(String make, String year, String model) async {
    setState(() => _isLoading = true);
    try {
      if (_database == null) throw Exception('Database not initialized');
      
      // Query all systems and filter by make/year/model
      final systems = await _database!.query('calibration_systems');
      
      // Extract unique system names (Protech Generic System Names) for this vehicle
      final systemTypeSet = <String>{};
      for (final system in systems) {
        final systemName = system['name']?.toString() ?? '';
        final systemYear = system['vehicle_year']?.toString().trim() ?? '';
        final systemModel = system['vehicle_model']?.toString().trim() ?? '';
        
        // Get the system's make - use vehicle_make column first, then fallback to extraction
        String systemMake = system['vehicle_make']?.toString().trim().toUpperCase() ?? '';
        if (systemMake.isEmpty) {
          final keywords = system['adas_keywords']?.toString() ?? '';
          systemMake = _extractVehicleMake(keywords);
          if (systemMake == 'UNKNOWN') {
            systemMake = _extractVehicleMake(systemName);
          }
        }
        
        if (systemMake == make && systemYear == year && systemModel == model) {
          // Use the name field which contains "Protech Generic System Name"
          if (systemName.isNotEmpty) {
            systemTypeSet.add(systemName);
          }
        }
      }
      
      final systemTypes = systemTypeSet.toList()..sort();
      
      setState(() {
        _systemTypes = systemTypes;
        _isLoading = false;
      });
      
      print('✅ Found ${systemTypes.length} system types for $make $year $model');
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading system types: $e')),
        );
      }
    }
  }

  /// Load individual system records for a specific vehicle and system type
  Future<void> _loadSystemsForVehicleAndType(String make, String year, String model, String systemType) async {
    setState(() => _isLoading = true);
    try {
      if (_database == null) throw Exception('Database not initialized');
      
      // Query all systems and filter by make/year/model/systemType
      final systems = await _database!.query('calibration_systems');
      
      final matchingSystems = <Map<String, dynamic>>[];
      for (final system in systems) {
        final systemName = system['name']?.toString() ?? '';
        final systemYear = system['vehicle_year']?.toString().trim() ?? '';
        final systemModel = system['vehicle_model']?.toString().trim() ?? '';
        
        // Get the system's make - use vehicle_make column first, then fallback to extraction
        String systemMake = system['vehicle_make']?.toString().trim().toUpperCase() ?? '';
        if (systemMake.isEmpty) {
          final keywords = system['adas_keywords']?.toString() ?? '';
          systemMake = _extractVehicleMake(keywords);
          if (systemMake == 'UNKNOWN') {
            systemMake = _extractVehicleMake(systemName);
          }
        }
        
        if (systemMake == make && systemYear == year && systemModel == model && systemName == systemType) {
          matchingSystems.add(system);
        }
      }
      
      setState(() {
        _currentSystems = matchingSystems;
        _isLoading = false;
      });
      
      print('✅ Found ${matchingSystems.length} records for $make $year $model - $systemType');
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
      if (_selectedSystemType != null) {
        // Go back from individual records to system types
        _selectedSystemType = null;
        _currentSystems = [];
        _searchQuery = '';
      } else if (_selectedModel != null) {
        // Go back from system types to models
        _selectedModel = null;
        _systemTypes = [];
      } else if (_selectedYear != null) {
        // Go back from models to years
        _selectedYear = null;
        _models = [];
      } else if (_selectedVehicleMake != null) {
        // Go back from years to makes
        _selectedVehicleMake = null;
        _years = [];
      }
    });
  }

  Future<void> _showClearAllConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Clear All Data?'),
          ],
        ),
        content: const Text(
          'This will permanently delete ALL calibration systems from the database.\n\n'
          'This action cannot be undone!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _clearAllData();
    }
  }

  Future<void> _clearAllData() async {
    try {
      if (_database == null) return;
      
      await _database!.delete('calibration_systems');
      
      setState(() {
        _vehicleMakes = [];
        _years = [];
        _models = [];
        _systemTypes = [];
        _currentSystems = [];
        _selectedVehicleMake = null;
        _selectedYear = null;
        _selectedModel = null;
        _selectedSystemType = null;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ All data cleared successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing data: $e')),
        );
      }
    }
  }

  Future<void> _showDeleteMakeConfirmation(String make) async {
    final count = _currentSystems.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 8),
            Text('Delete $make?'),
          ],
        ),
        content: Text(
          'This will delete $count system${count == 1 ? '' : 's'} for $make.\n\n'
          'This action cannot be undone!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteSystemsForMake(make);
    }
  }

  Future<void> _deleteSystemsForMake(String make) async {
    try {
      if (_database == null) return;
      
      int deletedCount = 0;
      for (final system in _currentSystems) {
        await _database!.delete(
          'calibration_systems',
          where: 'id = ?',
          whereArgs: [system['id']],
        );
        deletedCount++;
      }
      
      // Go back to vehicle list and refresh
      setState(() {
        _selectedVehicleMake = null;
        _selectedYear = null;
        _selectedModel = null;
        _selectedSystemType = null;
        _years = [];
        _models = [];
        _systemTypes = [];
        _currentSystems = [];
      });
      await _loadVehicleMakes();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Deleted $deletedCount systems for $make'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting systems: $e')),
        );
      }
    }
  }

  Future<void> _deleteSystem(Map<String, dynamic> system) async {
    final name = system['name']?.toString() ?? 'this system';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete System?'),
          ],
        ),
        content: Text('Delete "$name"?\n\nThis cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        if (_database == null) return;
        
        await _database!.delete(
          'calibration_systems',
          where: 'id = ?',
          whereArgs: [system['id']],
        );
        
        // Refresh current view
        if (_selectedSystemType != null) {
          await _loadSystemsForVehicleAndType(_selectedVehicleMake!, _selectedYear!, _selectedModel!, _selectedSystemType!);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ System deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting system: $e')),
          );
        }
      }
    }
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
    final showSearchBar = _selectedSystemType != null; // Only show search when viewing individual records
    
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More options',
            onSelected: (value) {
              switch (value) {
                case 'clear_all':
                  _showClearAllConfirmation();
                  break;
                case 'delete_make':
                  if (_selectedVehicleMake != null) {
                    _showDeleteMakeConfirmation(_selectedVehicleMake!);
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'clear_all',
                child: ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Clear All Data'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              if (_selectedSystemType != null)
                PopupMenuItem(
                  value: 'delete_make',
                  child: ListTile(
                    leading: const Icon(Icons.delete_sweep, color: Colors.orange),
                    title: Text('Delete All $_selectedVehicleMake'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (showSearchBar) _buildSearchBar(),
          if (showSearchBar) _buildSystemCount(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildCurrentView(),
          ),
        ],
      ),
    );
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    
    try {
      if (_selectedSystemType != null) {
        await _loadSystemsForVehicleAndType(_selectedVehicleMake!, _selectedYear!, _selectedModel!, _selectedSystemType!);
      } else if (_selectedModel != null) {
        await _loadSystemTypesForVehicle(_selectedVehicleMake!, _selectedYear!, _selectedModel!);
      } else if (_selectedYear != null) {
        await _loadModelsForMakeAndYear(_selectedVehicleMake!, _selectedYear!);
      } else if (_selectedVehicleMake != null) {
        await _loadYearsForMake(_selectedVehicleMake!);
      } else {
        await _loadVehicleMakes();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Database refreshed'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  Widget _buildCurrentView() {
    if (_selectedSystemType != null) {
      // Level 5: Show individual records for selected make/year/model/system type
      return _filteredSystems.isEmpty
          ? _buildEmptyState()
          : _buildSystemsList();
    } else if (_selectedModel != null) {
      // Level 4: Show system types (Protech Generic System Names) for selected make/year/model
      return _buildSystemTypesList();
    } else if (_selectedYear != null) {
      // Level 3: Show models for selected make/year
      return _buildModelsList();
    } else if (_selectedVehicleMake != null) {
      // Level 2: Show years for selected make
      return _buildYearsList();
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
              'No vehicles found in database',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Import data using "Update Database" first',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              onPressed: _refresh,
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
            subtitle: const Text('Tap to view years'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              setState(() {
                _selectedVehicleMake = make;
              });
              await _loadYearsForMake(make);
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
              await _loadSystemTypesForVehicle(_selectedVehicleMake!, _selectedYear!, model);
            },
          ),
        );
      },
    );
  }

  Widget _buildSystemTypesList() {
    if (_systemTypes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.settings_input_component, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No systems found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'No calibration systems available for this vehicle',
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
      itemCount: _systemTypes.length,
      itemBuilder: (context, index) {
        final systemType = _systemTypes[index];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.purple,
              child: const Icon(
                Icons.settings_input_component,
                color: Colors.white,
              ),
            ),
            title: Text(
              systemType,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: const Text('Tap to view details'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              setState(() {
                _selectedSystemType = systemType;
              });
              await _loadSystemsForVehicleAndType(_selectedVehicleMake!, _selectedYear!, _selectedModel!, systemType);
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _deleteSystem(system),
              tooltip: 'Delete this system',
            ),
            const Icon(Icons.expand_more),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('ID', system['id']?.toString() ?? ''),
                _buildDetailRow('Name', system['name']?.toString() ?? ''),
                _buildDetailRow('Vehicle Make', system['vehicle_make']?.toString() ?? ''),
                _buildDetailRow('Vehicle Year', system['vehicle_year']?.toString() ?? ''),
                _buildDetailRow('Vehicle Model', system['vehicle_model']?.toString() ?? ''),
                _buildDetailRow('Category', system['category']?.toString() ?? ''),
                // Hidden fields: Estimated Time, Estimated Cost, Equipment Needed, Required For, Description, ADAS Keywords
                _buildPreQualificationsSection(system['pre_qualifications']?.toString() ?? ''),
                if (system['hyperlink']?.toString().isNotEmpty ?? false)
                  _buildHyperlinkButton(system['hyperlink']!.toString()),
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

  /// Build Pre-Qualifications section with better formatting
  Widget _buildPreQualificationsSection(String preQuals) {
    // Check if empty
    if (preQuals.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              width: 160,
              child: Text(
                'Pre-Qualifications:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Text(
                '(none specified)',
                style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      );
    }

    // Parse pre-qualifications - they may be comma-separated or newline-separated
    List<String> items = [];
    if (preQuals.contains('\n')) {
      items = preQuals.split('\n');
    } else if (preQuals.contains(',')) {
      items = preQuals.split(',');
    } else {
      items = [preQuals];
    }
    
    // Clean up items
    items = items.map((item) => item.trim()).where((item) => item.isNotEmpty).toList();

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              width: 160,
              child: Text(
                'Pre-Qualifications:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Text(
                '(none specified)',
                style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.checklist, size: 20, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Pre-Qualifications:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SelectableText(
                        item,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Strip URLs from text
  String _stripUrls(String text) {
    if (text.isEmpty) return text;
    // Remove URLs (http, https, www)
    return text
        .replaceAll(RegExp(r'https?://[^\s]+'), '')
        .replaceAll(RegExp(r'www\.[^\s]+'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Build a clickable hyperlink button
  Widget _buildHyperlinkButton(String url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 160,
            child: Text(
              'Service Info:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('View Documentation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: () => _openUrl(url),
            ),
          ),
        ],
      ),
    );
  }

  /// Open URL in the default browser
  Future<void> _openUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open the link'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
