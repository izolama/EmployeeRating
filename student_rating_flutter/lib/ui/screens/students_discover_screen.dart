import 'package:flutter/material.dart';

import '../../data/models/student.dart';
import '../widgets/app_shimmer.dart';
import '../widgets/app_surface.dart';

class StudentsDiscoverScreen extends StatelessWidget {
  final List<Student> students;
  final VoidCallback onAdd;

  const StudentsDiscoverScreen({
    super.key,
    required this.students,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        safeTop: true,
        safeBottom: true,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                Text(
                  'Discover',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white.withOpacity(0.14),
                  child: const Icon(Icons.person, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SearchBar(),
            const SizedBox(height: 18),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.94),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 22,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: DefaultTabController(
                  length: 4,
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      _CapsuleTabBar(),
                      const SizedBox(height: 10),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _StudentsList(students: students),
                            _StudentsList(students: students),
                            _StudentsList(students: students),
                            _StudentsList(students: students),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        onPressed: onAdd,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.08),
        border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.2),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Cari siswa...',
              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 16),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('Top', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _CapsuleTabBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const color = Colors.black;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(22),
      ),
      child: TabBar(
        labelColor: color,
        unselectedLabelColor: Colors.grey[600],
        indicator: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        tabs: const [
          Tab(text: 'Top'),
          Tab(text: 'Kelas'),
          Tab(text: 'Kontak'),
          Tab(text: 'Alamat'),
        ],
      ),
    );
  }
}

class _StudentsList extends StatelessWidget {
  final List<Student> students;

  const _StudentsList({required this.students});

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) {
      return const Center(
          child: Text('Belum ada siswa',
              style: TextStyle(color: Colors.black87)));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 8, 12),
          child: Row(
            children: [
              Text('Siswa',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800, color: Colors.black)),
              const Spacer(),
              Text('${students.length} total',
                  style:
                      Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
            ],
          ),
        ),
        ...students.map((s) => _DiscoverStudentTile(student: s)).toList(),
      ],
    );
  }
}

class _DiscoverStudentTile extends StatelessWidget {
  final Student student;

  const _DiscoverStudentTile({required this.student});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: Colors.black.withOpacity(0.05), width: 1.2),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFEAEAEA),
              child: Text(student.name.isNotEmpty ? student.name[0] : '?',
                  style:
                      const TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Colors.black,
                      )),
                  const SizedBox(height: 4),
                  Text(
                    _subtitleText(student),
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black54),
          ],
        ),
      ),
    );
  }

  String _subtitleText(Student s) {
    final kelas = s.className?.isNotEmpty == true ? s.className! : 'Kelas -';
    final phone = s.phone.isNotEmpty ? s.phone : 'No phone';
    return '$kelas • $phone';
  }
}
