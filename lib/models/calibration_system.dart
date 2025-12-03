class CalibrationSystem {
  final String id;
  final String name;
  final String description;
  final String category;
  final List<String> requiredFor;
  final String estimatedTime;
  final String estimatedCost;
  final List<String> equipmentNeeded;
  final String iconName;
  final int priority;
  final List<String> preQualifications;
  final String? hyperlink;
  final List<String> adasKeywords;

  CalibrationSystem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.requiredFor,
    required this.estimatedTime,
    required this.estimatedCost,
    required this.equipmentNeeded,
    required this.iconName,
    required this.priority,
    this.preQualifications = const [],
    this.hyperlink,
    this.adasKeywords = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'required_for': requiredFor.join(','),
      'estimated_time': estimatedTime,
      'estimated_cost': estimatedCost,
      'equipment_needed': equipmentNeeded.join(','),
      'icon_name': iconName,
      'priority': priority,
      'pre_qualifications': preQualifications.join(','),
      'hyperlink': hyperlink ?? '',
      'adas_keywords': adasKeywords.join(','),
    };
  }

  factory CalibrationSystem.fromMap(Map<String, dynamic> map) {
    final preQuals = map['pre_qualifications'] as String? ?? '';
    final adasKw = map['adas_keywords'] as String? ?? '';
    final link = map['hyperlink'] as String?;
    
    return CalibrationSystem(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      category: map['category'] as String,
      requiredFor: (map['required_for'] as String).split(','),
      estimatedTime: map['estimated_time'] as String,
      estimatedCost: map['estimated_cost'] as String,
      equipmentNeeded: (map['equipment_needed'] as String).split(','),
      iconName: map['icon_name'] as String,
      priority: map['priority'] as int,
      preQualifications: preQuals.isEmpty ? [] : preQuals.split(','),
      hyperlink: link?.isEmpty == true ? null : link,
      adasKeywords: adasKw.isEmpty ? [] : adasKw.split(','),
    );
  }
}

class CalibrationResult {
  final String id;
  final String systemId;
  final String systemName;
  final String reason;
  final bool required;
  final DateTime analyzedAt;

  CalibrationResult({
    required this.id,
    required this.systemId,
    required this.systemName,
    required this.reason,
    required this.required,
    required this.analyzedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'system_id': systemId,
      'system_name': systemName,
      'reason': reason,
      'required': required ? 1 : 0,
      'analyzed_at': analyzedAt.toIso8601String(),
    };
  }

  factory CalibrationResult.fromMap(Map<String, dynamic> map) {
    return CalibrationResult(
      id: map['id'] as String,
      systemId: map['system_id'] as String,
      systemName: map['system_name'] as String,
      reason: map['reason'] as String,
      required: (map['required'] as int) == 1,
      analyzedAt: DateTime.parse(map['analyzed_at'] as String),
    );
  }
}



