import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/student.dart';

class StudentService {
  StudentService(this._client);

  final SupabaseClient _client;

  Future<List<Student>> fetchStudents() async {
    final response = await _client.from('student').select().order('student_id');
    return (response as List<dynamic>)
        .map((e) => Student.fromMap(e as Map<String, dynamic>))
        .toList();
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
      address: address,
      phone: phone,
    );
    await upsertStudent(student);
    return student;
  }
}
