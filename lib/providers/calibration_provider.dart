import 'package:flutter/foundation.dart';
import '../models/calibration_system.dart';
import '../services/database_service.dart';
import '../services/ollama_service.dart';
import '../services/pdf_service.dart';
import 'package:uuid/uuid.dart';

class CalibrationProvider extends ChangeNotifier {
  final DatabaseService _databaseService;
  final OllamaService _ollamaService;
  final PDFService _pdfService;
  
  List<CalibrationSystem> _allSystems = [];
  List<CalibrationSystem> _requiredSystems = [];
  List<CalibrationResult> _recentResults = [];
  bool _isLoading = false;
  bool _ollamaAvailable = false;
  String? _errorMessage;

  CalibrationProvider(this._databaseService)
      : _ollamaService = OllamaService(),
        _pdfService = PDFService() {
    _initialize();
  }

  List<CalibrationSystem> get allSystems => _allSystems;
  List<CalibrationSystem> get requiredSystems => _requiredSystems;
  List<CalibrationResult> get recentResults => _recentResults;
  bool get isLoading => _isLoading;
  bool get ollamaAvailable => _ollamaAvailable;
  String? get errorMessage => _errorMessage;

  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allSystems = await _databaseService.getAllSystems();
      _recentResults = await _databaseService.getRecentResults();
      _ollamaAvailable = await _ollamaService.isAvailable();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to initialize: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Public method to refresh all data from the database
  Future<void> refreshData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allSystems = await _databaseService.getAllSystems();
      _recentResults = await _databaseService.getRecentResults();
      _ollamaAvailable = await _ollamaService.isAvailable();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to refresh: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> analyzeEstimate(String estimateText) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Use enhanced analysis that compares estimate with database
      final systemIds = await _ollamaService.analyzeEstimate(
        estimateText,
        _allSystems,
      );

      // Also get detailed comparison for better insights
      final comparison = await _pdfService.compareDocumentWithDatabase(
        documentText: estimateText,
        databaseSystems: _allSystems,
      );

      // Combine AI results with database-driven comparison
      final combinedSystemIds = <String>{...systemIds};
      for (var matchedSystem in comparison['matched_systems'] as List<CalibrationSystem>) {
        combinedSystemIds.add(matchedSystem.id);
      }

      _requiredSystems = _allSystems
          .where((system) => combinedSystemIds.contains(system.id))
          .toList();

      // Sort by priority
      _requiredSystems.sort((a, b) => a.priority.compareTo(b.priority));

      // Save results to database with detailed reasons
      final uuid = const Uuid();
      final matchReasons = comparison['match_reasons'] as Map<String, List<String>>;
      
      for (var system in _requiredSystems) {
        final reasons = matchReasons[system.id] ?? ['Identified from estimate analysis'];
        final result = CalibrationResult(
          id: uuid.v4(),
          systemId: system.id,
          systemName: system.name,
          reason: reasons.join('; '),
          required: true,
          analyzedAt: DateTime.now(),
        );
        await _databaseService.saveCalibrationResult(result);
      }

      _recentResults = await _databaseService.getRecentResults();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Analysis failed: ${e.toString()}';
      _requiredSystems = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<String> askQuestion(String question) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get context-aware systems based on the question
      List<CalibrationSystem> contextSystems = _allSystems;
      
      // Check if question mentions specific vehicle types
      if (_containsVehicleKeywords(question)) {
        final vehicleType = _extractVehicleType(question);
        if (vehicleType != null) {
          contextSystems = await _databaseService.getSystemsByVehicleType(vehicleType);
        }
      }
      
      // Check if question mentions impact areas
      if (_containsImpactKeywords(question)) {
        final impactArea = _extractImpactArea(question);
        if (impactArea != null) {
          final impactSystems = await _databaseService.getSystemsByImpactArea(impactArea);
          // Combine with existing context or use impact systems if no other context
          if (contextSystems == _allSystems) {
            contextSystems = impactSystems;
          } else {
            // Merge systems, avoiding duplicates
            final combinedIds = <String>{};
            final combinedSystems = <CalibrationSystem>[];
            
            for (var system in contextSystems) {
              if (combinedIds.add(system.id)) {
                combinedSystems.add(system);
              }
            }
            
            for (var system in impactSystems) {
              if (combinedIds.add(system.id)) {
                combinedSystems.add(system);
              }
            }
            
            contextSystems = combinedSystems;
          }
        }
      }
      
      // Check if question asks about pre-qualifications
      if (_containsPreQualKeywords(question)) {
        final systemName = _extractSystemName(question);
        if (systemName != null) {
          final preQualSystems = await _databaseService.getPreQualificationRequirements(systemName);
          if (contextSystems == _allSystems) {
            contextSystems = preQualSystems;
          }
        }
      }

      // Check if question mentions DTCs or fault codes
      String? goldBlackContext;
      List<Map<String, dynamic>>? relevantDTCs;
      
