import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/student.dart';
import '../../data/services/student_service.dart';
import '../widgets/app_shimmer.dart';
import '../widgets/app_surface.dart';
import 'students_discover_screen.dart';

const _deepPurple = Color(0xFF5B4CFF);
const _midPurple = Color(0xFF7665FF);
const _pinkAccent = Color(0xFFFF8FB1);
const _pinkLight = Color(0xFFFFCCD5);
const _pinkMid = Color(0xFFFFB3C0);
const _pinkDark = Color(0xFF660012);

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => StudentsScreenState();
}

class StudentsScreenState extends State<StudentsScreen> {
  late final StudentService _service;
  late Future<List<Student>> _future;
  bool _isLoading = true;
  late final String _displayName;

  @override
  void initState() {
    super.initState();
    _service = StudentService(Supabase.instance.client);
    _displayName = _resolveName();
    _loadStudents();
  }

  String _greetingText() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'GOOD MORNING';
    if (hour >= 12 && hour < 17) return 'GOOD AFTERNOON';
    if (hour >= 17 && hour < 21) return 'GOOD EVENING';
    return 'GOOD NIGHT';
  }

  String _resolveName() {
    final user = Supabase.instance.client.auth.currentUser;
    final metaName = user?.userMetadata?['name'];
    if (metaName is String && metaName.trim().isNotEmpty) return metaName;
    final email = user?.email;
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }
    return 'Sahabat';
  }

  Future<void> reload() => _loadStudents();

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _future = _service.fetchStudents();
    });
    try {
      await _future;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    await _loadStudents();
  }

  Future<void> showAddDialog() async {
    final nameCtrl = TextEditingController();
    final classCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            top: 16,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Tambah Siswa',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Nama wajib diisi' : null,
                ),
                TextFormField(
                  controller: classCtrl,
                  decoration: const InputDecoration(labelText: 'Kelas'),
                ),
                TextFormField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(labelText: 'Alamat'),
                ),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Telepon'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    await _service.createStudent(
                      name: nameCtrl.text.trim(),
                      className: classCtrl.text.trim(),
                      address: addressCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                    );
                    if (context.mounted) Navigator.pop(context, true);
                  },
                  child: const Text('Simpan'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (saved == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<Student>>(
        future: _future,
        builder: (context, snapshot) {
          final isLoading = _isLoading ||
              snapshot.connectionState == ConnectionState.waiting ||
              snapshot.connectionState == ConnectionState.active;
          if (isLoading) return const _StudentsSkeleton();
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final students = snapshot.data ?? [];
          final bottomSpacer = MediaQuery.of(context).padding.bottom + 140;
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
                child: _GreetingHero(
                  name: _displayName,
                  greeting: _greetingText(),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _HeaderSection(
                    totalStudents: students.length, onAdd: showAddDialog),
              ),
              const SizedBox(height: 14),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _FeatureCard(onAdd: showAddDialog),
              ),
              const SizedBox(height: 18),
              _LiveStudentsSection(
                students: students,
                onSeeAll: () => _openDiscover(context, students),
                bottomPadding: 0,
              ),
              Container(
                height: bottomSpacer,
                color: Colors.white,
              ),
            ],
          );
        },
      ),
    );
  }

  void _openDiscover(BuildContext context, List<Student> students) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudentsDiscoverScreen(
          students: students,
          onAdd: showAddDialog,
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class _GreetingHero extends StatelessWidget {
  final String name;
  final String greeting;

  const _GreetingHero({required this.name, required this.greeting});

  String _avatarForName(String value) {
    final trimmed = value.trim().toLowerCase();
    if (trimmed.isEmpty) return 'assets/ic_avatar.png';
    final first = trimmed.split(' ').first;
    // Simple heuristic: only treat names ending with 'a' as female, otherwise default to male.
    final endsWithA = first.endsWith('a');
    return endsWithA ? 'assets/ic_avatar_2.png' : 'assets/ic_avatar.png';
  }

  @override
  Widget build(BuildContext context) {
    final avatar = _avatarForName(name);
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.wb_sunny_outlined,
                    color: Color(0xFFF7C8D5), size: 18),
                const SizedBox(width: 8),
                Text(
                  greeting,
                  style: const TextStyle(
                    color: Color(0xFFF7C8D5),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
        const Spacer(),
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.white.withOpacity(0.18),
          backgroundImage: AssetImage(avatar),
          child: Container(),
        ),
      ],
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final int totalStudents;
  final VoidCallback onAdd;

  const _HeaderSection({required this.totalStudents, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(6, 10, 6, 0),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_pinkLight, _pinkMid],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _WavePainter(),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selamat datang',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: _pinkDark.withOpacity(0.8),
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Student Rating',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: _pinkDark,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Icon(Icons.school, color: _pinkDark),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _StatPill(
                    label: 'Total siswa',
                    value: '$totalStudents',
                    icon: Icons.people_alt_rounded,
                  ),
                  const SizedBox(width: 10),
                  // FilledButton(
                  //   style: FilledButton.styleFrom(
                  //     backgroundColor: Colors.white,
                  //     foregroundColor: _pinkDark,
                  //     padding: const EdgeInsets.symmetric(
                  //         horizontal: 16, vertical: 10),
                  //     shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(14)),
                  //   ),
                  //   onPressed: onAdd,
                  //   child: const Row(
                  //     mainAxisSize: MainAxisSize.min,
                  //     children: [
                  //       Icon(Icons.add),
                  //       SizedBox(width: 6),
                  //       Text('Tambah'),
                  //     ],
                  //   ),
                  // ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatPill({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.black, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.black.withOpacity(0.8),
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final String title;
  final Student student;
  final VoidCallback onAdd;

  const _HighlightCard({
    required this.title,
    required this.student,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: _pinkAccent.withOpacity(0.14),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.grey[700],
                      letterSpacing: 0.1,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                student.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _deepPurple,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                student.className ?? '-',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Chip(
                    label: Text(
                        student.phone.isEmpty ? 'No phone' : student.phone),
                    avatar: const Icon(Icons.phone, size: 16),
                    backgroundColor: _pinkAccent.withOpacity(0.12),
                    labelStyle: const TextStyle(color: Colors.black87),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: onAdd,
                    child: const Text('Tambah lagi'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyCard({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Belum ada siswa',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Tambahkan siswa pertama untuk memulai penilaian.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: onAdd,
            child: const Text('Tambah siswa'),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final VoidCallback onAdd;

  const _FeatureCard({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF7B6CF8),
                Color(0xFF6E60F0),
                Color(0xFF6153E6),
              ],
              stops: [0, 0.55, 1],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: CustomPaint(
            painter: _FeatureCirclePainter(),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white
                    .withOpacity(0.3), // translucent wash closer to design
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Visibility(
                          visible: false,
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.white.withOpacity(0.18),
                            child:
                                const Icon(Icons.person, color: Colors.white),
                          ),
                        ),
                        const Spacer(),
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white.withOpacity(0.18),
                          child:
                              const Icon(Icons.person_add, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'FEATURED',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white.withOpacity(0.92),
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Tambah siswa dan lakukan penilaian untuk melihat ranking terbaik.',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontSize: 18,
                        height: 1.35,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF4A38C8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                      ),
                      onPressed: onAdd,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.group_add),
                          SizedBox(width: 8),
                          Text('Tambah Siswa'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveStudentsSection extends StatelessWidget {
  final List<Student> students;
  final VoidCallback onSeeAll;
  final double bottomPadding;

  const _LiveStudentsSection({
    required this.students,
    required this.onSeeAll,
    required this.bottomPadding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final take = students.take(3).toList();
    return Container(
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(34),
          topRight: Radius.circular(34),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(34, 20, 24, 10),
            child: Row(
              children: [
                Text(
                  'Live Siswa',
                  style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800, color: Colors.black87),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onSeeAll,
                  child: Text(
                    'Lihat semua',
                    style: TextStyle(
                      color: _deepPurple,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...take.map((s) => Padding(
                padding: const EdgeInsets.fromLTRB(30, 8, 30, 8),
                child: _LiveStudentCard(student: s),
              )),
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }
}

class _LiveStudentCard extends StatelessWidget {
  final Student student;

  const _LiveStudentCard({required this.student});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF7F7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6E6FF), width: 1.6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 6),
          )
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD9D4FF), Color(0xFFB3A7FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                student.name.isNotEmpty ? student.name[0] : '?',
                style: const TextStyle(
                  color: Color(0xFF1B1530),
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
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
                    fontWeight: FontWeight.w800,
                    fontSize: 16.5,
                    color: Color(0xFF0F0F3E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _subtitle(student),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF5B4CFF)),
        ],
      ),
    );
  }

  String _subtitle(Student s) {
    final kelas = s.className?.isNotEmpty == true ? s.className! : 'Kelas -';
    final phone = s.phone.isNotEmpty ? s.phone : 'No phone';
    return '$kelas • $phone';
  }
}

class _StudentsSkeleton extends StatelessWidget {
  const _StudentsSkeleton();

  @override
  Widget build(BuildContext context) {
    final bottomSpacer = MediaQuery.of(context).padding.bottom + 140;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 25, vertical: 8),
          child: _ShimmerGreeting(),
        ),
        const SizedBox(height: 10),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ShimmerBlock(height: 190, radius: 26, margin: EdgeInsets.zero),
        ),
        const SizedBox(height: 14),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ShimmerBlock(height: 230, radius: 28, margin: EdgeInsets.zero),
        ),
        const SizedBox(height: 18),
        const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child:
                ShimmerBlock(height: 18, radius: 6, margin: EdgeInsets.zero)),
        const SizedBox(height: 12),
        ...List.generate(
          3,
          (_) => const Padding(
            padding: EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: _ShimmerLiveCard(),
          ),
        ),
        Container(
          height: bottomSpacer,
          color: Colors.white,
        ),
      ],
    );
  }
}

