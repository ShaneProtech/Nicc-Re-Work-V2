import 'dart:io';
import 'dart:async';
import 'package:excel/excel.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/calibration_system.dart';

class ImportProgress {
  final int totalFiles;
  final int processedFiles;
  final int totalBytes;
  final int processedBytes;
  final String currentFileName;
  final int recordsImported;

  ImportProgress({
    required this.totalFiles,
    required this.processedFiles,
    required this.totalBytes,
    required this.processedBytes,
    required this.currentFileName,
    required this.recordsImported,
  });

  double get percentage => totalBytes > 0 ? (processedBytes / totalBytes) : 0.0;
}

class ExcelImportService {
  final Database database;

  ExcelImportService(this.database);

  /// Import Excel files from a directory with progress updates
  Stream<ImportProgress> importFromDirectoryWithProgress(String directoryPath) async* {
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        throw Exception('Directory does not exist');
      }

      // Get all Excel files in the directory
      final files = directory
          .listSync()
          .where((file) =>
              file is File &&
              (file.path.endsWith('.xlsx') || file.path.endsWith('.xls')))
          .cast<File>()
          .toList();

      if (files.isEmpty) {
        throw Exception('No Excel files found in directory');
      }

      // Calculate total size
      int totalBytes = 0;
      for (final file in files) {
        totalBytes += await file.length();
      }

      int processedBytes = 0;
      int totalImported = 0;

      // Process each Excel file
      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        final fileName = path.basename(file.path);
        final fileSize = await file.length();

