// Dart model mirroring a row in `public.health_records`.
// See the `create_health_records` migration for the canonical column list.

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum HealthRecordType { visit, lab, symptomLog }

enum HealthRecordStatus { none, flagged, missingResult }

// ---------------------------------------------------------------------------
// Enum helpers — DB ↔ Dart conversion
// ---------------------------------------------------------------------------

HealthRecordType healthRecordTypeFromDb(String s) => switch (s) {
      'lab' => HealthRecordType.lab,
      'symptom_log' => HealthRecordType.symptomLog,
      _ => HealthRecordType.visit,
    };

HealthRecordStatus healthRecordStatusFromDb(String s) => switch (s) {
      'flagged' => HealthRecordStatus.flagged,
      'missing_result' => HealthRecordStatus.missingResult,
      _ => HealthRecordStatus.none,
    };

extension HealthRecordTypeX on HealthRecordType {
  String get toDb => switch (this) {
        HealthRecordType.visit => 'visit',
        HealthRecordType.lab => 'lab',
        HealthRecordType.symptomLog => 'symptom_log',
      };
}

extension HealthRecordStatusX on HealthRecordStatus {
  String get toDb => switch (this) {
        HealthRecordStatus.none => 'none',
        HealthRecordStatus.flagged => 'flagged',
        HealthRecordStatus.missingResult => 'missing_result',
      };
}

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

class HealthRecordModel {
  const HealthRecordModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.recordDate,
    required this.title,
    this.notes,
    required this.status,
    this.aiSuggestion,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final HealthRecordType type;
  final DateTime recordDate;
  final String title;
  final String? notes;
  final HealthRecordStatus status;
  final String? aiSuggestion;
  final DateTime createdAt;

  /// True when the record was created within the last 7 days.
  bool get isRecent => DateTime.now().difference(createdAt).inDays <= 7;

  /// Formatted date for timeline display, e.g. "NOV 14, 2025".
  String get formattedDate {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    return '${months[recordDate.month - 1]} ${recordDate.day}, ${recordDate.year}';
  }

  factory HealthRecordModel.fromJson(Map<String, dynamic> json) {
    return HealthRecordModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: healthRecordTypeFromDb(json['type'] as String),
      recordDate: DateTime.parse(json['record_date'] as String),
      title: json['title'] as String,
      notes: json['notes'] as String?,
      status: healthRecordStatusFromDb(json['status'] as String? ?? 'none'),
      aiSuggestion: json['ai_suggestion'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
