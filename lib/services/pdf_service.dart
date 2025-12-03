import 'dart:io';
import '../models/calibration_system.dart';

class FaultEntry {
  final String system;
  final String code;
  final String description;
  final bool isFault; // true = Fault, false = No Fault
  
  FaultEntry({
    required this.system,
    required this.code,
    required this.description,
    required this.isFault,
  });
}

class PDFService {
  /// Extract text from a PDF file
  /// Note: This method only extracts text for analysis, it does NOT save or print the document
  Future<String> extractTextFromPDF(String filePath) async {
    try {
      // Extract text using simple byte parsing
      // This is read-only and does not modify or save the PDF
      return await _extractTextSimple(filePath);
    } catch (e) {
      throw Exception('Failed to extract PDF text: ${e.toString()}');
    }
  }

  Future<String> _extractTextSimple(String filePath) async {
    try {
      // Simple text extraction - reads the PDF file
      // For better extraction, you might want to use a specialized PDF library
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      
      // Try to extract readable text from bytes
      String text = String.fromCharCodes(bytes
          .where((byte) => byte >= 32 && byte <= 126 || byte == 10 || byte == 13)
          .toList());
      
      return text;
    } catch (e) {
      throw Exception('PDF text extraction failed: ${e.toString()}');
    }
  }

  /// Analyze PDF estimate for calibration keywords with enhanced ADAS detection
  Future<List<String>> analyzeEstimateForKeywords(String text) async {
    final keywords = <String>[];
    final lowerText = text.toLowerCase();

    // Check for common repair keywords that trigger calibrations
    final triggers = {
      'windshield': ['windshield', 'windscreen', 'front glass', 'w/s', 'w/shield'],
      'bumper': ['bumper', 'fascia', 'front bumper', 'rear bumper', 'f/bumper', 'r/bumper'],
      'mirror': ['mirror', 'side mirror', 'door mirror', 'outside mirror'],
      'camera': ['camera', 'backup camera', 'rear camera', 'front camera', 'cam'],
      'sensor': ['sensor', 'parking sensor', 'proximity sensor', 'ultrasonic'],
      'radar': ['radar', 'adaptive cruise', 'acc', 'radar module'],
      'alignment': ['alignment', 'wheel alignment', '4-wheel alignment', 'align', 'toe', 'camber'],
      'suspension': ['suspension', 'strut', 'shock', 'spring', 'control arm'],
      'airbag': ['airbag', 'air bag', 'srs', 'restraint'],
      'steering': ['steering', 'steering wheel', 'power steering', 'rack', 'column'],
      'headlight': ['headlight', 'headlamp', 'front light', 'h/lamp'],
      'quarter panel': ['quarter panel', 'quarter', 'rear panel', 'qtr panel'],
      'hood': ['hood', 'bonnet', 'engine lid'],
      'roof': ['roof', 'roof panel', 'headliner'],
      'door': ['door', 'front door', 'rear door'],
      // Enhanced ADAS-specific keywords
      'adas': ['adas', 'advanced driver', 'driver assist', 'driver assistance'],
      'collision_warning': ['collision warning', 'fcw', 'forward collision'],
      'lane_departure': ['lane departure', 'ldw', 'lka', 'lane keep', 'lane assist'],
      'blind_spot': ['blind spot', 'bsm', 'blis', 'side assist'],
      'parking_assist': ['parking assist', 'park assist', 'pdc'],
      'emergency_braking': ['emergency brake', 'aeb', 'automatic braking', 'collision mitigation'],
      'adaptive_cruise': ['adaptive cruise', 'acc', 'dynamic cruise'],
    };

    for (var entry in triggers.entries) {
      for (var keyword in entry.value) {
        if (lowerText.contains(keyword)) {
          keywords.add(entry.key);
          break;
        }
      }
    }

    return keywords.toSet().toList(); // Remove duplicates
  }