class _ShimmerGreeting extends StatelessWidget {
  const _ShimmerGreeting();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 12,
                  width: 140,
                  decoration: BoxDecoration(
                    color: const Color(0x33E7E7FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 18,
                  width: 200,
                  decoration: BoxDecoration(
                    color: const Color(0x33E7E7FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0x35F4F4FF),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerListItem extends StatelessWidget {
  const _ShimmerListItem();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Container(
        height: 82,
        decoration: BoxDecoration(
          color: const Color(0x33E7E7FF),
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x35F4F4FF),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0x35F4F4FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 10,
                    width: 140,
                    decoration: BoxDecoration(
                      color: const Color(0x2FF4F4FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x2AF4F4FF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerLiveCard extends StatelessWidget {
  const _ShimmerLiveCard();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          color: const Color(0x33E7E7FF),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE7E7FF)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0x35F4F4FF),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0x35F4F4FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 10,
                    width: 120,
                    decoration: BoxDecoration(
                      color: const Color(0x2FF4F4FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: const Color(0x24FFFFFF),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = Colors.white.withOpacity(0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final subtleStroke = Paint()
      ..color = Colors.white.withOpacity(0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    canvas.drawCircle(
        Offset(size.width * 0.82, size.height * 0.22), 110, stroke);
    canvas.drawCircle(
        Offset(size.width * 0.86, size.height * 0.18), 72, subtleStroke);
    canvas.drawCircle(
        Offset(size.width * 0.12, size.height * 0.78), 118, stroke);
    canvas.drawCircle(
        Offset(size.width * 0.18, size.height * 0.82), 74, subtleStroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = Colors.white.withOpacity(0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;

    final path1 = Path()
      ..moveTo(-20, size.height * 0.65)
      ..quadraticBezierTo(
        size.width * 0.2,
        size.height * 0.45,
        size.width * 0.5,
        size.height * 0.7,
      )
      ..quadraticBezierTo(
        size.width * 0.8,
        size.height * 0.9,
        size.width + 20,
        size.height * 0.65,
      );
    canvas.drawPath(path1, paint1);

    final paint2 = Paint()
      ..color = Colors.white.withOpacity(0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path2 = Path()
      ..moveTo(-10, size.height * 0.55)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.35,
        size.width * 0.6,
        size.height * 0.6,
      )
      ..quadraticBezierTo(
        size.width * 0.85,
        size.height * 0.75,
        size.width + 10,
        size.height * 0.5,
      );
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