      if (_containsDTCKeywords(question)) {
        // Extract DTC codes from the question
        final dtcCodes = _extractDTCCodes(question);
        if (dtcCodes.isNotEmpty) {
          relevantDTCs = [];
          for (final code in dtcCodes) {
            final dtc = await _databaseService.getDTCByCode(code);
            if (dtc != null) {
              relevantDTCs.add(dtc);
            }
          }
        }
        
        // Also search for any relevant DTCs based on keywords
        final searchTerms = _extractDTCSearchTerms(question);
        if (searchTerms.isNotEmpty) {
          for (final term in searchTerms) {
            final searchResults = await _databaseService.searchGoldBlackDTCs(term);
            relevantDTCs ??= [];
            for (final dtc in searchResults.take(10)) {
              if (!relevantDTCs.any((d) => d['dtc_code'] == dtc['dtc_code'])) {
                relevantDTCs.add(dtc);
              }
            }
          }
        }
        
        // Get summary context if asking general DTC questions
        if (relevantDTCs == null || relevantDTCs.isEmpty) {
          goldBlackContext = await _databaseService.getGoldBlackSummaryForAI();
        }
      }

      final answer = await _ollamaService.answerQuestion(
        question,
        contextSystems,
        goldBlackContext: goldBlackContext,
        relevantDTCs: relevantDTCs,
      );
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return answer;
    } catch (e) {
      _errorMessage = 'Question failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return 'Error: ${e.toString()}';
    }
  }

  // Helper methods for context extraction
  bool _containsVehicleKeywords(String question) {
    final vehicleKeywords = [
      'toyota', 'honda', 'ford', 'chevrolet', 'bmw', 'mercedes', 'audi', 'lexus',
      'nissan', 'hyundai', 'kia', 'subaru', 'mazda', 'volkswagen', 'acura',
      'infiniti', 'genesis', 'tesla', 'porsche', 'jaguar', 'land rover',
      '2020', '2021', '2022', '2023', '2024', '2025', 'model year',
      'sedan', 'suv', 'truck', 'coupe', 'hatchback', 'crossover'
    ];
    
    final lowerQuestion = question.toLowerCase();
    return vehicleKeywords.any((keyword) => lowerQuestion.contains(keyword));
  }

  bool _containsImpactKeywords(String question) {
    final impactKeywords = [
      'front', 'rear', 'side', 'quarter panel', 'bumper', 'windshield',
      'headlight', 'taillight', 'door', 'fender', 'hood', 'trunk',
      'roof', 'mirror', 'alignment', 'suspension', 'steering'
    ];
    
    final lowerQuestion = question.toLowerCase();
    return impactKeywords.any((keyword) => lowerQuestion.contains(keyword));
  }

  bool _containsPreQualKeywords(String question) {
    final preQualKeywords = [
      'pre-qual', 'prerequisite', 'requirement', 'needed', 'required',
      'before', 'prior to', 'setup', 'preparation', 'equipment'
    ];
    
    final lowerQuestion = question.toLowerCase();
    return preQualKeywords.any((keyword) => lowerQuestion.contains(keyword));
  }

  String? _extractVehicleType(String question) {
    final lowerQuestion = question.toLowerCase();
    
    // Extract year
    final yearMatch = RegExp(r'\b(20\d{2})\b').firstMatch(lowerQuestion);
    if (yearMatch != null) {
      return yearMatch.group(1);
    }
    
    // Extract make/model
    final makes = ['toyota', 'honda', 'ford', 'chevrolet', 'bmw', 'mercedes', 'audi'];
    for (var make in makes) {
      if (lowerQuestion.contains(make)) {
        return make;
      }
    }
    
    return null;
  }

  String? _extractImpactArea(String question) {
    final lowerQuestion = question.toLowerCase();
    
    if (lowerQuestion.contains('front') || lowerQuestion.contains('front-end')) {
      return 'front';
    } else if (lowerQuestion.contains('rear') || lowerQuestion.contains('back')) {
      return 'rear';
    } else if (lowerQuestion.contains('side') || lowerQuestion.contains('quarter')) {
      return 'side';
    } else if (lowerQuestion.contains('roof') || lowerQuestion.contains('top')) {
      return 'roof';
    } else if (lowerQuestion.contains('suspension') || lowerQuestion.contains('alignment')) {
      return 'suspension';
    }
    
    return null;
  }

  String? _extractSystemName(String question) {
    final lowerQuestion = question.toLowerCase();
    
    final systemNames = [
      'adas', 'camera', 'radar', 'lidar', 'sensor', 'calibration',
      'lane departure', 'blind spot', 'parking assist', 'adaptive cruise',
      'automatic emergency braking', 'pedestrian detection'
    ];
    
    for (var system in systemNames) {
      if (lowerQuestion.contains(system)) {
        return system;
      }
    }
    
    return null;
  }

  bool _containsDTCKeywords(String question) {
    final dtcKeywords = [
      'dtc', 'fault code', 'trouble code', 'diagnostic code', 'error code',
      'gold list', 'black list', 'goldlist', 'blacklist',
      'p0', 'p1', 'p2', 'p3', 'b0', 'b1', 'b2', 'c0', 'c1', 'u0', 'u1',
      'obd', 'obd2', 'obdii', 'can bus'
    ];
    
    final lowerQuestion = question.toLowerCase();
    return dtcKeywords.any((keyword) => lowerQuestion.contains(keyword));
  }

  List<String> _extractDTCCodes(String question) {
    // DTC codes typically follow patterns like P0XXX, B1XXX, C0XXX, U0XXX
    final dtcPattern = RegExp(r'\b([PBCU][0-9][0-9A-F]{2,3})\b', caseSensitive: false);
    final matches = dtcPattern.allMatches(question.toUpperCase());
    return matches.map((m) => m.group(1)!).toList();
  }

  List<String> _extractDTCSearchTerms(String question) {
    final lowerQuestion = question.toLowerCase();
    final terms = <String>[];
    
    // Extract module names
    final modules = ['airbag', 'srs', 'abs', 'esp', 'traction', 'engine', 'transmission', 
                     'bcm', 'pcm', 'ecm', 'tcm', 'steering', 'brake', 'camera', 'radar'];
    for (final module in modules) {
      if (lowerQuestion.contains(module)) {
        terms.add(module);
      }
    }
    
    return terms;
  }

  Future<void> searchSystems(String query) async {
    if (query.isEmpty) {
      _requiredSystems = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _requiredSystems = await _databaseService.searchSystems(query);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Search failed: ${e.toString()}';
      _requiredSystems = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearResults() {
    _requiredSystems = [];
    _errorMessage = null;
    notifyListeners();
  }

  double getTotalEstimatedCost() {
    double total = 0;
    for (var system in _requiredSystems) {
      final costStr = system.estimatedCost
          .replaceAll('\$', '')
          .replaceAll(',', '')
          .split('-')
          .first
          .trim();
      total += double.tryParse(costStr) ?? 0;
    }
    return total;
  }

  String getTotalEstimatedTime() {
    double totalHours = 0;
    for (var system in _requiredSystems) {
      final timeStr = system.estimatedTime.split('-').first.trim();
      final hours = double.tryParse(timeStr.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      totalHours += hours;
    }
    return '${totalHours.toStringAsFixed(1)} hours';
  }

  Future<void> analyzePDFs({
    required String estimatePath,
    String? scanReportPath,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Extract text from estimate PDF (read-only, no saving or printing)
      final estimateText = await _pdfService.extractTextFromPDF(estimatePath);
      
      // If scan report is provided, perform enhanced analysis with fault detection
      if (scanReportPath != null) {
        final comparison = await _pdfService.comparePDFs(
          estimatePath: estimatePath,
          scanReportPath: scanReportPath,
          databaseSystems: _allSystems,
        );
        
        // Get systems from scan analysis (fault-based)
        final scanAnalysis = comparison['scan_analysis'] as Map<String, dynamic>?;
        final scanAffectedSystems = scanAnalysis != null 
            ? (scanAnalysis['affected_systems'] as List<CalibrationSystem>) 
            : <CalibrationSystem>[];
        
        // Get systems from estimate analysis
        final estimateAnalysis = await _pdfService.compareDocumentWithDatabase(
          documentText: estimateText,
          databaseSystems: _allSystems,
        );
        final estimateMatchedSystems = estimateAnalysis['matched_systems'] as List<CalibrationSystem>;
        
        // Combine both lists (scan faults take priority)
        final combinedSystemIds = <String>{};
        final combinedSystems = <CalibrationSystem>[];
        
        // Add scan-based systems first (these have faults)
        for (var system in scanAffectedSystems) {
          if (combinedSystemIds.add(system.id)) {
            combinedSystems.add(system);
          }
        }
        
        // Add estimate-based systems
        for (var system in estimateMatchedSystems) {
          if (combinedSystemIds.add(system.id)) {
            combinedSystems.add(system);
          }
        }
        
        _requiredSystems = combinedSystems;
        _requiredSystems.sort((a, b) => a.priority.compareTo(b.priority));
        
        // Save results
        final uuid = const Uuid();
        for (var system in _requiredSystems) {
          final result = CalibrationResult(
            id: uuid.v4(),
            systemId: system.id,
            systemName: system.name,
            reason: scanAffectedSystems.contains(system) 
                ? 'Fault detected in scan report' 
                : 'Identified from estimate',
            required: true,
            analyzedAt: DateTime.now(),
          );
          await _databaseService.saveCalibrationResult(result);
        }
        
        _recentResults = await _databaseService.getRecentResults();
      } else {
        // Analyze the estimate by comparing with database
        await analyzeEstimate(estimateText);
      }
      
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'PDF analysis failed: ${e.toString()}';
      _requiredSystems = [];
    }

    _isLoading = false;
    notifyListeners();
  }
}

