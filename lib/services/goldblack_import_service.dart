import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart' as xml;
import 'database_service.dart';

class GoldBlackImportService {
  final DatabaseService _dbService;

  GoldBlackImportService(this._dbService);

  Future<Map<String, dynamic>> importGoldList(String filePath) async {
    return await _importFile(filePath, 'gold');
  }

  Future<Map<String, dynamic>> importBlackList(String filePath) async {
    return await _importFile(filePath, 'black');
  }

  Future<Map<String, dynamic>> _importFile(String filePath, String listType) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return {'success': false, 'error': 'File not found: $filePath', 'count': 0};
      }

      if (filePath.toLowerCase().endsWith('.csv')) {
        return await _importCSVFile(filePath, listType);
      } else {
        return await _importXlsxFile(filePath, listType);
      }
    } catch (e) {
      return {'success': false, 'error': e.toString(), 'count': 0};
    }
  }

  /// Import XLSX file by directly parsing the XML inside (bypasses Excel library issues)
  Future<Map<String, dynamic>> _importXlsxFile(String filePath, String listType) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      // Find shared strings (cell text values are often stored here)
      final sharedStrings = <String>[];
      final sharedStringsFile = archive.findFile('xl/sharedStrings.xml');
      if (sharedStringsFile != null) {
        final content = utf8.decode(sharedStringsFile.content as List<int>);
        final doc = xml.XmlDocument.parse(content);
        for (final si in doc.findAllElements('si')) {
          final tElements = si.findAllElements('t');
          if (tElements.isNotEmpty) {
            sharedStrings.add(tElements.map((t) => t.innerText).join());
          } else {
            sharedStrings.add('');
          }
        }
      }

      // Find all sheet files
      final sheetFiles = archive.files
          .where((f) => f.name.startsWith('xl/worksheets/sheet') && f.name.endsWith('.xml'))
          .toList();
      
      if (sheetFiles.isEmpty) {
        return {'success': false, 'error': 'No worksheets found in Excel file', 'count': 0};
      }

      List<String>? headers;
      final allRows = <List<String>>[];

      // Process each sheet
      for (final sheetFile in sheetFiles) {
        final content = utf8.decode(sheetFile.content as List<int>);
        final doc = xml.XmlDocument.parse(content);
        
        final rows = doc.findAllElements('row').toList();
        
        for (final row in rows) {
          final cells = row.findAllElements('c').toList();
          final rowData = <String>[];
          
          int expectedCol = 0;
          for (final cell in cells) {
            // Get cell reference to determine column position
            final ref = cell.getAttribute('r') ?? '';
            final colLetter = ref.replaceAll(RegExp(r'[0-9]'), '');
            final actualCol = _columnLetterToIndex(colLetter);
            
            // Fill empty cells if there are gaps
            while (expectedCol < actualCol) {
              rowData.add('');
              expectedCol++;
            }
            
            // Get cell value
            String value = '';
            final vElement = cell.findElements('v').firstOrNull;
            final tAttr = cell.getAttribute('t');
            
            if (vElement != null) {
              if (tAttr == 's') {
                // Shared string reference
                final index = int.tryParse(vElement.innerText) ?? 0;
                if (index < sharedStrings.length) {
                  value = sharedStrings[index];
                }
              } else {
                value = vElement.innerText;
              }
            } else {
              // Check for inline string
              final isElement = cell.findElements('is').firstOrNull;
              if (isElement != null) {
                value = isElement.findAllElements('t').map((t) => t.innerText).join();
              }
            }
            
            rowData.add(value.trim());
            expectedCol++;
          }
          
          // Skip empty rows
          if (rowData.every((cell) => cell.isEmpty)) continue;
          
          // First non-empty row of first sheet becomes headers
          if (headers == null) {
            headers = rowData;
          } else {
            allRows.add(rowData);
          }
        }
      }

      if (headers == null || allRows.isEmpty) {
        return {'success': false, 'error': 'No data found in Excel file', 'count': 0};
      }

      // Import the data
      return await _importRows(headers, allRows, listType, sheetFiles.length);
      
    } catch (e) {
      return {'success': false, 'error': 'Failed to read Excel file: $e', 'count': 0};
    }
  }

  /// Import CSV file
  Future<Map<String, dynamic>> _importCSVFile(String filePath, String listType) async {
    try {
      final contents = await File(filePath).readAsString();
      final lines = contents.split('\n').where((line) => line.trim().isNotEmpty).toList();
      
      if (lines.isEmpty) {
        return {'success': false, 'error': 'Empty file', 'count': 0};
      }

      final headers = _parseCSVLine(lines[0]);
      final allRows = <List<String>>[];
      
      for (var i = 1; i < lines.length; i++) {
        final row = _parseCSVLine(lines[i]);
        if (row.isNotEmpty && !row.every((cell) => cell.isEmpty)) {
          allRows.add(row);
        }
      }

      return await _importRows(headers, allRows, listType, 1);
      
    } catch (e) {
      return {'success': false, 'error': 'Failed to read CSV file: $e', 'count': 0};
    }
  }

  /// Common import logic for both XLSX and CSV
  Future<Map<String, dynamic>> _importRows(
    List<String> headers, 
    List<List<String>> rows, 
    String listType,
    int sheetCount,
  ) async {
    final lowerHeaders = headers.map((h) => h.toLowerCase().trim()).toList();
    final columnMap = _mapColumns(lowerHeaders);

    // If no DTC code column found, use first column as DTC code
    if (columnMap['dtc_code'] == null) {
      columnMap['dtc_code'] = 0;
    }

    // Clear existing data for this list type to prevent duplicates
    await _dbService.clearGoldBlackDTCs(listType: listType);

    int totalImported = 0;
    final seenCodes = <String>{};  // Track seen codes to prevent duplicates within import
    final dtcBatch = <Map<String, dynamic>>[];
    
    for (final row in rows) {
      final dtcCode = _getRowValue(row, columnMap['dtc_code']);
      if (dtcCode == null || dtcCode.isEmpty) continue;
      
      // Skip duplicates within this import
      final uniqueKey = '$dtcCode|${_getRowValue(row, columnMap['description']) ?? ''}';
      if (seenCodes.contains(uniqueKey)) continue;
      seenCodes.add(uniqueKey);

      final dtcRecord = {
        'dtc_code': dtcCode,
        'description': _getRowValue(row, columnMap['description']) ?? '',
        'module': _getRowValue(row, columnMap['module']) ?? '',
        'system': _getRowValue(row, columnMap['system']) ?? '',
        'category': _getRowValue(row, columnMap['category']) ?? '',
        'list_type': listType,
        'make': _getRowValue(row, columnMap['make']) ?? '',
        'model': _getRowValue(row, columnMap['model']) ?? '',
        'year': _getRowValue(row, columnMap['year']) ?? '',
        'notes': _getRowValue(row, columnMap['notes']) ?? '',
        'additional_data': _buildAdditionalData(row, lowerHeaders, columnMap),
      };

      dtcBatch.add(dtcRecord);

      if (dtcBatch.length >= 500) {
        await _dbService.insertGoldBlackDTCBatch(dtcBatch);
        totalImported += dtcBatch.length;
        dtcBatch.clear();
      }
    }

    if (dtcBatch.isNotEmpty) {
      await _dbService.insertGoldBlackDTCBatch(dtcBatch);
      totalImported += dtcBatch.length;
    }

    // Build column mapping info for debugging
    final mappingInfo = <String>[];
    columnMap.forEach((key, value) {
      if (value != null && value < headers.length) {
        mappingInfo.add('$key → "${headers[value]}" (col $value)');
      }
    });
    
    // List unmapped columns
    final unmappedCols = <String>[];
    for (var i = 0; i < headers.length; i++) {
      if (!columnMap.values.contains(i) && headers[i].isNotEmpty) {
        unmappedCols.add('"${headers[i]}" (col $i)');
      }
    }

    return {
      'success': true,
      'count': totalImported,
      'sheets': sheetCount,
      'list_type': listType,
      'headers': headers.join(' | '),
      'column_mapping': mappingInfo.join('\n'),
      'unmapped': unmappedCols.join('\n'),
    };
  }

  int _columnLetterToIndex(String letter) {
    if (letter.isEmpty) return 0;
    int index = 0;
    for (int i = 0; i < letter.length; i++) {
      index = index * 26 + (letter.codeUnitAt(i) - 'A'.codeUnitAt(0) + 1);
    }
    return index - 1;
  }

  String? _getRowValue(List<String> row, int? columnIndex) {
    if (columnIndex == null || columnIndex >= row.length) return null;
    final value = row[columnIndex].trim();
    return value.isEmpty ? null : value;
  }

  String _buildAdditionalData(List<String> row, List<String> headers, Map<String, int?> mappedColumns) {
    final additionalData = <String, String>{};
    final mappedIndices = mappedColumns.values.whereType<int>().toSet();

    for (var i = 0; i < headers.length && i < row.length; i++) {
      if (mappedIndices.contains(i)) continue;
      
      final header = headers[i];
      if (header.isEmpty) continue;
      
      final value = _getRowValue(row, i);
      if (value != null && value.isNotEmpty) {
        additionalData[header] = value;
      }
    }

    if (additionalData.isEmpty) return '';
    return additionalData.entries.map((e) => '${e.key}: ${e.value}').join(' | ');
  }

  List<String> _parseCSVLine(String line) {
    final result = <String>[];
    var current = StringBuffer();
    var inQuotes = false;
    
    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(current.toString().trim());
        current = StringBuffer();
      } else {
        current.write(char);
      }
    }
    result.add(current.toString().trim());
    
    return result;
  }

  Map<String, int?> _mapColumns(List<String> headers) {
    final map = <String, int?>{};
    final usedIndices = <int>{};

    // FIRST: Find the Description column - this is the priority
    // Look for any column that contains "description" in the header
    map['description'] = _findColumnContaining(headers, 'description');
    // Also check for other common description-like column names
    if (map['description'] == null) {
      for (final keyword in ['fault', 'meaning', 'definition', 'detail', 'carmake', 'message', 'symptom']) {
        map['description'] = _findColumnContaining(headers, keyword);
        if (map['description'] != null) break;
      }
    }
    if (map['description'] != null) usedIndices.add(map['description']!);

    // DTC Code column - look for specific DTC-related headers
    // Avoid columns already used and avoid matching description columns
    map['dtc_code'] = _findColumnIndexExcluding(headers, [
      'dtc', 'dtc code', 'code', 'fault code', 'trouble code', 'obd',
    ], usedIndices, excludeKeywords: ['description']);
    if (map['dtc_code'] != null) usedIndices.add(map['dtc_code']!);

    // Module column
    map['module'] = _findColumnIndexExcluding(headers, [
      'module', 'ecu', 'control module', 'controller',
    ], usedIndices, excludeKeywords: ['description']);
    if (map['module'] != null) usedIndices.add(map['module']!);

    // System column
    map['system'] = _findColumnIndexExcluding(headers, [
      'system', 'system name', 'adas',
    ], usedIndices, excludeKeywords: ['description', 'module']);
    if (map['system'] != null) usedIndices.add(map['system']!);

    // Category column
    map['category'] = _findColumnIndexExcluding(headers, [
      'category', 'type', 'class', 'group',
    ], usedIndices, excludeKeywords: ['description']);
    if (map['category'] != null) usedIndices.add(map['category']!);

    // Make column - be very specific, only exact matches
    map['make'] = _findExactColumn(headers, ['make', 'oem', 'manufacturer'], usedIndices);
    if (map['make'] != null) usedIndices.add(map['make']!);

    // Model column
    map['model'] = _findExactColumn(headers, ['model'], usedIndices);
    if (map['model'] != null) usedIndices.add(map['model']!);

    // Year column
    map['year'] = _findExactColumn(headers, ['year', 'yr'], usedIndices);
    if (map['year'] != null) usedIndices.add(map['year']!);

    // Notes column
    map['notes'] = _findColumnIndexExcluding(headers, [
      'notes', 'note', 'comment', 'remarks',
    ], usedIndices, excludeKeywords: ['description']);
    if (map['notes'] != null) usedIndices.add(map['notes']!);

    return map;
  }

  /// Find exact column match (header equals one of the names)
  int? _findExactColumn(List<String> headers, List<String> names, Set<int> excludeIndices) {
    for (var i = 0; i < headers.length; i++) {
      if (excludeIndices.contains(i)) continue;
      final header = headers[i].toLowerCase().trim();
      for (final name in names) {
        if (header == name) {
          return i;
        }
      }
    }
    return null;
  }

  /// Find column index while excluding already-used indices and certain keywords
  int? _findColumnIndexExcluding(
    List<String> headers, 
    List<String> possibleNames, 
    Set<int> excludeIndices,
    {List<String> excludeKeywords = const []}
  ) {
    for (var i = 0; i < headers.length; i++) {
      if (excludeIndices.contains(i)) continue;
      final header = headers[i].toLowerCase().trim();
      
      // Skip if header contains any excluded keywords
      bool hasExcluded = false;
      for (final kw in excludeKeywords) {
        if (header.contains(kw)) {
          hasExcluded = true;
          break;
        }
      }
      if (hasExcluded) continue;
      
      for (final name in possibleNames) {
        if (header == name || header.contains(name)) {
          return i;
        }
      }
    }
    return null;
  }

  /// Find column that contains a specific keyword anywhere in the header
  int? _findColumnContaining(List<String> headers, String keyword) {
    final lowerKeyword = keyword.toLowerCase();
    for (var i = 0; i < headers.length; i++) {
      final header = headers[i].toLowerCase().trim();
      if (header.contains(lowerKeyword)) {
        return i;
      }
    }
    return null;
  }
}
