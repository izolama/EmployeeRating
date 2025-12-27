import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/criteria.dart';
import '../../data/models/rating.dart';
import '../../data/models/rating_value.dart';
import '../../data/services/criteria_service.dart';
import '../../data/services/student_service.dart';
import '../../data/services/rating_service.dart';
import '../widgets/app_shimmer.dart';
import '../widgets/app_surface.dart';

class RatingScreen extends StatefulWidget {
  const RatingScreen({super.key});

  @override
  State<RatingScreen> createState() => RatingScreenState();
}

class RatingScreenState extends State<RatingScreen> {
  late final CriteriaService _criteriaService;
  late final RatingService _ratingService;
  bool _loading = true;
  List<Criteria> _criteria = [];
  List<Rating> _ratings = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _criteriaService = CriteriaService(client);
    _ratingService = RatingService(client, StudentService(client));
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final criteria = await _criteriaService.fetchCriteria();
      final ratings = await _ratingService.fetchRatingsWithStudents();
      setState(() {
        _criteria = criteria;
        _ratings = ratings;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> reload() => _fetchData();

  Future<void> _openRatingDialog(Rating rating) async {
    final controllers = <int, TextEditingController>{};
    for (var i = 0; i < _criteria.length; i++) {
      final value = _valueByIndex(rating.value, i);
      controllers[i] = TextEditingController(text: value.toString());
    }

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nilai - ${rating.student.name}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...List.generate(_criteria.length, (index) {
                final c = _criteria[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: TextField(
                    controller: controllers[index],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '${c.id} - ${c.name}',
                      helperText: 'Target ${c.amount} (${c.desc})',
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  final newValue = RatingValue(
                    k1: int.tryParse(controllers[0]?.text ?? '') ?? 0,
                    k2: int.tryParse(controllers[1]?.text ?? '') ?? 0,
                    k3: int.tryParse(controllers[2]?.text ?? '') ?? 0,
                    k4: int.tryParse(controllers[3]?.text ?? '') ?? 0,
                    k5: int.tryParse(controllers[4]?.text ?? '') ?? 0,
                  );
                  await _ratingService.upsertRating(
                    ratingId: rating.ratingId,
                    studentId: rating.student.id,
                    value: newValue,
                  );
                  if (context.mounted) Navigator.pop(context, true);
                },
                child: const Text('Simpan'),
              ),
            ],
          ),
        );
      },
    );

    if (saved == true) {
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _RatingSkeleton();
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }
    if (_ratings.isEmpty) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: AppCard(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            child: const Text('Belum ada data siswa.'),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
        itemCount: _ratings.length,
        itemBuilder: (context, index) {
          final rating = _ratings[index];
          return AppCard(
            margin: const EdgeInsets.only(bottom: 14),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              title: Text(rating.student.name),
              subtitle: Text(
                _criteria.asMap().entries.map((entry) {
                  final i = entry.key;
                  final c = entry.value;
                  return '${c.id}: ${_valueByIndex(rating.value, i)}';
                }).join(' | '),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _openRatingDialog(rating),
              ),
            ),
          );
        },
      ),
    );
  }

  int _valueByIndex(RatingValue value, int index) {
    switch (index) {
      case 0:
        return value.k1;
      case 1:
        return value.k2;
      case 2:
        return value.k3;
      case 3:
        return value.k4;
      case 4:
        return value.k5;
      default:
        return 0;
    }
  }
}

class _RatingSkeleton extends StatelessWidget {
  const _RatingSkeleton();

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
              height: 92,
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
                          width: 180,
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
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0x33FFFFFF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