        try {
          // Yield progress IMMEDIATELY before processing (this shows the filename)
          yield ImportProgress(
            totalFiles: files.length,
            processedFiles: i,
            totalBytes: totalBytes,
            processedBytes: processedBytes,
            currentFileName: fileName,
            recordsImported: totalImported,
          );

          // Allow UI to update
          await Future.delayed(const Duration(milliseconds: 50));

          // Import the file (this is where the time is spent)
          print('⏱️  Processing ${fileName}... (this may take a while for large files)');
          final imported = await _importExcelFile(file);
          
          totalImported += imported;
          processedBytes += fileSize;

          // Yield progress after processing (this updates the progress bar)
          yield ImportProgress(
            totalFiles: files.length,
            processedFiles: i + 1,
            totalBytes: totalBytes,
            processedBytes: processedBytes,
            currentFileName: fileName,
            recordsImported: totalImported,
          );

          // Allow UI to update
          await Future.delayed(const Duration(milliseconds: 50));
        } catch (e) {
          print('Error importing ${file.path}: $e');
          processedBytes += fileSize;
        }
      }
    } catch (e) {
      throw Exception('Import error: ${e.toString()}');
    }
  }

  /// Import Excel files from a directory (legacy method for compatibility)
  Future<Map<String, dynamic>> importFromDirectory(String directoryPath) async {
    try {
      int totalImported = 0;
      int filesProcessed = 0;
      final results = <String, int>{};

      await for (final progress in importFromDirectoryWithProgress(directoryPath)) {
        totalImported = progress.recordsImported;
        filesProcessed = progress.processedFiles;
      }

      return {
        'success': true,
        'message': 'Successfully imported $totalImported records from $filesProcessed files',
        'totalRecords': totalImported,
        'filesProcessed': filesProcessed,
        'fileResults': results,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  /// Import a single Excel file
  Future<int> _importExcelFile(File file) async {
    print('📄 Reading file: ${path.basename(file.path)}');
    final bytes = await file.readAsBytes();
    
    print('📊 Parsing Excel file (${_formatBytes(bytes.length)})... Please wait...');
    // Yield control to allow UI updates
    await Future.delayed(const Duration(milliseconds: 50));
    
    final excel = Excel.decodeBytes(bytes);
    print('✅ Found ${excel.tables.length} sheets');

    int importedCount = 0;

    // Process each sheet
    for (final sheetName in excel.tables.keys) {
      final sheet = excel.tables[sheetName];
      if (sheet == null || sheet.rows.isEmpty) continue;

      // First row is the header
      final headerRow = sheet.rows[0];
      final headers = headerRow.map((cell) => cell?.value?.toString()?.trim() ?? '').toList();

      // Check if this looks like ADAS systems data
      if (_isADASSystemSheet(headers)) {
        print('   Processing sheet: $sheetName (${sheet.rows.length - 1} data rows)...');
        final imported = await _importADASSystemsFromSheet(sheet, headers, 0);
        importedCount += imported;
        print('   ✓ Imported $imported records from $sheetName');
      } else {
        print('   ⊘ Skipping non-ADAS sheet: $sheetName');
      }
      
      // Yield control after each sheet
      await Future.delayed(const Duration(milliseconds: 50));
    }

    print('📦 Total imported from file: $importedCount records\n');
    return importedCount;
  }

  /// Check if the sheet contains ADAS systems data
  bool _isADASSystemSheet(List<String> headers) {
    // Look for common ADAS system column names
    final adasColumns = [
      'system',
      'name',
      'adas',
      'calibration',
      'pre-qualification',
      'prequalification',
      'hyperlink',
      'link',
      'keyword',
      'component',
      'oem',
      'vehicle',
      'make',
      'model',
    ];

    final lowerHeaders = headers.map((h) => h.toLowerCase()).toList();
    return adasColumns.any((col) => lowerHeaders.any((h) => h.contains(col)));
  }

  /// Import ADAS systems from an Excel sheet - UPDATE existing or INSERT new
  /// Each unique combination of name + year + model creates a separate record
  Future<int> _importADASSystemsFromSheet(
    Sheet sheet,
    List<String> headers,
    int headerRowIndex,
  ) async {
    // Map Excel columns directly to database column names
    final columnMap = _mapColumnsToDatabase(headers);
    
    if (columnMap.isEmpty) {
      print('   ⊘ No matching columns found - skipping this sheet');
      return 0;
    }

    // Must have a name column to import
    if (!columnMap.containsKey('name')) {
      print('   ⊘ No system name column found - skipping this sheet');
      return 0;
    }

    print('   Found ${columnMap.length} matching database columns');
    
    // Get all existing systems from database for matching
    final existingSystems = await database.query('calibration_systems');
    print('   Database has ${existingSystems.length} existing records');
    
    // Build a lookup map for existing records by compound key (name + make + year + model)
    final existingByKey = <String, Map<String, dynamic>>{};
    for (final record in existingSystems) {
      final name = (record['name'] as String?)?.toLowerCase() ?? '';
      final make = (record['vehicle_make'] as String?)?.toLowerCase().trim() ?? '';
      final year = (record['vehicle_year'] as String?)?.toLowerCase().trim() ?? '';
      final model = (record['vehicle_model'] as String?)?.toLowerCase().trim() ?? '';
      final key = '$name|$make|$year|$model';
      existingByKey[key] = record;
    }
    
    int updatedCount = 0;
    int insertedCount = 0;
    
    print('   Processing Excel rows...');
    
    // Process each row - update if exists, insert if new
    // Match by COMPOUND KEY: name + year + model (so each vehicle/system combo is unique)
    await database.transaction((txn) async {
      for (int i = headerRowIndex + 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        if (row.isEmpty) continue;

        try {
          // Extract the system name from Excel row
          final excelSystemName = _getCellValue(row, columnMap['name']);
          if (excelSystemName == null || excelSystemName.isEmpty) continue;
          
          // Build data map with all columns from Excel
          final rowData = <String, dynamic>{};
          
          for (final entry in columnMap.entries) {
            final dbColumn = entry.key;
            final excelColumnIndex = entry.value;
            
            final value = _getCellValue(row, excelColumnIndex);
            if (value != null && value.isNotEmpty) {
              rowData[dbColumn] = value;
            }
          }
          
          if (rowData.isEmpty) continue;
          
          // Get make, year and model for compound key
          final excelMake = (rowData['vehicle_make'] as String?)?.toLowerCase().trim() ?? '';
          final excelYear = (rowData['vehicle_year'] as String?)?.toLowerCase().trim() ?? '';
          final excelModel = (rowData['vehicle_model'] as String?)?.toLowerCase().trim() ?? '';
          final compoundKey = '${excelSystemName.toLowerCase()}|$excelMake|$excelYear|$excelModel';
          
          // Find matching record in database by compound key (name + make + year + model)
          final matchingRecord = existingByKey[compoundKey];
          
          if (matchingRecord != null) {
            // UPDATE existing record
            await txn.update(
              'calibration_systems',
              rowData,
              where: 'id = ?',
              whereArgs: [matchingRecord['id']],
            );
            updatedCount++;
          } else {
            // INSERT new record - generate unique ID from name + make + year + model
            final idBase = excelSystemName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
            final makePart = excelMake.isNotEmpty ? '_${excelMake.replaceAll(RegExp(r'[^a-z0-9]'), '_')}' : '';
            final yearPart = excelYear.isNotEmpty ? '_$excelYear' : '';
            final modelPart = excelModel.isNotEmpty ? '_${excelModel.replaceAll(RegExp(r'[^a-z0-9]'), '_')}' : '';
            final id = '$idBase$makePart$yearPart$modelPart';
            rowData['id'] = id;
            
            // Set defaults for required fields if not present
            rowData['name'] ??= excelSystemName;
            rowData['description'] ??= '';
            rowData['category'] ??= '';
            rowData['estimated_time'] ??= '';
            rowData['estimated_cost'] ??= '';
            rowData['equipment_needed'] ??= '';
            rowData['required_for'] ??= '';
            rowData['pre_qualifications'] ??= '';
            rowData['hyperlink'] ??= '';
            rowData['adas_keywords'] ??= '';
            rowData['priority'] ??= 0;
            rowData['vehicle_year'] ??= '';
            rowData['vehicle_model'] ??= '';
            rowData['vehicle_make'] ??= '';
            
            await txn.insert(
              'calibration_systems',
              rowData,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            insertedCount++;
            
            // Add to lookup map so subsequent rows with same key update instead of insert
            existingByKey[compoundKey] = {'id': id, ...rowData};
          }
        } catch (e) {
          // Silently skip invalid rows
        }
        
        // Yield control every 100 rows
        if (i % 100 == 0) {
          await Future.delayed(const Duration(milliseconds: 1));
        }
      }
    });

    print('   ✓ Updated $updatedCount existing records');
    print('   ✓ Inserted $insertedCount new records');
    
    // Debug: Check if pre_qualifications was mapped
    if (columnMap.containsKey('pre_qualifications')) {
      print('   ✅ Pre-qualifications column WAS mapped (column index: ${columnMap['pre_qualifications']})');
    } else {
      print('   ⚠️ Pre-qualifications column was NOT mapped - check column headers');
    }
    
    return updatedCount + insertedCount;
  }
  
  /// Map Excel column headers directly to database column names (for updating only)
  Map<String, int> _mapColumnsToDatabase(List<String> headers) {
    final map = <String, int>{};
    
    print('   📋 Mapping Excel columns to database columns:');
    print('   📋 Excel headers found (${headers.length} columns):');
    for (int i = 0; i < headers.length; i++) {
      final h = headers[i];
      final lower = h.toLowerCase();
      // Highlight potential pre-qual/pre-req columns
      if (lower.contains('pre-qual') || lower.contains('prequal') || 
          lower.contains('pre-req') || lower.contains('prereq') ||
          lower.contains('prerequisite')) {
        print('      Column $i: "${headers[i]}" ⭐ PRE-QUAL/PRE-REQ DETECTED');
      } else {
        print('      Column $i: "${headers[i]}"');
      }
    }
    
    // Define the database columns we want to update
    // Order matters - more specific matches should come first
    // For vehicle_year and vehicle_model, we need to be careful not to match "model" in "model year"
    final dbColumns = {
      'name': ['protech generic system name', 'oem adas system name', 'system name', 'system', 'name'],
      'description': ['description', 'desc', 'notes', 'details', 'info'],
      'category': ['calibration type', 'cal type', 'category', 'type', 'parent component', 'component'],
      'estimated_time': ['time', 'duration', 'estimated time', 'labor time', 'hours'],
      'estimated_cost': ['cost', 'price', 'estimated cost', 'labor cost', 'fee'],
      'pre_qualifications': [
        'calibration prerequisites short hand',
        'calibration prerequisites shorthand',  
        'calibration prerequisites',
        'prerequisites short hand',
        'prerequisites shorthand',
        'prerequisites',
        'pre-qualifications',
        'prequalifications', 
        'pre-qualification',
        'prequalification',
        'pre-qual',
        'prequal',
        'pre qual',
        'pre-reqs',
        'prereqs',
        'pre-req',
        'prereq',
        'pre req',
        'requirements',
      ],
      'hyperlink': [
        'service information hyperlink',
        'oe glass service info hyperlink',
        'service info hyperlink',
        'hyperlink',
        'link',
        'url',
        'web link',
        'reference',
      ],
      'adas_keywords': ['keyword', 'keywords', 'search', 'tags'],
      'required_for': ['required', 'trigger', 'required for', 'applies to', 'conditions'],
      'equipment_needed': ['equipment', 'tool', 'tools', 'equipment needed', 'required equipment'],
      // Year column - check for exact matches first, then partial
      'vehicle_year': ['model year', 'vehicle year', 'year'],
      // Model column - be more specific to avoid matching "model year"
      'vehicle_model': ['vehicle model', 'model name'],
      // Make column - for vehicle manufacturer
      'vehicle_make': ['make', 'oem', 'manufacturer', 'vehicle make'],
    };
    
    // First pass: exact matches (header equals keyword exactly)
    for (int i = 0; i < headers.length; i++) {
      final header = headers[i].toLowerCase().trim();
      if (header.isEmpty) continue;
      
      for (final dbEntry in dbColumns.entries) {
        final dbColumn = dbEntry.key;
        final keywords = dbEntry.value;
        
        for (final keyword in keywords) {
          if (header == keyword) {
            if (!map.containsKey(dbColumn)) {
              map[dbColumn] = i;
              print('      "${headers[i]}" → $dbColumn (exact match)');
            }
            break;
          }
        }
      }
    }
    
    // Second pass: partial/contains matches for columns not yet mapped
    for (int i = 0; i < headers.length; i++) {
      final header = headers[i].toLowerCase().trim();
      if (header.isEmpty) continue;
      
      for (final dbEntry in dbColumns.entries) {
        final dbColumn = dbEntry.key;
        final keywords = dbEntry.value;
        
        // Skip if already mapped
        if (map.containsKey(dbColumn)) continue;
        
        for (final keyword in keywords) {
          if (header.contains(keyword)) {
            // Special case: Don't match "model" for vehicle_model if the header contains "year"
            if (dbColumn == 'vehicle_model' && keyword == 'model' && header.contains('year')) {
              continue;
            }
            
            map[dbColumn] = i;
            print('      "${headers[i]}" → $dbColumn (partial match on "$keyword")');
            break;
          }
        }
      }
    }
    
    // Third pass: Find "Model" column that is NOT "Model Year"
    // This handles the common case where there's both "Model Year" and "Model" columns
    if (!map.containsKey('vehicle_model')) {
      for (int i = 0; i < headers.length; i++) {
        final header = headers[i].toLowerCase().trim();
        if (header.isEmpty) continue;
        
        // Match "model" but NOT if it contains "year"
        if (header.contains('model') && !header.contains('year')) {
          map['vehicle_model'] = i;
          print('      "${headers[i]}" → vehicle_model (model without year)');
          break;
        }
      }
    }
    
    if (map.isEmpty) {
      print('      ⚠️  No matching columns found');
    } else {
      print('   📋 Total columns mapped: ${map.length}');
      
      // Show which database columns were NOT mapped
      final unmappedDbColumns = dbColumns.keys.where((col) => !map.containsKey(col)).toList();
      if (unmappedDbColumns.isNotEmpty) {
        print('   ⚠️  Database columns NOT found in Excel: $unmappedDbColumns');
      }
      
      // Show which Excel columns were NOT mapped
      final mappedIndices = map.values.toSet();
      final unmappedExcelColumns = <String>[];
      for (int i = 0; i < headers.length; i++) {
        if (!mappedIndices.contains(i) && headers[i].isNotEmpty) {
          unmappedExcelColumns.add('"${headers[i]}" (column $i)');
        }
      }
      if (unmappedExcelColumns.isNotEmpty) {
        print('   ⚠️  Excel columns NOT mapped to database: ${unmappedExcelColumns.join(', ')}');
      }
    }
    
    return map;
  }

  /// Map Excel column headers to fixed database fields
  Map<String, int> _mapColumns(List<String> headers) {
    final map = <String, int>{};

    print('   📋 Mapping Excel columns to database fields:');

    for (int i = 0; i < headers.length; i++) {
      final header = headers[i].toLowerCase().trim();
      if (header.isEmpty) continue;

      // Map Excel columns to FIXED database fields
      if (header.contains('system') || header.contains('name')) {
        if (!map.containsKey('name')) {
          map['name'] = i;
          print('      "${headers[i]}" → name (system name)');
        }
      }
      if (header.contains('description') || header.contains('desc')) {
        map['description'] = i;
        print('      "${headers[i]}" → description');
      }
      if (header.contains('category') || header.contains('type')) {
        map['category'] = i;
        print('      "${headers[i]}" → category');
      }
      if (header.contains('time') || header.contains('duration')) {
        map['estimatedTime'] = i;
        print('      "${headers[i]}" → estimated_time');
      }
      if (header.contains('cost') || header.contains('price')) {
        map['estimatedCost'] = i;
        print('      "${headers[i]}" → estimated_cost');
      }
      if (header.contains('pre-qual') || header.contains('prequalification') || header.contains('requirement')) {
        map['preQualifications'] = i;
        print('      "${headers[i]}" → pre_qualifications');
      }
      if (header.contains('hyperlink') || header.contains('link') || header.contains('url')) {
        map['hyperlink'] = i;
        print('      "${headers[i]}" → hyperlink');
      }
      if (header.contains('keyword') || header.contains('search')) {
        map['keywords'] = i;
        print('      "${headers[i]}" → adas_keywords');
      }
      if (header.contains('required') || header.contains('trigger')) {
        map['requiredFor'] = i;
        print('      "${headers[i]}" → required_for');
      }
      if (header.contains('equipment') || header.contains('tool')) {
        map['equipmentNeeded'] = i;
        print('      "${headers[i]}" → equipment_needed');
      }
      if (header.contains('priority')) {
        map['priority'] = i;
        print('      "${headers[i]}" → priority');
      }
      if (header.contains('component') || header.contains('parent')) {
        map['component'] = i;
        print('      "${headers[i]}" → category (alt)');
      }
      // Prioritize "make" column for vehicle make, don't overwrite if already set
      if (header.contains('make') && !header.contains('remarks')) {
        if (!map.containsKey('oem')) {
          map['oem'] = i;
          print('      "${headers[i]}" → adas_keywords (vehicle make - HIGH PRIORITY)');
        }
      } else if ((header.contains('oem') || header.contains('manufacturer')) && !map.containsKey('oem')) {
        map['oem'] = i;
        print('      "${headers[i]}" → adas_keywords (as OEM)');
      }
      if (header.contains('calibration type') || header.contains('cal type')) {
        map['calibrationType'] = i;
        print('      "${headers[i]}" → description (alt)');
      }
    }

    if (map.isEmpty) {
      print('      ⚠️  No column mappings found - check Excel headers');
    }

    return map;
  }

  /// Parse a row into a CalibrationSystem
  CalibrationSystem? _parseRowToCalibrationSystem(
    List<Data?> row,
    Map<String, int> columnMap,
  ) {
    // Get system name (required)
    final name = _getCellValue(row, columnMap['name']);
    if (name == null || name.isEmpty) return null;

    // Generate ID from name
    final id = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');

    // Get other fields with defaults
    final description = _getCellValue(row, columnMap['description']) ??
        _getCellValue(row, columnMap['calibrationType']) ??
        'ADAS calibration system';

    final category = _getCellValue(row, columnMap['category']) ??
        _getCellValue(row, columnMap['component']) ??
        'ADAS Systems';

    final estimatedTime = _getCellValue(row, columnMap['estimatedTime']) ?? '1-2 hours';
    final estimatedCost = _getCellValue(row, columnMap['estimatedCost']) ?? '\$150-\$300';

    // Parse list fields
    final requiredFor = _parseListField(
      _getCellValue(row, columnMap['requiredFor']),
      defaultValues: ['ADAS work', 'camera work', 'sensor work'],
    );

    final equipmentNeeded = _parseListField(
      _getCellValue(row, columnMap['equipmentNeeded']),
      defaultValues: ['ADAS calibration equipment', 'diagnostic scanner'],
    );

    final preQualifications = _parseListField(
      _getCellValue(row, columnMap['preQualifications']),
      defaultValues: [],
    );

    // Build keywords from multiple sources
    final keywords = <String>[];
    
    // Add explicit keywords
    keywords.addAll(_parseListField(_getCellValue(row, columnMap['keywords'])));
    
    // Add OEM names as keywords (THIS IS WHERE VEHICLE MAKE SHOULD BE)
    final oemValue = _getCellValue(row, columnMap['oem']);
    if (oemValue != null && oemValue.isNotEmpty) {
      // Debug: Print first few OEM values to see what we're getting
      keywords.addAll(_parseListField(oemValue));
    }
    
    // Add variations of the system name
    keywords.add(name.toLowerCase());
    keywords.addAll(name.toLowerCase().split(RegExp(r'\s+')));
    
    // Remove duplicates and ENSURE vehicle make is first
    final uniqueKeywords = keywords.toSet().toList();
    
    // Move vehicle make to the front if it exists
    if (oemValue != null && oemValue.isNotEmpty) {
      uniqueKeywords.remove(oemValue.toLowerCase());
      uniqueKeywords.insert(0, oemValue);
    }

    final hyperlink = _getCellValue(row, columnMap['hyperlink']);

    final priority = _parsePriority(_getCellValue(row, columnMap['priority']));

    return CalibrationSystem(
      id: id,
      name: name,
      description: description,
      category: category,
      requiredFor: requiredFor,
      estimatedTime: estimatedTime,
      estimatedCost: estimatedCost,
      equipmentNeeded: equipmentNeeded,
      iconName: _determineIcon(category),
      priority: priority,
      preQualifications: preQualifications,
      hyperlink: hyperlink,
      adasKeywords: uniqueKeywords,
    );
  }

  /// Get cell value as string
  String? _getCellValue(List<Data?> row, int? columnIndex) {
    if (columnIndex == null || columnIndex >= row.length) return null;
    final cell = row[columnIndex];
    if (cell == null || cell.value == null) return null;
    return cell.value.toString().trim();
  }

  /// Parse a delimited string into a list
  List<String> _parseListField(String? value, {List<String>? defaultValues}) {
    if (value == null || value.isEmpty) {
      return defaultValues ?? [];
    }

    // Try different delimiters
    List<String> items;
    if (value.contains(';')) {
      items = value.split(';');
    } else if (value.contains(',')) {
      items = value.split(',');
    } else if (value.contains('|')) {
      items = value.split('|');
    } else if (value.contains('\n')) {
      items = value.split('\n');
    } else {
      items = [value];
    }

    return items
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  /// Parse priority value
  int _parsePriority(String? value) {
    if (value == null || value.isEmpty) return 2;

    // Try to parse as number
    final intValue = int.tryParse(value);
    if (intValue != null) return intValue.clamp(1, 3);

    // Parse from text
    final lower = value.toLowerCase();
    if (lower.contains('high') || lower.contains('critical')) return 1;
    if (lower.contains('low')) return 3;
    return 2;
  }

  /// Determine icon based on category
  String _determineIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('camera')) return 'camera';
    if (lower.contains('radar')) return 'radar';
    if (lower.contains('sensor') || lower.contains('parking')) return 'sensors';
    if (lower.contains('light') || lower.contains('headlight')) return 'lightbulb';
    if (lower.contains('steering') || lower.contains('chassis')) return 'steering';
    return 'settings';
  }

  /// Insert or update a calibration system
  Future<void> _insertOrUpdateSystem(CalibrationSystem system) async {
    // Check if system exists
    final existing = await database.query(
      'calibration_systems',
      where: 'id = ?',
      whereArgs: [system.id],
    );

    if (existing.isEmpty) {
      // Insert new system
      await database.insert('calibration_systems', system.toMap());
    } else {
      // Update existing system
      await database.update(
        'calibration_systems',
        system.toMap(),
        where: 'id = ?',
        whereArgs: [system.id],
      );
    }
  }

  /// Import from a single file with progress updates
  Stream<ImportProgress> importFromFileWithProgress(String filePath) async* {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist');
      }

      final fileName = path.basename(file.path);
      final fileSize = await file.length();

      // Yield initial progress
      yield ImportProgress(
        totalFiles: 1,
        processedFiles: 0,
        totalBytes: fileSize,
        processedBytes: 0,
        currentFileName: fileName,
        recordsImported: 0,
      );

      // Import the file
      final imported = await _importExcelFile(file);

      // Yield final progress
      yield ImportProgress(
        totalFiles: 1,
        processedFiles: 1,
        totalBytes: fileSize,
        processedBytes: fileSize,
        currentFileName: fileName,
        recordsImported: imported,
      );
    } catch (e) {
      throw Exception('Import error: ${e.toString()}');
    }
  }

  /// Import from a single file (legacy method for compatibility)
  Future<Map<String, dynamic>> importFromFile(String filePath) async {
    try {
      int totalImported = 0;

      await for (final progress in importFromFileWithProgress(filePath)) {
        totalImported = progress.recordsImported;
      }

      return {
        'success': true,
        'message': 'Successfully imported $totalImported records',
        'totalRecords': totalImported,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  /// Format bytes to human-readable string
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

