import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/services/auth_service.dart';
import '../widgets/app_surface.dart';
import 'login_screen.dart';
import 'criteria_screen.dart';
import 'students_screen.dart';
import 'rating_screen.dart';
import 'ranking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _signingOut = false;

  final GlobalKey<StudentsScreenState> _studentsKey =
      GlobalKey<StudentsScreenState>();
  final GlobalKey<CriteriaScreenState> _criteriaKey =
      GlobalKey<CriteriaScreenState>();
  final GlobalKey<RatingScreenState> _ratingKey =
      GlobalKey<RatingScreenState>();
  final GlobalKey<RankingScreenState> _rankingKey =
      GlobalKey<RankingScreenState>();

  late final List<Widget> _pages = [
    StudentsScreen(key: _studentsKey),
    CriteriaScreen(key: _criteriaKey),
    RatingScreen(key: _ratingKey),
    RankingScreen(key: _rankingKey),
    _SettingsPage(onLogout: _signOut),
  ];

  final _titles = const [
    'Siswa',
    'Kriteria',
    'Penilaian',
    'Ranking',
    'Pengaturan',
  ];

  AuthService get _auth => AuthService(Supabase.instance.client);

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: NavigationBar(
            height: 76,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shadowColor: Colors.black.withOpacity(0.08),
            indicatorColor: colorScheme.primary.withOpacity(0.14),
            selectedIndex: _currentIndex,
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
            onDestinationSelected: (value) {
              setState(() => _currentIndex = value);
              switch (value) {
                case 0:
                  _studentsKey.currentState?.reload();
                  break;
                case 1:
                  _criteriaKey.currentState?.reload();
                  break;
                case 2:
                  _ratingKey.currentState?.reload();
                  break;
                case 3:
                  _rankingKey.currentState?.reload();
                  break;
              }
            },
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Siswa'),
              NavigationDestination(
                  icon: Icon(Icons.list_alt_outlined),
                  selectedIcon: Icon(Icons.list_alt),
                  label: 'Kriteria'),
              NavigationDestination(
                  icon: Icon(Icons.assignment_outlined),
                  selectedIcon: Icon(Icons.assignment),
                  label: 'Penilaian'),
              NavigationDestination(
                  icon: Icon(Icons.emoji_events_outlined),
                  selectedIcon: Icon(Icons.emoji_events),
                  label: 'Ranking'),
              NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: 'Setting'),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: _signingOut
                  ? null
                  : () => _studentsKey.currentState?.showAddDialog(),
              child: const Icon(Icons.add),
            )
          : null,
      body: Stack(
        children: [
          AppBackground(
            safeBottom: true,
            padding: _currentIndex == 0
                ? EdgeInsets.zero
                : const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: _pages,
                  ),
                ),
              ],
            ),
          ),
          if (_signingOut)
            Container(
              color: Colors.black.withOpacity(0.1),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

class _SettingsPage extends StatelessWidget {
  final Future<void> Function() onLogout;

  const _SettingsPage({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 24),
      children: [
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primary.withOpacity(0.12),
                child: Icon(Icons.settings, color: colorScheme.primary),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Pengaturan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Keluar'),
            subtitle: const Text('Kembali ke halaman login'),
            onTap: () => onLogout(),
          ),
        ),
      ],
    );
  }
}
