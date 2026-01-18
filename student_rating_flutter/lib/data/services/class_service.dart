import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/class_info.dart';

class ClassService {
  ClassService(this._client);

  final SupabaseClient _client;

  Future<ClassInfo?> fetchClassInfo(String classId) async {
    final classRow = await _client
        .from('class')
        .select('class_id, class_name, wali_user_id')
        .eq('class_id', classId)
        .maybeSingle();
    if (classRow == null) return null;

    String? waliName;
    final waliUserId = classRow['wali_user_id'] as String?;
    if (waliUserId != null && waliUserId.isNotEmpty) {
      final waliRow = await _client
          .from('profiles')
          .select('full_name')
          .eq('user_id', waliUserId)
          .maybeSingle();
      waliName = waliRow?['full_name'] as String?;
    }

    return ClassInfo(
      id: classRow['class_id'] as String,
      name: classRow['class_name'] as String?,
      waliUserId: waliUserId,
      waliName: waliName,
    );
  }
}
