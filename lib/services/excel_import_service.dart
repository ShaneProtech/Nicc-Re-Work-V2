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

  /// Import ADAS systems from an Excel sheet by UPDATING existing records
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

    print('   Found ${columnMap.length} matching database columns');
    
    // Get all existing systems from database
    final existingSystems = await database.query('calibration_systems');
    print('   Database has ${existingSystems.length} existing records to match against');
    
    int updatedCount = 0;
    
    print('   Matching Excel rows to database records...');
    
    // Process each row and update matching records
    await database.transaction((txn) async {
      for (int i = headerRowIndex + 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        if (row.isEmpty) continue;

        try {
          // Extract the system name from Excel row
          final excelSystemName = _getCellValue(row, columnMap['name']);
          if (excelSystemName == null || excelSystemName.isEmpty) continue;
          
          // Find matching record in database by name (case-insensitive)
          final matchingRecord = existingSystems.where(
            (record) => (record['name'] as String).toLowerCase() == excelSystemName.toLowerCase(),
          ).firstOrNull;
          
          if (matchingRecord == null) continue; // No match found
          
          // Build update map with only the columns that exist in Excel
          final updateData = <String, dynamic>{};
          
          for (final entry in columnMap.entries) {
            final dbColumn = entry.key;
            final excelColumnIndex = entry.value;
            
            final value = _getCellValue(row, excelColumnIndex);
            if (value != null && value.isNotEmpty) {
              updateData[dbColumn] = value;
            }
          }
          
          if (updateData.isNotEmpty) {
            // Update the existing record
            await txn.update(
              'calibration_systems',
              updateData,
              where: 'id = ?',
              whereArgs: [matchingRecord['id']],
            );
            updatedCount++;
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
    return updatedCount;
  }
  
  /// Map Excel column headers directly to database column names (for updating only)
  Map<String, int> _mapColumnsToDatabase(List<String> headers) {
    final map = <String, int>{};
    
    print('   📋 Mapping Excel columns to database columns:');
    
    // Define the database columns we want to update
    final dbColumns = {
      'name': ['name', 'system', 'system name', 'protech generic system name'],
      'description': ['description', 'desc'],
      'category': ['category', 'type', 'parent component', 'component'],
      'estimated_time': ['time', 'duration', 'estimated time'],
      'estimated_cost': ['cost', 'price', 'estimated cost'],
      'pre_qualifications': ['pre-qual', 'prequalification', 'prerequisite', 'calibration prerequisites', 'calibration prerequisites short hand'],
      'hyperlink': ['hyperlink', 'link', 'url', 'service information hyperlink', 'oe glass service info hyperlink'],
      'adas_keywords': ['keyword', 'search', 'make', 'oem', 'manufacturer'],
      'required_for': ['required', 'trigger', 'required for'],
      'equipment_needed': ['equipment', 'tool', 'equipment needed'],
    };
    
    for (int i = 0; i < headers.length; i++) {
      final header = headers[i].toLowerCase().trim();
      if (header.isEmpty) continue;
      
      // Check which database column this Excel column matches
      for (final dbEntry in dbColumns.entries) {
        final dbColumn = dbEntry.key;
        final keywords = dbEntry.value;
        
        // Check if Excel header matches any of the keywords
        for (final keyword in keywords) {
          if (header.contains(keyword)) {
            if (!map.containsKey(dbColumn)) {
              map[dbColumn] = i;
              print('      "${headers[i]}" → $dbColumn');
            }
            break;
          }
        }
      }
    }
    
    if (map.isEmpty) {
      print('      ⚠️  No matching columns found');
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

