import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../widgets/screen_wrapper.dart';

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

  /// Comprehensive analysis to find ADAS systems that need calibration based on actual repairs
  List<Map<String, String>> _analyzeForRequiredCalibrations(Map<String, dynamic> allValues, String rawContent) {
    final calibrations = <Map<String, String>>[];
    final addedSystems = <String>{};
    final contentLower = rawContent.toLowerCase();

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

    // Define repair operations and which calibrations they trigger
    // Only these specific repairs will trigger calibrations
    final repairToCalibration = {
      // Front bumper work
      'front bumper': ['ACC', 'AEB', 'APA'],
      'front bumper cover': ['ACC', 'AEB', 'APA'],
      'front bumper r&r': ['ACC', 'AEB', 'APA'],
      'front bumper r&i': ['ACC', 'AEB', 'APA'],
      'front bumper replace': ['ACC', 'AEB', 'APA'],
      'front bumper repair': ['ACC', 'AEB', 'APA'],
      
      // Rear bumper work
      'rear bumper': ['BSW', 'RCTA', 'APA', 'BUC'],
      'rear bumper cover': ['BSW', 'RCTA', 'APA', 'BUC'],
      'rear bumper r&r': ['BSW', 'RCTA', 'APA', 'BUC'],
      'rear bumper r&i': ['BSW', 'RCTA', 'APA', 'BUC'],
      'rear bumper replace': ['BSW', 'RCTA', 'APA', 'BUC'],
      'rear bumper repair': ['BSW', 'RCTA', 'APA', 'BUC'],
      
      // Windshield work
      'windshield': ['LKA', 'LDW', 'AEB', 'TSR', 'HUD'],
      'windshield replace': ['LKA', 'LDW', 'AEB', 'TSR', 'HUD'],
      'windshield r&r': ['LKA', 'LDW', 'AEB', 'TSR', 'HUD'],
      'windshield r&i': ['LKA', 'LDW', 'AEB', 'TSR', 'HUD'],
      'front glass': ['LKA', 'LDW', 'AEB', 'TSR', 'HUD'],
      
      // Grille work
      'grille': ['ACC', 'AEB', 'NV'],
      'grille r&r': ['ACC', 'AEB', 'NV'],
      'grille r&i': ['ACC', 'AEB', 'NV'],
      'grille replace': ['ACC', 'AEB', 'NV'],
      'front grille': ['ACC', 'AEB', 'NV'],
      
      // Quarter panel work
      'quarter panel': ['BSW', 'RCTA'],
      'rear quarter': ['BSW', 'RCTA'],
      'quarter panel r&r': ['BSW', 'RCTA'],
      'quarter panel repair': ['BSW', 'RCTA'],
      
      // Headlight work
      'headlight': ['AHL'],
      'headlamp': ['AHL'],
      'headlight r&r': ['AHL'],
      'headlight r&i': ['AHL'],
      'headlight replace': ['AHL'],
      'headlamp replace': ['AHL'],
      
      // Mirror work
      'mirror': ['BSW', 'SVC'],
      'side mirror': ['BSW', 'SVC'],
      'mirror r&r': ['BSW', 'SVC'],
      'mirror r&i': ['BSW', 'SVC'],
      'mirror replace': ['BSW', 'SVC'],
      
      // Tailgate/Trunk work
      'tailgate': ['BUC', 'SVC'],
      'trunk': ['BUC'],
      'liftgate': ['BUC', 'SVC'],
      'tailgate r&r': ['BUC', 'SVC'],
      'trunk lid': ['BUC'],
      
      // Steering/Suspension work
      'alignment': ['SAS'],
      'wheel alignment': ['SAS'],
      'steering': ['SAS'],
      'suspension': ['SAS', 'AHL'],
      'tie rod': ['SAS'],
      'control arm': ['SAS'],
      'strut': ['SAS', 'AHL'],
      
      // Radar/Sensor work
      'radar': ['ACC', 'AEB', 'BSW'],
      'front radar': ['ACC', 'AEB'],
      'rear radar': ['BSW', 'RCTA'],
      'radar sensor': ['ACC', 'AEB', 'BSW'],
      
      // Camera work
      'camera': ['LKA', 'BUC', 'SVC'],
      'front camera': ['LKA', 'LDW', 'AEB', 'TSR'],
      'rear camera': ['BUC'],
      'backup camera': ['BUC'],
      'surround camera': ['SVC'],
      '360 camera': ['SVC'],
      
      // Collision areas
      'front collision': ['ACC', 'AEB', 'LKA', 'AHL', 'NV'],
      'front end damage': ['ACC', 'AEB', 'LKA', 'AHL', 'NV'],
      'front impact': ['ACC', 'AEB', 'LKA', 'AHL', 'NV'],
      'rear collision': ['BSW', 'RCTA', 'BUC', 'APA'],
      'rear end damage': ['BSW', 'RCTA', 'BUC', 'APA'],
      'rear impact': ['BSW', 'RCTA', 'BUC', 'APA'],
      'side collision': ['BSW', 'SVC'],
      'side impact': ['BSW', 'SVC'],
      
      // Radiator support
      'radiator support': ['ACC', 'AEB', 'NV'],
      'radiator': ['ACC', 'NV'],
      
      // Sensor work
      'parking sensor': ['APA'],
      'ultrasonic sensor': ['APA'],
      'blind spot sensor': ['BSW'],
    };

    // Step 1: Find all repairs mentioned in the file
    final repairsFound = <String, String>{};  // repair -> context
    
    for (final repair in repairToCalibration.keys) {
      if (contentLower.contains(repair)) {
        // Find context to use as reason
        final context = _extractRepairContext(rawContent, repair);
        repairsFound[repair] = context;
      }
    }

    // Step 2: For each repair found, add the corresponding calibrations
    for (final entry in repairsFound.entries) {
      final repair = entry.key;
      final context = entry.value;
      final systems = repairToCalibration[repair] ?? [];
      
      for (final system in systems) {
        if (!addedSystems.contains(system)) {
          addedSystems.add(system);
          calibrations.add({
            'name': '${systemFullNames[system]} ($system)',
            'reason': context,
          });
        }
      }
    }

    // Step 3: Check for explicit calibration entries in structured data
    // This handles cases where the JSON explicitly lists calibrations needed
    for (int i = 1; i <= 20; i++) {
      final calKeys = ['calibration$i', 'calibration_$i', 'cal$i', 'cal_$i', 'system$i', 'system_$i', 'adas$i'];
      
      for (final calKey in calKeys) {
        final calValue = _findValueExact(allValues, calKey);
        if (calValue != null && calValue.isNotEmpty) {
          // Try to match to known system
          String systemName = calValue;
          String? matchedCode;
          
          final systemAliases = {
            'ACC': ['acc', 'adaptive cruise'],
            'AEB': ['aeb', 'auto emergency', 'emergency braking', 'collision mitigation'],
            'LKA': ['lka', 'lane keep', 'lane assist'],
            'LDW': ['ldw', 'lane departure'],
            'BSW': ['bsw', 'blind spot'],
            'RCTA': ['rcta', 'rear cross traffic'],
            'APA': ['apa', 'parking assist', 'park assist'],
            'BUC': ['buc', 'backup camera', 'rear camera'],
            'SVC': ['svc', 'surround view', '360'],
            'AHL': ['ahl', 'adaptive headlight'],
            'SAS': ['sas', 'steering angle'],
            'NV': ['nv', 'night vision'],
            'TSR': ['tsr', 'traffic sign'],
            'DMS': ['dms', 'driver monitor'],
            'HUD': ['hud', 'head up', 'heads up'],
          };
          
          for (final sysEntry in systemAliases.entries) {
            for (final alias in sysEntry.value) {
              if (calValue.toLowerCase().contains(alias)) {
                matchedCode = sysEntry.key;
                systemName = '${systemFullNames[matchedCode]} ($matchedCode)';
                break;
              }
            }
            if (matchedCode != null) break;
          }
          
          // Find reason
          String reason = '';
          for (final reasonKey in ['reason$i', 'reason_$i', 'because$i', 'because_$i', 'trigger$i', 'cause$i']) {
            final rv = _findValueExact(allValues, reasonKey);
            if (rv != null && rv.isNotEmpty) {
              reason = rv;
              break;
            }
          }
          
          // Only add if not already added or if it has a specific reason
          final keyToCheck = matchedCode ?? calValue;
          if (!addedSystems.contains(keyToCheck)) {
            addedSystems.add(keyToCheck);
            calibrations.add({
              'name': systemName,
              'reason': reason.isNotEmpty ? reason : 'Per repair requirements',
            });
          }
          break;
        }
      }
    }

    // Step 4: Check for calibration fields with explicit system and reason
    for (final entry in allValues.entries) {
      final key = entry.key.toLowerCase();
      final value = entry.value?.toString() ?? '';
      
      // Look for keys that explicitly state calibration is needed
      if ((key.contains('calibration') && key.contains('required')) ||
          (key.contains('calibration') && key.contains('needed')) ||
          key.contains('needs_calibration') ||
          key.contains('requires_calibration')) {
        
        if (value.toLowerCase() == 'true' || value.toLowerCase() == 'yes' || value == '1') {
          // Find which system this relates to
          final systemKey = key.replaceAll('calibration', '').replaceAll('required', '')
              .replaceAll('needed', '').replaceAll('_', '').trim();
          
          for (final sysEntry in systemFullNames.entries) {
            if (systemKey.toLowerCase().contains(sysEntry.key.toLowerCase())) {
              if (!addedSystems.contains(sysEntry.key)) {
                addedSystems.add(sysEntry.key);
                calibrations.add({
                  'name': '${sysEntry.value} (${sysEntry.key})',
                  'reason': 'Calibration flagged as required',
                });
              }
              break;
            }
          }
        }
      }
    }

    return calibrations;
  }

  /// Extract the repair context to use as the reason
  String _extractRepairContext(String content, String repair) {
    final contentLower = content.toLowerCase();
    final repairLower = repair.toLowerCase();
    
    final index = contentLower.indexOf(repairLower);
    if (index == -1) return _capitalizeFirst(repair);
    
    // Look for action words near the repair mention
    final start = (index - 50).clamp(0, content.length);
    final end = (index + repair.length + 50).clamp(0, content.length);
    final context = content.substring(start, end).toLowerCase();
    
    // Find the action being performed
    String action = '';
    final actions = [
      ('replace', 'replacement'),
      ('r&r', 'R&R'),
      ('r&i', 'R&I'),
      ('repair', 'repair'),
      ('remove', 'removal'),
      ('install', 'installation'),
      ('damage', 'damage'),
      ('collision', 'collision'),
      ('impact', 'impact'),
    ];
    
    for (final (keyword, display) in actions) {
      if (context.contains(keyword)) {
        action = display;
        break;
      }
    }
    
    final repairCapitalized = _capitalizeFirst(repair);
    if (action.isNotEmpty) {
      return '$repairCapitalized $action';
    }
    return repairCapitalized;
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
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
    
    return ScreenWrapper(
      title: 'ID3 JSON',
      subtitle: 'Import and analyze vehicle calibration data',
      accentColor: AppColors.cardJSON,
      actions: [
        if (_vehicles.isNotEmpty)
          NeumorphicIconButton(
            icon: Icons.clear_all_rounded,
            onPressed: _clearData,
            tooltip: 'Clear All',
            color: AppColors.error,
          ),
        NeumorphicIconButton(
          icon: Icons.folder_open_rounded,
          onPressed: _pickJsonFiles,
          tooltip: 'Select Files',
          color: AppColors.cardJSON,
        ),
      ],
      child: Column(
        children: [
          _buildDropZone(),
          
          if (_vehicles.isNotEmpty)
            _buildStatusBar(analyzingCount, analyzedCount),
          
          Expanded(
            child: _vehicles.isEmpty
                ? _buildEmptyState()
                : _buildResultsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar(int analyzingCount, int analyzedCount) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 28),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: NeumorphicDecoration.glowingBorder(
        glowColor: analyzingCount > 0 ? AppColors.warning : AppColors.primaryBlue,
        radius: 14,
        glowIntensity: 0.3,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (analyzingCount > 0) ...[
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.warning),
              ),
            ),
            const SizedBox(width: 12),
          ] else ...[
            Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 20,
            ),
            const SizedBox(width: 8),
          ],
          Text(
            analyzingCount > 0
                ? 'Analyzing $analyzingCount file(s)... $analyzedCount completed'
                : '$analyzedCount vehicle(s) analyzed',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: analyzingCount > 0 ? AppColors.warning : AppColors.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
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
      child: GestureDetector(
        onTap: _pickJsonFiles,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 140,
          margin: const EdgeInsets.fromLTRB(28, 16, 28, 16),
          decoration: _isDragging
              ? NeumorphicDecoration.glowingBorder(
                  glowColor: AppColors.cardJSON,
                  radius: 20,
                  glowIntensity: 0.7,
                )
              : NeumorphicDecoration.concave(radius: 20),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isDragging
                        ? AppColors.cardJSON.withOpacity(0.2)
                        : AppColors.backgroundLight.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _isDragging ? Icons.file_download_rounded : Icons.cloud_upload_rounded,
                    size: 36,
                    color: _isDragging ? AppColors.cardJSON : AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _isDragging 
                      ? 'Drop files here' 
                      : 'Drag & Drop JSON or Text files',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _isDragging ? AppColors.cardJSON : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isDragging 
                      ? 'Release to import' 
                      : 'or click to browse  •  Each file = 1 vehicle',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1);
  }

  Widget _buildEmptyState() {
    return EmptyState(
      icon: Icons.description_outlined,
      title: 'No files imported',
      subtitle: 'Drag and drop JSON or Text files above\nEach file represents one vehicle',
      iconColor: AppColors.cardJSON.withOpacity(0.5),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
      itemCount: _vehicles.length,
      itemBuilder: (context, index) {
        final vehicle = _vehicles[index];
        return _buildVehicleCard(vehicle, index + 1)
            .animate(delay: (index * 100).ms)
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.1);
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: NeumorphicDecoration.flat(radius: 20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: AppColors.success,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicleInfo.isNotEmpty ? vehicleInfo : 'Unknown Vehicle',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        vehicle.fileName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: calibrations.isNotEmpty 
                        ? AppColors.primaryBlue.withOpacity(0.15) 
                        : AppColors.textMuted.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: calibrations.isNotEmpty 
                          ? AppColors.primaryBlue.withOpacity(0.3) 
                          : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    '${calibrations.length} calibration${calibrations.length != 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: calibrations.isNotEmpty ? AppColors.primaryBlue : AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            Container(height: 1, color: AppColors.shadowLight.withOpacity(0.3)),
            const SizedBox(height: 16),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: NeumorphicDecoration.concave(radius: 14),
              child: SelectableText(
                _buildOutputText(year, make, model, vin, calibrations),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.7,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: NeumorphicDecoration.glowingBorder(
        glowColor: AppColors.primaryBlue,
        radius: 20,
        glowIntensity: 0.3,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                    ),
                  ),
                  Icon(
                    Icons.search_rounded,
                    color: AppColors.primaryBlue,
                    size: 18,
                  ).animate(onPlay: (c) => c.repeat())
                      .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 800.ms)
                      .then()
                      .scale(begin: const Offset(1.1, 1.1), end: const Offset(0.9, 0.9), duration: 800.ms),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.fileName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildPulsingDot(),
                      const SizedBox(width: 10),
                      Text(
                        'Analyzing file contents...',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      backgroundColor: AppColors.backgroundLight,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                      minHeight: 6,
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
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat())
        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 600.ms)
        .then()
        .scale(begin: const Offset(1.2, 1.2), end: const Offset(0.8, 0.8), duration: 600.ms);
  }

  Widget _buildErrorCard(_VehicleAnalysis vehicle, int number) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: NeumorphicDecoration.glowingBorder(
        glowColor: AppColors.error,
        radius: 20,
        glowIntensity: 0.4,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.fileName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Error: ${vehicle.error}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.error,
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
