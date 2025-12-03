import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as path;

class NiccDBService {
  Database? _niccDb;

  /// Open connection to NiccDB.db
  Future<Database> get database async {
    if (_niccDb != null) return _niccDb!;
    
    // Initialize FFI
    sqfliteFfiInit();
    
    // Look for NiccDB.db in the workspace root
    final workspaceRoot = Directory.current.path;
    final dbPath = path.join(workspaceRoot, 'NiccDB.db');
    
    final file = File(dbPath);
    if (!await file.exists()) {
      throw Exception('NiccDB.db not found at: $dbPath');
    }
    
    _niccDb = await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(readOnly: true),
    );
    
    return _niccDb!;
  }

  /// Get all available tables in NiccDB.db
  Future<List<String>> getTables() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
    );
    return result.map((row) => row['name'] as String).toList();
  }

  /// Get all vehicle makes from NiccDB.db
  Future<List<String>> getVehicleMakes() async {
    final db = await database;
    
    // Try to find a column with vehicle makes
    // This will depend on your actual NiccDB.db structure
    try {
      final tables = await getTables();
      print('📋 NiccDB.db tables: $tables');
      
      // Try common table and column names
      for (final table in tables) {
        try {
          final columns = await db.rawQuery('PRAGMA table_info($table)');
          final columnNames = columns.map((c) => (c['name'] as String).toLowerCase()).toList();
          
          print('   Table: $table, Columns: $columnNames');
          
          // Look for make/manufacturer columns
          if (columnNames.contains('make') || 
              columnNames.contains('manufacturer') || 
              columnNames.contains('oem')) {
            
            final makeColumn = columnNames.contains('make') 
                ? 'make' 
                : columnNames.contains('manufacturer') 
                    ? 'manufacturer' 
                    : 'oem';
            
            final result = await db.rawQuery(
              'SELECT DISTINCT $makeColumn FROM $table WHERE $makeColumn IS NOT NULL AND $makeColumn != "" ORDER BY $makeColumn'
            );
            
            final makes = result
                .map((row) => row[makeColumn] as String?)
                .where((make) => make != null && make.isNotEmpty)
                .map((make) => make!.toUpperCase())
                .toSet()
                .toList()
              ..sort();
            
            if (makes.isNotEmpty) {
              print('✅ Found ${makes.length} vehicle makes in table: $table');
              return makes;
            }
          }
        } catch (e) {
          print('⚠️  Error checking table $table: $e');
        }
      }
    } catch (e) {
      print('❌ Error reading NiccDB.db: $e');
    }
    
    return [];
  }

  /// Get all years for a specific vehicle make
  Future<List<String>> getYearsForMake(String make) async {
    final db = await database;
    
    try {
      // Table name is usually the lowercase make name with underscores
      final tableName = make.toLowerCase().replaceAll(' ', '_');
      
      final columns = await db.rawQuery('PRAGMA table_info($tableName)');
      final columnNames = columns.map((c) => (c['name'] as String).toLowerCase()).toList();
      
      if (columnNames.contains('year')) {
        final result = await db.rawQuery(
          'SELECT DISTINCT year FROM $tableName WHERE year IS NOT NULL AND year != "" ORDER BY year DESC'
        );
        
        final years = result
            .map((row) => row['year']?.toString() ?? '')
            .where((year) => year.isNotEmpty)
            .toSet()
            .toList();
        
        print('✅ Found ${years.length} years for $make');
        return years;
      }
    } catch (e) {
      print('⚠️  Error getting years for $make: $e');
    }
    
    return [];
  }

  /// Get all models for a specific vehicle make and year
  Future<List<String>> getModelsForMakeAndYear(String make, String year) async {
    final db = await database;
    
    try {
      final tableName = make.toLowerCase().replaceAll(' ', '_');
      
      final columns = await db.rawQuery('PRAGMA table_info($tableName)');
      final columnNames = columns.map((c) => (c['name'] as String).toLowerCase()).toList();
      
      if (columnNames.contains('model') && columnNames.contains('year')) {
        final result = await db.rawQuery(
          'SELECT DISTINCT model FROM $tableName WHERE year = ? AND model IS NOT NULL AND model != "" ORDER BY model',
          [year],
        );
        
        final models = result
            .map((row) => row['model']?.toString() ?? '')
            .where((model) => model.isNotEmpty)
            .toSet()
            .toList();
        
        print('✅ Found ${models.length} models for $make $year');
        return models;
      }
    } catch (e) {
      print('⚠️  Error getting models for $make $year: $e');
    }
    
    return [];
  }

  /// Get all systems for a specific vehicle make, year, and model
  Future<List<Map<String, dynamic>>> getSystemsForVehicle(String make, String year, String model) async {
    final db = await database;
    
    try {
      final tableName = make.toLowerCase().replaceAll(' ', '_');
      
      final result = await db.rawQuery(
        'SELECT * FROM $tableName WHERE year = ? AND model = ? ORDER BY rowid',
        [year, model],
      );
      
      print('✅ Found ${result.length} systems for $make $year $model');
      return result;
    } catch (e) {
      print('❌ Error getting systems for $make $year $model: $e');
    }
    
    return [];
  }

  /// Get schema for a specific table
  Future<List<Map<String, dynamic>>> getTableSchema(String tableName) async {
    final db = await database;
    return await db.rawQuery('PRAGMA table_info($tableName)');
  }

  /// Close the database connection
  Future<void> close() async {
    await _niccDb?.close();
    _niccDb = null;
  }
}

