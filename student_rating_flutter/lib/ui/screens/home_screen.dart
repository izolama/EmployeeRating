import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
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

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
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
  late final TabController _tabController;

  AuthService get _auth => AuthService(Supabase.instance.client);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: _currentIndex,
    )..addListener(() {
        if (!_tabController.indexIsChanging) {
          _onNavTap(_tabController.index);
        }
      });
  }

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
    const barSurface = Colors.black;
    final iconColor = Colors.white.withOpacity(0.95);
    final unselectedIcon = Colors.white70;
    const indicatorColor = Colors.transparent;
    final barRadius = BorderRadius.circular(28);
    final screenWidth = MediaQuery.of(context).size.width;
    final barWidth =
        (screenWidth - 140).clamp(220.0, screenWidth - 32); // compact pill
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: null,
      body: Stack(
        children: [
          BottomBar(
            fit: StackFit.expand,
            width: barWidth,
            offset: 18,
            barColor: Colors.transparent,
            borderRadius: barRadius,
            barDecoration: BoxDecoration(
              color: barSurface,
              borderRadius: barRadius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 26,
                  offset: const Offset(0, 14),
                ),
              ],
              border: Border.all(color: Colors.white.withOpacity(0.12)),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.06),
                  Colors.white.withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            hideOnScroll: true,
            scrollOpposite: false,
            body: (context, controller) {
              return AppBackground(
                safeBottom: _currentIndex != 0,
                padding: _currentIndex == 0
                    ? EdgeInsets.zero
                    : const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  children: [
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          StudentsScreen(
                            key: _studentsKey,
                            scrollController: controller,
                          ),
                          CriteriaScreen(key: _criteriaKey),
                          RatingScreen(key: _ratingKey),
                          RankingScreen(key: _rankingKey),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            child: SafeArea(
              top: false,
              child: Material(
                color: Colors.transparent,
                borderRadius: barRadius,
                child: TabBar(
                  controller: _tabController,
                  onTap: _onNavTap,
                  isScrollable: true,
                  labelPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  indicatorPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  indicatorColor: indicatorColor,
                  indicator: const UnderlineTabIndicator(
                    borderSide: BorderSide(color: Colors.transparent, width: 0),
                    insets: EdgeInsets.zero,
                  ),
                  splashFactory: NoSplash.splashFactory,
                  overlayColor:
                      const MaterialStatePropertyAll(Colors.transparent),
                  dividerColor: Colors.transparent,
                  labelColor: iconColor,
                  unselectedLabelColor: unselectedIcon,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                  tabs: const [
                    Tab(icon: Icon(Icons.home, size: 20)),
                    Tab(icon: Icon(Icons.list_alt, size: 20)),
                    Tab(icon: Icon(Icons.assignment, size: 20)),
                    Tab(icon: Icon(Icons.emoji_events, size: 20)),
                  ],
                ),
              ),
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
    if (_tabController.index != value) {
      _tabController.animateTo(value);
    }
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
