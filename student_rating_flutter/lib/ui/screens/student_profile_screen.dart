import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/student.dart';
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
  bool _loading = true;
  Student? _student;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = StudentService(Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final studentId = widget.studentId?.trim();
      if (studentId != null && studentId.isNotEmpty) {
        final byId = await _service.fetchStudentById(studentId);
        setState(() => _student = byId);
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
      setState(() => _student = match.isNotEmpty ? match.first : null);
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
                  : _ProfileCard(student: _student!),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Profil siswa belum ditemukan.\nHubungi admin untuk sinkronisasi.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final Student student;

  const _ProfileCard({required this.student});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.black.withOpacity(0.06)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.black.withOpacity(0.06),
                  child: Text(
                    student.name.isNotEmpty ? student.name[0] : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  student.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  student.className.isNotEmpty ? student.className : '-',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
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

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
