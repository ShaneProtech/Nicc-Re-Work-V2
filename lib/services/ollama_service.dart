import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/calibration_system.dart';

class OllamaService {
  final String baseUrl;
  final String model;

  OllamaService({
    this.baseUrl = 'http://localhost:11434',
    this.model = 'mistral',
  });

  Future<bool> isAvailable() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/tags'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> analyzeEstimate(
    String estimateText,
    List<CalibrationSystem> allSystems,
  ) async {
    // First, extract keywords from the estimate for structured analysis
    final estimateKeywords = _extractKeywordsFromText(estimateText);
    
    // Build comprehensive system context with detailed database information
    final systemsContext = allSystems.map((s) {
      return '''
System ID: ${s.id}
Name: ${s.name}
Category: ${s.category}
Triggers: ${s.requiredFor.join(", ")}
Priority: ${s.priority}
Cost: ${s.estimatedCost}
Time: ${s.estimatedTime}
Description: ${s.description}''';
    }).join('\n---\n');

    final prompt = '''You are an expert ADAS (Advanced Driver Assistance Systems) calibration specialist with access to a comprehensive calibration database.

YOUR TASK: Compare the repair estimate details with the calibration database to determine which calibrations and/or programmings are needed.

CALIBRATION DATABASE:
$systemsContext

REPAIR ESTIMATE DETAILS:
$estimateText

EXTRACTED KEYWORDS FROM ESTIMATE: ${estimateKeywords.join(", ")}

ANALYSIS INSTRUCTIONS:
1. Carefully read the repair estimate details
2. Cross-reference each repair item with the calibration database triggers
3. For each database system, check if ANY of its triggers match the repair items
4. Consider both direct matches (e.g., "windshield replacement" matches ADAS Camera) and indirect matches (e.g., "front collision" may affect multiple systems)
5. Prioritize high-priority systems (priority 1-2) when repairs affect them
6. List ALL calibration systems that may be affected by the repairs described

OUTPUT FORMAT:
List ONLY the exact System IDs (from the database above) that require calibration or programming.
One system ID per line, nothing else.
If uncertain, include the system rather than risk missing a required calibration.

System IDs to return:''';

    try {
      final response = await _generateCompletion(prompt);
      final lines = response.split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      
      // Match response lines with actual system IDs or names
      final matchedSystems = <String>{};
      for (var system in allSystems) {
        for (var line in lines) {
          final lowerLine = line.toLowerCase();
          // Check if line matches system ID or system name
          if (lowerLine.contains(system.id.toLowerCase()) ||
              lowerLine.contains(system.name.toLowerCase()) ||
              system.id.toLowerCase().contains(lowerLine) ||
              system.name.toLowerCase().contains(lowerLine)) {
            matchedSystems.add(system.id);
            break;
          }
        }
      }
      
      // Also perform database-driven keyword analysis as additional validation
      final keywordMatches = _databaseDrivenAnalysis(estimateText, estimateKeywords, allSystems);
      matchedSystems.addAll(keywordMatches);
      
      return matchedSystems.toList();
    } catch (e) {
      // Fallback to enhanced database-driven analysis if Ollama fails
      return _databaseDrivenAnalysis(estimateText, estimateKeywords, allSystems).toList();
    }
  }

  /// Extract repair-related keywords from estimate text
  List<String> _extractKeywordsFromText(String text) {
    final lowerText = text.toLowerCase();
    final keywords = <String>[];
    
    // Common repair keywords that trigger calibrations
    final repairKeywords = [
      'windshield', 'windscreen', 'front glass',
      'bumper', 'fascia', 'front bumper', 'rear bumper',
      'mirror', 'side mirror', 'door mirror',
      'camera', 'backup camera', 'rear camera', 'front camera',
      'sensor', 'parking sensor', 'proximity sensor',
      'radar', 'adaptive cruise', 'acc',
      'alignment', 'wheel alignment', '4-wheel alignment',
      'suspension', 'strut', 'shock', 'spring',
      'airbag', 'air bag', 'srs',
      'steering', 'steering wheel', 'power steering',
      'headlight', 'headlamp', 'front light',
      'quarter panel', 'quarter', 'rear panel',
      'hood', 'bonnet', 'grille', 'radiator support',
      'roof', 'roof panel', 'headliner',
      'door', 'front door', 'rear door',
      'collision', 'impact', 'damage',
      'replace', 'replacement', 'repair',
      'front-end', 'rear-end',
    ];
    
    for (var keyword in repairKeywords) {
      if (lowerText.contains(keyword)) {
        keywords.add(keyword);
      }
    }
    
    return keywords.toSet().toList();
  }

  /// Database-driven analysis comparing estimate with calibration system triggers
  Set<String> _databaseDrivenAnalysis(
    String estimateText,
    List<String> estimateKeywords,
    List<CalibrationSystem> allSystems,
  ) {
    final lowerText = estimateText.toLowerCase();
    final matchedSystems = <String>{};

    // For each system in the database, check if any of its triggers match the estimate
    for (var system in allSystems) {
      bool systemMatches = false;
      
      // Check if any of the system's triggers appear in the estimate
      for (var trigger in system.requiredFor) {
        final lowerTrigger = trigger.toLowerCase();
        
        // Direct text match
        if (lowerText.contains(lowerTrigger)) {
          systemMatches = true;
          break;
        }
        
        // Keyword-based match
        for (var keyword in estimateKeywords) {
          if (lowerTrigger.contains(keyword) || keyword.contains(lowerTrigger)) {
            systemMatches = true;
            break;
          }
        }
        
        if (systemMatches) break;
      }
      
      if (systemMatches) {
        matchedSystems.add(system.id);
      }
    }

    return matchedSystems;
  }

  Future<String> answerQuestion(
    String question,
    List<CalibrationSystem> allSystems,
  ) async {
    final systemsContext = allSystems.map((s) {
      return '''
System: ${s.name}
Category: ${s.category}
Description: ${s.description}
Required For: ${s.requiredFor.join(", ")}
Time: ${s.estimatedTime}
Cost: ${s.estimatedCost}
Equipment: ${s.equipmentNeeded.join(", ")}
''';
    }).join('\n---\n');

    final prompt = '''You are an expert ADAS calibration assistant with access to a comprehensive calibration database. Answer questions intelligently based on context.

CONTEXT-AWARE RESPONSE RULES:
1. VEHICLE-SPECIFIC QUESTIONS: If user mentions a specific vehicle, year, make, model, or VIN, reference the database systems that apply to that vehicle type
2. IMPACT AREA QUESTIONS: If user asks about specific damage areas (front, rear, side, etc.), identify relevant calibration systems from the database
3. PRE-QUALIFICATION QUESTIONS: If user asks about pre-qualifications, requirements, or prerequisites, provide specific information from the database
4. GENERAL QUESTIONS: For casual conversation, respond naturally without overwhelming with technical details
5. TECHNICAL QUESTIONS: When asked about specific repairs, parts, or systems, provide detailed database information

DATABASE CONTEXT (use when relevant):
$systemsContext

RESPONSE GUIDELINES:
- Be conversational and helpful
- Reference specific systems from the database when discussing vehicles, impact areas, or pre-qualifications
- Provide practical, actionable information
- If discussing a specific vehicle or repair scenario, mention the relevant calibration systems
- Keep responses focused and relevant to the question

Question: $question

Provide a helpful, context-aware response based on the question and available database information.
''';

    try {
      return await _generateCompletion(prompt);
    } catch (e) {
      return 'I apologize, but I\'m having trouble connecting to the AI service. Please ensure Ollama is running on your system. Error: ${e.toString()}';
    }
  }

  Future<String> _generateCompletion(String prompt) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/generate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'model': model,
        'prompt': prompt,
        'stream': false,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['response'] as String;
    } else {
      throw Exception('Failed to generate completion: ${response.statusCode}');
    }
  }

  List<String> _fallbackAnalysis(
    String estimateText,
    List<CalibrationSystem> allSystems,
  ) {
    final lowerText = estimateText.toLowerCase();
    final requiredSystems = <String>[];

    for (var system in allSystems) {
      for (var keyword in system.requiredFor) {
        if (lowerText.contains(keyword.toLowerCase())) {
          requiredSystems.add(system.id);
          break;
        }
      }
    }

    return requiredSystems;
  }
}

