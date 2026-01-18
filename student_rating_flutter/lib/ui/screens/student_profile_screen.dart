import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/student.dart';
import '../../data/models/class_info.dart';
import '../../data/services/class_service.dart';
import '../../data/services/student_service.dart';
import '../widgets/app_surface.dart';

class StudentProfileScreen extends StatefulWidget {
  final String profileName;
  final String? classId;
  final String? studentId;

  const StudentProfileScreen({
    super.key,
    required this.profileName,
    required this.classId,
    required this.studentId,
  });

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  late final StudentService _service;
  late final ClassService _classService;
  bool _loading = true;
  Student? _student;
  ClassInfo? _classInfo;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = StudentService(Supabase.instance.client);
    _classService = ClassService(Supabase.instance.client);
    _load();
  }

  Future<void> _loadClassInfo(Student? student) async {
    if (student == null) return;
    final directId = student.classId?.trim() ?? '';
    final fallbackId = student.className.trim();
    final classId = directId.isNotEmpty ? directId : fallbackId;
    if (classId.isEmpty) return;
    final info = await _classService.fetchClassInfo(classId);
    if (!mounted) return;
    setState(() => _classInfo = info);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _classInfo = null;
    });
    try {
      final studentId = widget.studentId?.trim();
      if (studentId != null && studentId.isNotEmpty) {
        final byId = await _service.fetchStudentById(studentId);
        if (!mounted) return;
        setState(() => _student = byId);
        await _loadClassInfo(byId);
        return;
      }
      final students = await _service.fetchStudents();
      final classId = widget.classId?.trim().toLowerCase();
      final name = widget.profileName.trim().toLowerCase();
      final match = students.where((s) {
        final sameClass = classId == null || classId.isEmpty
            ? true
            : s.className.trim().toLowerCase() == classId;
        final sameName = s.name.trim().toLowerCase() == name;
        return sameClass && sameName;
      }).toList();
      if (!mounted) return;
      final student = match.isNotEmpty ? match.first : null;
      setState(() => _student = student);
      await _loadClassInfo(student);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      safeTop: true,
      safeBottom: true,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _student == null
                  ? _EmptyProfile(name: widget.profileName)
                  : _ProfileCard(
                      student: _student!,
                      classInfo: _classInfo,
                    ),
    );
  }
}

class _EmptyProfile extends StatelessWidget {
  final String name;

  const _EmptyProfile({required this.name});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F7),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Profil siswa belum ditemukan.\nHubungi admin untuk sinkronisasi.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF8E8E93)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final Student student;
  final ClassInfo? classInfo;

  const _ProfileCard({required this.student, required this.classInfo});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F7),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.black.withOpacity(0.06)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 12),
                  )
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFFE5E5EA),
                    child: Text(
                      student.name.isNotEmpty ? student.name[0] : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1C1C1E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          student.className.isNotEmpty
                              ? student.className
                              : '-',
                          style: const TextStyle(
                            color: Color(0xFF8E8E93),
                            fontSize: 13,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _InfoTile(
            label: 'ID Siswa',
            value: student.id,
          ),
          const SizedBox(height: 10),
          _InfoTile(
            label: 'Wali Kelas',
            value: (classInfo?.waliName?.trim().isNotEmpty == true)
                ? classInfo!.waliName!.trim()
                : '-',
          ),
          const SizedBox(height: 10),
          _InfoTile(
            label: 'Alamat',
            value: student.address.isNotEmpty ? student.address : '-',
          ),
          const SizedBox(height: 10),
          _InfoTile(
            label: 'Telepon',
            value: student.phone.isNotEmpty ? student.phone : '-',
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  static const double _valueRightInset = 12;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8E8E93),
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(right: _valueRightInset),
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF1C1C1E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