  /// Parse scan report to find fault entries (not "No Fault")
  Future<List<FaultEntry>> parseScanReportForFaults(String scanText) async {
    final faults = <FaultEntry>[];
    final lines = scanText.split('\n');
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      final lowerLine = line.toLowerCase();
      
      // Look for fault indicators (skip "No Fault" entries)
      if (lowerLine.contains('fault') && !lowerLine.contains('no fault')) {
        // Extract fault information
        String system = 'Unknown System';
        String code = '';
        String description = line;
        
        // Try to identify the system from context
        if (i > 0) {
          final prevLine = lines[i - 1].toLowerCase();
          system = _identifySystemFromContext(prevLine + ' ' + lowerLine);
        }
        
        // Try to extract fault code (common patterns: B1234, C5678, U0123, P0456)
        final codeMatch = RegExp(r'\b([BCUP]\d{4})\b', caseSensitive: false).firstMatch(line);
        if (codeMatch != null) {
          code = codeMatch.group(1) ?? '';
        }
        
        faults.add(FaultEntry(
          system: system,
          code: code,
          description: description,
          isFault: true,
        ));
      }
    }
    
    return faults;
  }

  /// Identify ADAS system from context
  String _identifySystemFromContext(String context) {
    final lowerContext = context.toLowerCase();
    
    if (lowerContext.contains('camera') || lowerContext.contains('fcm') || 
        lowerContext.contains('forward') || lowerContext.contains('vision')) {
      return 'Camera System';
    } else if (lowerContext.contains('radar') || lowerContext.contains('acc') || 
               lowerContext.contains('adaptive cruise')) {
      return 'Radar System';
    } else if (lowerContext.contains('lane') || lowerContext.contains('ldw') || 
               lowerContext.contains('lka')) {
      return 'Lane Departure System';
    } else if (lowerContext.contains('blind') || lowerContext.contains('bsm') || 
               lowerContext.contains('blis')) {
      return 'Blind Spot System';
    } else if (lowerContext.contains('parking') || lowerContext.contains('pdc') || 
               lowerContext.contains('sensor')) {
      return 'Parking Assist System';
    } else if (lowerContext.contains('brake') || lowerContext.contains('aeb') || 
               lowerContext.contains('emergency')) {
      return 'Emergency Braking System';
    } else if (lowerContext.contains('steering') || lowerContext.contains('sas')) {
      return 'Steering System';
    } else if (lowerContext.contains('headlight') || lowerContext.contains('afs')) {
      return 'Adaptive Lighting System';
    }
    
    return 'ADAS System';
  }

  /// Enhanced ADAS detection using keywords from database
  Future<List<CalibrationSystem>> identifyADASSystemsFromText({
    required String text,
    required List<CalibrationSystem> allSystems,
  }) async {
    final matchedSystems = <CalibrationSystem>[];
    final lowerText = text.toLowerCase();
    
    for (var system in allSystems) {
      // Check if any ADAS keywords match
      for (var keyword in system.adasKeywords) {
        if (lowerText.contains(keyword.toLowerCase())) {
          matchedSystems.add(system);
          break; // Found a match, move to next system
        }
      }
    }
    
    return matchedSystems;
  }

  /// Compare document information with database calibration systems
  /// Returns matched systems and reasons for calibration with enhanced ADAS detection
  Future<Map<String, dynamic>> compareDocumentWithDatabase({
    required String documentText,
    required List<CalibrationSystem> databaseSystems,
  }) async {
    final documentKeywords = await analyzeEstimateForKeywords(documentText);
    final matchedSystems = <CalibrationSystem>[];
    final matchReasons = <String, List<String>>{};

    // First, use enhanced ADAS keyword detection
    final adasMatches = await identifyADASSystemsFromText(
      text: documentText,
      allSystems: databaseSystems,
    );
    
    for (var system in adasMatches) {
      if (!matchedSystems.contains(system)) {
        matchedSystems.add(system);
        matchReasons[system.id] = ['ADAS system identified in document'];
      }
    }

    // Compare each database system against the document
    for (var system in databaseSystems) {
      final reasons = matchReasons[system.id] ?? <String>[];
      
      // Check if any of the system's required triggers appear in the document
      for (var trigger in system.requiredFor) {
        final lowerTrigger = trigger.toLowerCase();
        final lowerText = documentText.toLowerCase();
        
        // Direct match in document text
        if (lowerText.contains(lowerTrigger)) {
          reasons.add('Document mentions: $trigger');
          continue;
        }
        
        // Match via extracted keywords
        for (var keyword in documentKeywords) {
          if (lowerTrigger.contains(keyword) || keyword.contains(lowerTrigger)) {
            reasons.add('Related to: $keyword (triggers: $trigger)');
            break;
          }
        }
      }
      
      if (reasons.isNotEmpty) {
        if (!matchedSystems.contains(system)) {
          matchedSystems.add(system);
        }
        matchReasons[system.id] = reasons;
      }
    }

    return {
      'document_keywords': documentKeywords,
      'matched_systems': matchedSystems,
      'match_reasons': matchReasons,
      'total_matches': matchedSystems.length,
      'document_text_length': documentText.length,
      'database_systems_checked': databaseSystems.length,
    };
  }

  /// Analyze scan report for faults and match to ADAS systems
  Future<Map<String, dynamic>> analyzeScanReportWithFaults({
    required String scanReportText,
    required List<CalibrationSystem> databaseSystems,
  }) async {
    // Parse scan report for fault entries
    final faults = await parseScanReportForFaults(scanReportText);
    
    // Identify ADAS systems mentioned in scan report
    final adasSystemsInScan = await identifyADASSystemsFromText(
      text: scanReportText,
      allSystems: databaseSystems,
    );
    
    // Match faults to affected ADAS systems
    final affectedSystems = <CalibrationSystem>[];
    final faultDetails = <String, Map<String, dynamic>>{};
    
    for (var system in adasSystemsInScan) {
      // Check if this system has related faults
      final relatedFaults = <FaultEntry>[];
      
      for (var fault in faults) {
        // Check if fault is related to this system
        final faultContext = '${fault.system} ${fault.description}'.toLowerCase();
        bool isRelated = false;
        
        // Check against system's ADAS keywords
        for (var keyword in system.adasKeywords) {
          if (faultContext.contains(keyword.toLowerCase())) {
            isRelated = true;
            break;
          }
        }
        
        if (isRelated) {
          relatedFaults.add(fault);
        }
      }
      
      if (relatedFaults.isNotEmpty) {
        affectedSystems.add(system);
        faultDetails[system.id] = {
          'system': system,
          'faults': relatedFaults,
          'pre_qualifications': system.preQualifications,
          'hyperlink': system.hyperlink,
        };
      }
    }
    
    return {
      'all_faults': faults,
      'affected_systems': affectedSystems,
      'fault_details': faultDetails,
      'total_faults': faults.length,
      'total_affected_systems': affectedSystems.length,
    };
  }

  /// Compare estimate PDF with scan report PDF (for dual-document analysis)
  /// Enhanced with fault detection and ADAS system matching
  Future<Map<String, dynamic>> comparePDFs({
    required String estimatePath,
    String? scanReportPath,
    List<CalibrationSystem>? databaseSystems,
  }) async {
    final estimateText = await extractTextFromPDF(estimatePath);
    final estimateKeywords = await analyzeEstimateForKeywords(estimateText);

    List<String> scanKeywords = [];
    String? scanText;
    List<FaultEntry> scanFaults = [];
    Map<String, dynamic>? scanAnalysis;

    if (scanReportPath != null) {
      scanText = await extractTextFromPDF(scanReportPath);
      scanKeywords = await analyzeEstimateForKeywords(scanText);
      
      // Analyze scan report for faults if database systems provided
      if (databaseSystems != null) {
        scanAnalysis = await analyzeScanReportWithFaults(
          scanReportText: scanText,
          databaseSystems: databaseSystems,
        );
        scanFaults = scanAnalysis['all_faults'] as List<FaultEntry>;
      }
    }

    // Find keywords in estimate but not in scan report
    final missing = estimateKeywords
        .where((keyword) => !scanKeywords.contains(keyword))
        .toList();

    // Find keywords in scan report but not in estimate
    final additional = scanKeywords
        .where((keyword) => !estimateKeywords.contains(keyword))
        .toList();

    return {
      'estimate_text': estimateText,
      'scan_text': scanText,
      'estimate_keywords': estimateKeywords,
      'scan_keywords': scanKeywords,
      'missing_in_scan': missing,
      'additional_in_scan': additional,
      'match_percentage': scanKeywords.isEmpty
          ? 0.0
          : (estimateKeywords.where((k) => scanKeywords.contains(k)).length /
                  estimateKeywords.length) *
              100,
      'scan_faults': scanFaults,
      'scan_analysis': scanAnalysis,
    };
  }
}



