import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/student.dart';

class StudentService {
  StudentService(this._client);

  final SupabaseClient _client;

  Future<List<Student>> fetchStudents({String? classId}) async {
    var query = _client.from('student').select();
    if (classId != null && classId.trim().isNotEmpty) {
      query = query.eq('student_class', classId.trim());
    }
    final response = await query.order('student_id');
    return (response as List<dynamic>)
        .map((e) => Student.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<Student?> fetchStudentById(String studentId) async {
    final response =
        await _client.from('student').select().eq('student_id', studentId).maybeSingle();
    if (response == null) return null;
    return Student.fromMap(response as Map<String, dynamic>);
  }

  String _generateId() =>
      'S${DateTime.now().millisecondsSinceEpoch.toString().padLeft(13, '0')}';

  Future<void> upsertStudent(Student student) async {
    await _client.from('student').upsert(student.toMap());
  }

  Future<Student> createStudent({
    required String name,
    required String className,
    required String address,
    required String phone,
  }) async {
    final id = _generateId();
    final student = Student(
      id: id,
      name: name,
      className: className,
      classId: className,
      address: address,
      phone: phone,
    );
    await upsertStudent(student);
    return student;
  }
}
