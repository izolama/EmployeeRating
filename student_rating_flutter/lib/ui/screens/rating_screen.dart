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
  final String? classId;

  const RatingScreen({super.key, this.classId});

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
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final criteria = await _criteriaService.fetchCriteria();
      final ratings = await _ratingService.fetchRatingsWithStudents();
      if (!mounted) return;
      var filtered = ratings;
      if (widget.classId != null && widget.classId!.trim().isNotEmpty) {
        final classId = widget.classId!.trim().toLowerCase();
        filtered = ratings
            .where((r) => r.student.className.trim().toLowerCase() == classId)
            .toList();
      }
      setState(() {
        _criteria = criteria;
        _ratings = filtered;
      });
    } catch (e) {
      if (!mounted) return;
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
    bool isSaving = false;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      barrierColor: Colors.black54,
      builder: (context) {
        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: StatefulBuilder(
            builder: (context, modalSetState) {
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
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
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
                            labelStyle: const TextStyle(color: Colors.white70),
                            helperStyle: const TextStyle(color: Colors.white54),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Colors.white38, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Colors.white, width: 1.2),
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 46,
                      width: 200,
                      child: isSaving
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.18)),
                                ),
                                alignment: Alignment.center,
                                child: const LinearProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                  backgroundColor: Colors.white24,
                                ),
                              ),
                            )
                          : FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor:
                                    Colors.white.withOpacity(0.14),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () async {
                                modalSetState(() => isSaving = true);
                                try {
                                  final newValue = RatingValue(
                                    k1: int.tryParse(controllers[0]?.text ?? '') ??
                                        0,
                                    k2: int.tryParse(controllers[1]?.text ?? '') ??
                                        0,
                                    k3: int.tryParse(controllers[2]?.text ?? '') ??
                                        0,
                                    k4: int.tryParse(controllers[3]?.text ?? '') ??
                                        0,
                                    k5: int.tryParse(controllers[4]?.text ?? '') ??
                                        0,
                                  );
                                  await _ratingService.upsertRating(
                                    ratingId: rating.ratingId,
                                    studentId: rating.student.id,
                                    value: newValue,
                                  );
                                  if (context.mounted) {
                                    Navigator.pop(context, true);
                                  }
                                } finally {
                                  if (mounted) {
                                    modalSetState(() => isSaving = false);
                                  }
                                }
                              },
                              child: const Text('Simpan'),
                            ),
                    ),
                  ],
                ),
              );
            },
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
            child: const Text(
              'Belum ada data siswa.',
              style: TextStyle(color: Colors.white),
            ),
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
              title: Text(
                rating.student.name,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                _criteria.asMap().entries.map((entry) {
                  final i = entry.key;
                  final c = entry.value;
                  return '${c.id}: ${_valueByIndex(rating.value, i)}';
                }).join(' | '),
                style: const TextStyle(color: Colors.white70),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.white70),
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
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.08),
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
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 10,
                          width: 180,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
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
                      color: Colors.white.withOpacity(0.08),
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
