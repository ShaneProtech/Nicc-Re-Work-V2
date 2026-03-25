import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';

class JsonImportScreen extends StatefulWidget {
  const JsonImportScreen({Key? key}) : super(key: key);

  @override
  State<JsonImportScreen> createState() => _JsonImportScreenState();
}

class _VehicleAnalysis {
  final String fileName;
  final Map<String, dynamic>? data;
  final String? error;
  bool isAnalyzing;

  _VehicleAnalysis({
    required this.fileName,
    this.data,
    this.error,
    this.isAnalyzing = false,
  });
}

class _JsonImportScreenState extends State<JsonImportScreen> with TickerProviderStateMixin {
  List<_VehicleAnalysis> _vehicles = [];
  bool _isDragging = false;

  Future<void> _pickJsonFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'txt'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        await _processFiles(result.files.map((f) => File(f.path!)).toList());
      }
    } catch (e) {
      _showError('Error picking files: $e');
    }
  }

  Future<void> _processFiles(List<File> files) async {
    // Add all files to the list with analyzing state
    final newVehicles = files.map((f) => _VehicleAnalysis(
      fileName: f.path.split(Platform.pathSeparator).last,
      isAnalyzing: true,
    )).toList();

    setState(() {
      _vehicles.addAll(newVehicles);
    });

    // Process each file individually with delay for visual feedback
    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final vehicleIndex = _vehicles.length - files.length + i;
      
      try {
        // Simulate analysis time for visual feedback (minimum 500ms)
        final analysisResult = await Future.wait([
          _analyzeFile(file),
          Future.delayed(const Duration(milliseconds: 800)),
        ]);
        
        final data = analysisResult[0] as Map<String, dynamic>;
        
        setState(() {
          _vehicles[vehicleIndex] = _VehicleAnalysis(
            fileName: _vehicles[vehicleIndex].fileName,
            data: data,
            isAnalyzing: false,
          );
        });
      } catch (e) {
        setState(() {
          _vehicles[vehicleIndex] = _VehicleAnalysis(
            fileName: _vehicles[vehicleIndex].fileName,
            error: e.toString(),
            isAnalyzing: false,
          );
        });
      }
    }
  }

  Future<Map<String, dynamic>> _analyzeFile(File file) async {
    final content = await file.readAsString();
    
    // Try to parse as JSON first
    dynamic jsonData;
    try {
      jsonData = jsonDecode(content);
    } catch (e) {
      // If JSON parsing fails, try to extract data from raw text
      return _extractFromRawText(content);
    }

    // Deep search through the entire JSON structure
    return _deepAnalyzeJson(jsonData, content);
  }

  Map<String, dynamic> _deepAnalyzeJson(dynamic data, String rawContent) {
    final result = <String, dynamic>{
      'year': '',
      'make': '',
      'model': '',
      'vin': '',
      'calibrations': <Map<String, String>>[],
    };

    // Collect all key-value pairs from the entire JSON structure
    final allValues = <String, dynamic>{};
    _flattenJson(data, allValues, '');

    // Search for vehicle information with multiple possible keys
    result['year'] = _findValue(allValues, [
      'year', 'modelyear', 'model_year', 'vehicleyear', 'vehicle_year',
      'yr', 'model year', 'vehicle year'
    ]);
    
    result['make'] = _findValue(allValues, [
      'make', 'manufacturer', 'brand', 'oem', 'vehiclemake', 'vehicle_make',
      'car_make', 'carmake', 'vehicle make'
    ]);
    
    result['model'] = _findValue(allValues, [
      'model', 'vehiclemodel', 'vehicle_model', 'carmodel', 'car_model',
      'model_name', 'modelname', 'vehicle model'
    ]);
    
    result['vin'] = _findValue(allValues, [
      'vin', 'vehicleidentificationnumber', 'vehicle_identification_number',
      'vin_number', 'vinnumber', 'serial', 'serialnumber', 'serial_number'
    ]);

    // Analyze the entire file content for ADAS systems and calibration needs
    final calibrations = _analyzeForRequiredCalibrations(allValues, rawContent);
    
    result['calibrations'] = calibrations;
    return result;
  }

  /// Comprehensive analysis to find ADAS systems that need calibration
  List<Map<String, String>> _analyzeForRequiredCalibrations(Map<String, dynamic> allValues, String rawContent) {
    final calibrations = <Map<String, String>>[];
    final addedSystems = <String>{};
    final contentLower = rawContent.toLowerCase();

    // ADAS System definitions with full names and aliases
    final adasSystems = {
      'ACC': ['acc', 'adaptive cruise control', 'adaptive cruise', 'radar cruise', 'dynamic cruise'],
      'AEB': ['aeb', 'automatic emergency braking', 'auto emergency brake', 'collision mitigation', 'cmbs', 'pre-collision', 'forward collision', 'fcw', 'forward collision warning'],
      'LKA': ['lka', 'lane keep assist', 'lane keeping', 'lkas', 'lane assist', 'lane centering'],
      'LDW': ['ldw', 'lane departure warning', 'lane departure'],
      'BSW': ['bsw', 'blind spot warning', 'blind spot monitor', 'bsm', 'blis', 'blind spot detection', 'blind spot'],
      'RCTA': ['rcta', 'rear cross traffic', 'rear cross-traffic', 'cross traffic alert'],
      'APA': ['apa', 'parking assist', 'park assist', 'parking sensor', 'ultrasonic', 'pdc', 'park distance'],
      'BUC': ['buc', 'backup camera', 'rear camera', 'rearview camera', 'reverse camera', 'back up camera'],
      'SVC': ['svc', 'surround view', '360 camera', 'around view', 'bird eye', 'multi-view camera', 'avm'],
      'AHL': ['ahl', 'adaptive headlight', 'adaptive headlamp', 'auto headlight', 'adaptive front light', 'afs'],
      'SAS': ['sas', 'steering angle sensor', 'steering sensor', 'steering angle'],
      'NV': ['nv', 'night vision', 'infrared camera', 'thermal camera'],
      'TSR': ['tsr', 'traffic sign recognition', 'traffic sign', 'sign recognition'],
      'DMS': ['dms', 'driver monitoring', 'driver attention', 'driver alert'],
      'HUD': ['hud', 'head-up display', 'heads up display', 'head up'],
    };

    // Repair triggers that indicate calibration is needed
    final repairTriggers = {
      'ACC': ['front bumper', 'front radar', 'grille', 'front collision', 'front end', 'radiator support', 'front impact'],
      'AEB': ['front bumper', 'front radar', 'front camera', 'windshield', 'front collision', 'grille', 'front end'],
      'LKA': ['windshield', 'front camera', 'windshield camera', 'forward camera', 'alignment', 'suspension'],
      'LDW': ['windshield', 'front camera', 'windshield camera', 'forward camera'],
      'BSW': ['rear bumper', 'quarter panel', 'rear quarter', 'rear corner', 'rear collision', 'side mirror', 'rear impact'],
      'RCTA': ['rear bumper', 'rear corner', 'rear collision', 'rear impact'],
      'APA': ['front bumper', 'rear bumper', 'bumper', 'parking sensor', 'sensor'],
      'BUC': ['tailgate', 'trunk', 'rear bumper', 'liftgate', 'rear camera', 'backup camera'],
      'SVC': ['front bumper', 'rear bumper', 'side mirror', 'camera', 'mirror', 'door'],
      'AHL': ['headlight', 'headlamp', 'front end', 'front collision', 'suspension'],
      'SAS': ['alignment', 'steering', 'suspension', 'wheel', 'tie rod', 'rack'],
      'NV': ['grille', 'front bumper', 'radiator', 'front end'],
      'TSR': ['windshield', 'front camera'],
      'DMS': ['interior', 'mirror', 'dash', 'dashboard'],
      'HUD': ['windshield', 'dashboard', 'dash'],
    };

    // Full system names for display
    final systemFullNames = {
      'ACC': 'Adaptive Cruise Control',
      'AEB': 'Automatic Emergency Braking',
      'LKA': 'Lane Keep Assist',
      'LDW': 'Lane Departure Warning',
      'BSW': 'Blind Spot Warning',
      'RCTA': 'Rear Cross Traffic Alert',
      'APA': 'Parking Assist',
      'BUC': 'Backup Camera',
      'SVC': 'Surround View Camera',
      'AHL': 'Adaptive Headlights',
      'SAS': 'Steering Angle Sensor',
      'NV': 'Night Vision',
      'TSR': 'Traffic Sign Recognition',
      'DMS': 'Driver Monitoring System',
      'HUD': 'Head-Up Display',
    };

    // Step 1: Find all ADAS systems mentioned in the file
    final systemsFound = <String>{};
    final systemContexts = <String, List<String>>{};

    for (final entry in adasSystems.entries) {
      final systemCode = entry.key;
      final aliases = entry.value;
      
      for (final alias in aliases) {
        if (contentLower.contains(alias)) {
          systemsFound.add(systemCode);
          // Find context around the mention
          final contexts = _findContextsForTerm(rawContent, alias);
          systemContexts[systemCode] = [...(systemContexts[systemCode] ?? []), ...contexts];
          break;
        }
      }
    }

    // Step 2: Find all repair/incident information
    final repairsFound = <String>[];
    final repairKeywords = [
      'repair', 'replace', 'r&r', 'r&i', 'remove', 'install', 'collision',
      'damage', 'impact', 'hit', 'accident', 'incident', 'work', 'service'
    ];
    
    for (final keyword in repairKeywords) {
      if (contentLower.contains(keyword)) {
        // Extract surrounding context
        final contexts = _findContextsForTerm(rawContent, keyword);
        repairsFound.addAll(contexts);
      }
    }

    // Step 3: For each system found, check if repairs trigger calibration need
    for (final system in systemsFound) {
      final triggers = repairTriggers[system] ?? [];
      String? reason;
      
      // Check if any trigger is mentioned
      for (final trigger in triggers) {
        if (contentLower.contains(trigger.toLowerCase())) {
          reason = _findBestReason(rawContent, trigger);
          break;
        }
      }
      
      // Also check if system is explicitly marked as needing calibration
      if (reason == null) {
        final systemAliases = adasSystems[system] ?? [];
        for (final alias in systemAliases) {
          if (contentLower.contains('$alias calibration') ||
              contentLower.contains('calibrate $alias') ||
              contentLower.contains('$alias cal') ||
              contentLower.contains('$alias required') ||
              contentLower.contains('$alias needed')) {
            reason = 'System calibration required';
            break;
          }
        }
      }

      if (reason != null && !addedSystems.contains(system)) {
        addedSystems.add(system);
        calibrations.add({
          'name': '${systemFullNames[system]} ($system)',
          'reason': reason,
        });
      }
    }

    // Step 4: Check for explicit calibration entries in the data
    for (final entry in allValues.entries) {
      final key = entry.key.toLowerCase();
      final value = entry.value?.toString() ?? '';
      
      // Look for calibration-related keys
      if (key.contains('calibration') || key.contains('adas') || key.contains('system')) {
        // Check if value contains a system code
        for (final systemEntry in adasSystems.entries) {
          final systemCode = systemEntry.key;
          final aliases = systemEntry.value;
          
          if (addedSystems.contains(systemCode)) continue;
          
          for (final alias in aliases) {
            if (value.toLowerCase().contains(alias)) {
              addedSystems.add(systemCode);
              
              // Try to find reason
              String reason = '';
              final reasonKeys = ['reason', 'because', 'trigger', 'cause', 'why', 'due'];
              for (final rk in reasonKeys) {
                final rv = _findValue(allValues, [rk, '${key}_$rk', '${rk}_${entry.key}']);
                if (rv.isNotEmpty) {
                  reason = rv;
                  break;
                }
              }
              
              calibrations.add({
                'name': '${systemFullNames[systemCode]} ($systemCode)',
                'reason': reason.isEmpty ? 'Calibration required' : reason,
              });
              break;
            }
          }
        }
      }
    }

    // Step 5: Check for numbered calibration fields
    for (int i = 1; i <= 20; i++) {
      final calKeys = ['calibration$i', 'calibration_$i', 'cal$i', 'cal_$i', 'system$i', 'system_$i'];
      
      for (final calKey in calKeys) {
        final calValue = _findValueExact(allValues, calKey);
        if (calValue != null && calValue.isNotEmpty) {
          // Check if it's a known system
          String? matchedSystem;
          for (final systemEntry in adasSystems.entries) {
            for (final alias in systemEntry.value) {
              if (calValue.toLowerCase().contains(alias)) {
                matchedSystem = systemEntry.key;
                break;
              }
            }
            if (matchedSystem != null) break;
          }
          
          if (matchedSystem != null && !addedSystems.contains(matchedSystem)) {
            addedSystems.add(matchedSystem);
            
            // Find reason
            String reason = '';
            for (final reasonKey in ['reason$i', 'reason_$i', 'because$i', 'because_$i', 'trigger$i']) {
              final rv = _findValueExact(allValues, reasonKey);
              if (rv != null && rv.isNotEmpty) {
                reason = rv;
                break;
              }
            }
            
            calibrations.add({
              'name': '${systemFullNames[matchedSystem]} ($matchedSystem)',
              'reason': reason.isEmpty ? 'Calibration required' : reason,
            });
          } else if (matchedSystem == null) {
            // Unknown system, add as-is
            String reason = '';
            for (final reasonKey in ['reason$i', 'reason_$i', 'because$i', 'because_$i']) {
              final rv = _findValueExact(allValues, reasonKey);
              if (rv != null && rv.isNotEmpty) {
                reason = rv;
                break;
              }
            }
            calibrations.add({
              'name': calValue,
              'reason': reason,
            });
          }
          break;
        }
      }
    }

    // Step 6: If no calibrations found yet, do a final deep scan
    if (calibrations.isEmpty) {
      // Look for any "required" or "needed" mentions with systems
      for (final systemEntry in adasSystems.entries) {
        final systemCode = systemEntry.key;
        final aliases = systemEntry.value;
        
        if (addedSystems.contains(systemCode)) continue;
        
        for (final alias in aliases) {
          // Check various patterns
          final patterns = [
            '$alias required',
            '$alias needed',
            '$alias calibration',
            'calibrate $alias',
            '$alias - required',
            '$alias: required',
            'requires $alias',
            '$alias service',
          ];
          
          for (final pattern in patterns) {
            if (contentLower.contains(pattern)) {
              addedSystems.add(systemCode);
              calibrations.add({
                'name': '${systemFullNames[systemCode]} ($systemCode)',
                'reason': 'Calibration required per analysis',
              });
              break;
            }
          }
          if (addedSystems.contains(systemCode)) break;
        }
      }
    }

    return calibrations;
  }

  List<String> _findContextsForTerm(String content, String term) {
    final contexts = <String>[];
    final lowerContent = content.toLowerCase();
    final lowerTerm = term.toLowerCase();
    
    int index = 0;
    while ((index = lowerContent.indexOf(lowerTerm, index)) != -1) {
      final start = (index - 50).clamp(0, content.length);
      final end = (index + term.length + 50).clamp(0, content.length);
      contexts.add(content.substring(start, end).replaceAll('\n', ' ').trim());
      index += term.length;
    }
    
    return contexts;
  }

  String _findBestReason(String content, String trigger) {
    final lowerContent = content.toLowerCase();
    final triggerLower = trigger.toLowerCase();
    
    // Find the context around the trigger
    final index = lowerContent.indexOf(triggerLower);
    if (index == -1) return trigger;
    
    // Extract surrounding text
    final start = (index - 30).clamp(0, content.length);
    final end = (index + trigger.length + 30).clamp(0, content.length);
    final context = content.substring(start, end).replaceAll('\n', ' ').trim();
    
    // Look for repair actions
    final actions = ['replace', 'repair', 'r&r', 'r&i', 'remove', 'install', 'damage', 'collision'];
    for (final action in actions) {
      if (context.toLowerCase().contains(action)) {
        // Capitalize first letter
        final capitalizedTrigger = trigger[0].toUpperCase() + trigger.substring(1);
        return '$capitalizedTrigger $action';
      }
    }
    
    return trigger[0].toUpperCase() + trigger.substring(1);
  }

  void _flattenJson(dynamic data, Map<String, dynamic> result, String prefix) {
    if (data is Map) {
      for (final entry in data.entries) {
        final key = entry.key.toString();
        final fullKey = prefix.isEmpty ? key : '$prefix.$key';
        result[key.toLowerCase()] = entry.value;
        result[fullKey.toLowerCase()] = entry.value;
        _flattenJson(entry.value, result, fullKey);
      }
    } else if (data is List) {
      for (int i = 0; i < data.length; i++) {
        _flattenJson(data[i], result, '$prefix[$i]');
      }
    }
  }

  String _findValue(Map<String, dynamic> values, List<String> keys) {
    for (final key in keys) {
      final lowerKey = key.toLowerCase().replaceAll(' ', '');
      for (final entry in values.entries) {
        final entryKey = entry.key.toLowerCase().replaceAll(' ', '').replaceAll('_', '').replaceAll('.', '');
        if (entryKey == lowerKey || entryKey.endsWith(lowerKey)) {
          final val = entry.value;
          if (val != null && val.toString().isNotEmpty && val.toString() != 'null') {
            return val.toString();
          }
        }
      }
    }
    return '';
  }

  String? _findValueExact(Map<String, dynamic> values, String key) {
    final lowerKey = key.toLowerCase();
    for (final entry in values.entries) {
      if (entry.key.toLowerCase() == lowerKey) {
        final val = entry.value;
        if (val != null && val.toString().isNotEmpty && val.toString() != 'null') {
          return val.toString();
        }
      }
    }
    return null;
  }

  Map<String, String>? _extractCalibration(dynamic item) {
    if (item is Map) {
      String name = '';
      String reason = '';
      
      for (final entry in item.entries) {
        final key = entry.key.toString().toLowerCase();
        final value = entry.value?.toString() ?? '';
        
        if (key.contains('name') || key.contains('system') || key.contains('type') || 
            key.contains('calibration') || key.contains('service')) {
          if (name.isEmpty) name = value;
        } else if (key.contains('reason') || key.contains('because') || 
                   key.contains('trigger') || key.contains('cause') || key.contains('why')) {
          if (reason.isEmpty) reason = value;
        }
      }
      
      if (name.isNotEmpty) {
        return {'name': name, 'reason': reason};
      }
    } else if (item is String && item.isNotEmpty) {
      return {'name': item, 'reason': ''};
    }
    return null;
  }

  Map<String, String> _parseCalibrationString(String key, String value) {
    // Check if the value contains " - " pattern for reason
    if (value.contains(' - ')) {
      final parts = value.split(' - ');
      return {'name': parts[0].trim(), 'reason': parts.sublist(1).join(' - ').trim()};
    }
    return {'name': value, 'reason': ''};
  }

  List<Map<String, String>> _extractCalibrationsFromText(String text) {
    final calibrations = <Map<String, String>>[];
    final lines = text.split('\n');
    
    final calibrationPatterns = [
      RegExp(r'calibration[:\s]*([A-Za-z0-9\s\-\/]+)(?:\s*[-–]\s*(?:because[:\s]*)?(.+))?', caseSensitive: false),
      RegExp(r'(ACC|AEB|LKA|LDW|BSW|BSM|RCTA|APA|BUC|SVC|AHL|SAS|FCW|NV|TSR|DMS)\s*[-–:]\s*(.+)?', caseSensitive: false),
    ];
    
    for (final line in lines) {
      for (final pattern in calibrationPatterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          final name = match.group(1)?.trim() ?? '';
          final reason = match.group(2)?.trim() ?? '';
          if (name.isNotEmpty) {
            calibrations.add({'name': name, 'reason': reason});
          }
        }
      }
    }
    
    return calibrations;
  }

  Map<String, dynamic> _extractFromRawText(String content) {
    final result = <String, dynamic>{
      'year': '',
      'make': '',
      'model': '',
      'vin': '',
      'calibrations': <Map<String, String>>[],
    };

    // Extract year (4-digit number between 1990-2030)
    final yearMatch = RegExp(r'\b(19[9]\d|20[0-3]\d)\b').firstMatch(content);
    if (yearMatch != null) {
      result['year'] = yearMatch.group(1) ?? '';
    }

    // Extract VIN (17 characters)
    final vinMatch = RegExp(r'\b[A-HJ-NPR-Z0-9]{17}\b').firstMatch(content);
    if (vinMatch != null) {
      result['vin'] = vinMatch.group(0) ?? '';
    }

    // Known makes
    final makes = [
      'Acura', 'Alfa Romeo', 'Audi', 'BMW', 'Buick', 'Cadillac', 'Chevrolet',
      'Chrysler', 'Dodge', 'Fiat', 'Ford', 'Genesis', 'GMC', 'Honda', 'Hyundai',
      'Infiniti', 'Jaguar', 'Jeep', 'Kia', 'Land Rover', 'Lexus', 'Lincoln',
      'Mazda', 'Mercedes', 'Mini', 'Mitsubishi', 'Nissan', 'Porsche', 'Ram',
      'Subaru', 'Tesla', 'Toyota', 'Volkswagen', 'Volvo'
    ];
    
    for (final make in makes) {
      if (content.toLowerCase().contains(make.toLowerCase())) {
        result['make'] = make;
        break;
      }
    }

    // Extract calibrations from text
    result['calibrations'] = _extractCalibrationsFromText(content);

    return result;
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearData() {
    setState(() {
      _vehicles = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final analyzedCount = _vehicles.where((v) => !v.isAnalyzing && v.error == null).length;
    final analyzingCount = _vehicles.where((v) => v.isAnalyzing).length;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('ID3 JSON'),
        actions: [
          if (_vehicles.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearData,
              tooltip: 'Clear All',
            ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: _pickJsonFiles,
            tooltip: 'Select Files',
          ),
        ],
      ),
      body: Column(
        children: [
          // Drop Zone
          _buildDropZone(),
          
          // Status
          if (_vehicles.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: analyzingCount > 0 ? Colors.orange.shade900 : Colors.blue.shade900,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (analyzingCount > 0) ...[
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    analyzingCount > 0
                        ? 'Analyzing $analyzingCount file(s)... $analyzedCount completed'
                        : '$analyzedCount vehicle(s) analyzed',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          
          // Results
          Expanded(
            child: _vehicles.isEmpty
                ? _buildEmptyState()
                : _buildResultsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDropZone() {
    return DropTarget(
      onDragDone: (details) async {
        final files = details.files
            .where((f) => f.path.toLowerCase().endsWith('.json') || f.path.toLowerCase().endsWith('.txt'))
            .map((f) => File(f.path))
            .toList();
        
        if (files.isNotEmpty) {
          await _processFiles(files);
        } else {
          _showError('Please drop JSON or Text files only');
        }
      },
      onDragEntered: (details) {
        setState(() => _isDragging = true);
      },
      onDragExited: (details) {
        setState(() => _isDragging = false);
      },
      child: Container(
        height: 120,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isDragging ? Colors.blue.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isDragging ? Colors.blue : Colors.grey,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: InkWell(
          onTap: _pickJsonFiles,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isDragging ? Icons.file_download : Icons.upload_file,
                  size: 40,
                  color: _isDragging ? Colors.blue : Colors.grey,
                ),
                const SizedBox(height: 8),
                Text(
                  _isDragging 
                      ? 'Drop files here' 
                      : 'Drag & Drop JSON or Text files here\nor click to browse\n(Each file = 1 vehicle)',
                  style: TextStyle(
                    color: _isDragging ? Colors.blue : Colors.grey,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insert_drive_file, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No files imported',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Drag and drop JSON or Text files above\nEach file represents one vehicle',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _vehicles.length,
      itemBuilder: (context, index) {
        final vehicle = _vehicles[index];
        return _buildVehicleCard(vehicle, index + 1);
      },
    );
  }

  Widget _buildVehicleCard(_VehicleAnalysis vehicle, int number) {
    if (vehicle.isAnalyzing) {
      return _buildAnalyzingCard(vehicle, number);
    }
    
    if (vehicle.error != null) {
      return _buildErrorCard(vehicle, number);
    }

    final data = vehicle.data!;
    final year = data['year']?.toString() ?? '';
    final make = data['make']?.toString() ?? '';
    final model = data['model']?.toString() ?? '';
    final vin = data['vin']?.toString() ?? '';
    final calibrations = data['calibrations'] as List<Map<String, String>>? ?? [];

    final vehicleInfo = [year, make, model].where((s) => s.isNotEmpty).join(' ');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.check, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicleInfo.isNotEmpty ? vehicleInfo : 'Unknown Vehicle',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        vehicle.fileName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: calibrations.isNotEmpty ? Colors.blue.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${calibrations.length} calibration(s)',
                    style: TextStyle(
                      color: calibrations.isNotEmpty ? Colors.blue : Colors.grey,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            const Divider(height: 24),
            
            // Vehicle Info Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _buildOutputText(year, make, model, vin, calibrations),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: Colors.white,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildOutputText(String year, String make, String model, String vin, List<Map<String, String>> calibrations) {
    final buffer = StringBuffer();
    
    // Vehicle info
    if (year.isNotEmpty) buffer.writeln('Year: $year');
    if (make.isNotEmpty) buffer.writeln('Make: $make');
    if (model.isNotEmpty) buffer.writeln('Model: $model');
    if (vin.isNotEmpty) buffer.writeln('VIN: $vin');
    
    if (year.isEmpty && make.isEmpty && model.isEmpty && vin.isEmpty) {
      buffer.writeln('Vehicle: Unknown');
    }
    
    buffer.writeln('');
    
    // Calibrations
    if (calibrations.isNotEmpty) {
      for (int i = 0; i < calibrations.length; i++) {
        final cal = calibrations[i];
        final system = cal['name'] ?? 'Unknown';
        final reason = cal['reason'] ?? '';
        
        if (reason.isNotEmpty) {
          buffer.writeln('Calibration ${i + 1}: $system $reason');
        } else {
          buffer.writeln('Calibration ${i + 1}: $system');
        }
      }
    } else {
      buffer.writeln('No calibrations found');
    }
    
    return buffer.toString().trimRight();
  }

  Widget _buildAnalyzingCard(_VehicleAnalysis vehicle, int number) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Animated analyzing indicator
            SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.blue.shade400,
                    ),
                  ),
                  Icon(
                    Icons.search,
                    color: Colors.blue.shade400,
                    size: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.fileName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildPulsingDot(),
                      const SizedBox(width: 8),
                      Text(
                        'Analyzing file contents...',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade300,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Progress bar animation
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.grey[800],
                      color: Colors.blue.shade400,
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPulsingDot() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.5, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(value),
            shape: BoxShape.circle,
          ),
        );
      },
      onEnd: () {
        // This will cause the animation to repeat
        setState(() {});
      },
    );
  }

  Widget _buildErrorCard(_VehicleAnalysis vehicle, int number) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.red.shade900.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.red,
              child: const Icon(Icons.error, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.fileName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Error: ${vehicle.error}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.red.shade300,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
