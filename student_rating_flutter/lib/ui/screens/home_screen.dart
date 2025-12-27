import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/services/auth_service.dart';
import '../widgets/app_surface.dart';
import 'criteria_screen.dart';
import 'login_screen.dart';
import 'ranking_screen.dart';
import 'rating_screen.dart';
import 'students_screen.dart';

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
  final _navController = NotchBottomBarController(index: 0);

  late final List<Widget> _pages = [
    StudentsScreen(key: _studentsKey),
    CriteriaScreen(key: _criteriaKey),
    RatingScreen(key: _ratingKey),
    RankingScreen(key: _rankingKey),
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
      backgroundColor: Colors.transparent,
      extendBody: true,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: null,
      bottomNavigationBar: AnimatedNotchBottomBar(
        notchBottomBarController: _navController,
        color: Colors.transparent,
        notchColor: Colors.transparent,
        kIconSize: 26,
        kBottomRadius: 22,
        showLabel: true,
        removeMargins: true,
        bottomBarHeight: 78,
        itemLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        bottomBarItems: [
          BottomBarItem(
            inActiveItem:
                Icon(Icons.home_outlined, color: Colors.grey.shade500),
            activeItem: Icon(Icons.home, color: colorScheme.primary),
            itemLabel: 'Siswa',
          ),
          BottomBarItem(
            inActiveItem:
                Icon(Icons.list_alt_outlined, color: Colors.grey.shade500),
            activeItem: Icon(Icons.list_alt, color: colorScheme.primary),
            itemLabel: 'Kriteria',
          ),
          BottomBarItem(
            inActiveItem:
                Icon(Icons.assignment_outlined, color: Colors.grey.shade500),
            activeItem: Icon(Icons.assignment, color: colorScheme.primary),
            itemLabel: 'Nilai',
          ),
          BottomBarItem(
            inActiveItem:
                Icon(Icons.emoji_events_outlined, color: Colors.grey.shade500),
            activeItem: Icon(Icons.emoji_events, color: colorScheme.primary),
            itemLabel: 'Ranking',
          ),
        ],
        onTap: (index) {
          _navController.index = index;
          _onNavTap(index);
        },
      ),
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

  void _onNavTap(int value) {
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
  }
}
