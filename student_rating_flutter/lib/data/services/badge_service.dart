import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/badge.dart';

class BadgeService {
  final SupabaseClient _client;

  BadgeService(this._client);

  Future<List<StudentBadge>> fetchByStudent(String studentId) async {
    final rows = await _client
        .from('student_badges')
        .select()
        .eq('student_id', studentId)
        .order('computed_at', ascending: false);
    return rows
        .map<StudentBadge>(
            (row) => StudentBadge.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> upsertBadges(
      String studentId, List<StudentBadge> badges) async {
    final payload = badges.map((b) => b.toMap()).toList();
    await _client.from('student_badges').upsert(payload);
  }
}
