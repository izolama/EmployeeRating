import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/criteria.dart';
import '../../data/models/ranking.dart';
import '../../data/services/criteria_service.dart';
import '../../data/services/student_service.dart';
import '../../data/services/rating_service.dart';
import '../../logic/profile_matching.dart';
import '../widgets/app_shimmer.dart';
import '../widgets/app_surface.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => RankingScreenState();
}

class RankingScreenState extends State<RankingScreen> {
  bool _loading = true;
  String? _error;
  List<Ranking> _rankings = [];

  late final CriteriaService _criteriaService;
  late final RatingService _ratingService;

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _criteriaService = CriteriaService(client);
    _ratingService = RatingService(client, StudentService(client));
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final criteria = await _criteriaService.fetchCriteria();
      final ratings = await _ratingService.fetchRatingsWithStudents();
      final calculator = ProfileMatchingCalculator();
      final rankingList = calculator.calculate(
        criteria: criteria,
        ratings: ratings,
      );
      setState(() {
        _rankings = rankingList;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> reload() => _load();

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _RankingSkeleton();
    if (_error != null) return Center(child: Text('Error: $_error'));
    if (_rankings.isEmpty) {
      return const Center(child: Text('Belum ada data ranking.'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 120),
        itemCount: _rankings.length,
        itemBuilder: (context, index) {
          final rank = _rankings[index];
          final colorScheme = Theme.of(context).colorScheme;
          return AppCard(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: CircleAvatar(
                backgroundColor: colorScheme.primary.withOpacity(0.12),
                child: Text('${index + 1}'),
              ),
              title: Text(rank.studentName),
              subtitle: Text('Total: ${rank.totalScore.toStringAsFixed(3)}'),
              trailing: FittedBox(
                alignment: Alignment.centerRight,
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('K1 ${rank.k1.toStringAsFixed(1)}'),
                    Text('K2 ${rank.k2.toStringAsFixed(1)}'),
                    Text('K3 ${rank.k3.toStringAsFixed(1)}'),
                    Text('K4 ${rank.k4.toStringAsFixed(1)}'),
                    Text('K5 ${rank.k5.toStringAsFixed(1)}'),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RankingSkeleton extends StatelessWidget {
  const _RankingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 120),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppShimmer(
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0x33E7E7FF),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 10,
                          width: 160,
                          decoration: BoxDecoration(
                            color: const Color(0x2FF4F4FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 10,
                        width: 48,
                        decoration: BoxDecoration(
                          color: const Color(0x30FFFFFF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 10,
                        width: 48,
                        decoration: BoxDecoration(
                          color: const Color(0x24FFFFFF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
