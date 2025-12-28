class StudentBadge {
  final String id;
  final String studentId;
  final String code;
  final String level;
  final DateTime computedAt;

  const StudentBadge({
    required this.id,
    required this.studentId,
    required this.code,
    required this.level,
    required this.computedAt,
  });

  factory StudentBadge.fromMap(Map<String, dynamic> map) => StudentBadge(
        id: map['id'] as String,
        studentId: map['student_id'] as String,
        code: map['badge_code'] as String,
        level: map['badge_level'] as String,
        computedAt: DateTime.parse(map['computed_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'student_id': studentId,
        'badge_code': code,
        'badge_level': level,
        'computed_at': computedAt.toIso8601String(),
      };
}
