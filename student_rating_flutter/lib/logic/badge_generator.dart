import '../data/models/badge.dart';
import '../data/models/ranking.dart';

class BadgeGenerator {
  List<StudentBadge> generate({
    required Ranking ranking,
    required int globalRank,
    required int totalStudents,
    required String studentId,
  }) {
    final badges = <StudentBadge>[];
    final now = DateTime.now();

    void add(String code, String level) {
      final id = '$studentId-$code-$level';
      badges.add(StudentBadge(
        id: id,
        studentId: studentId,
        code: code,
        level: level,
        computedAt: now,
      ));
    }

    // Overall score tiers.
    final score = ranking.totalScore;
    if (score >= 0.8) {
      add('overall', 'elite');
    } else if (score >= 0.6) {
      add('overall', 'pro');
    } else if (score >= 0.4) {
      add('overall', 'rising');
    }

    // Global rank tiers.
    if (globalRank == 1) add('rank', 'champion');
    if (globalRank <= 3) add('rank', 'top3');
    final percentile = globalRank / (totalStudents == 0 ? 1 : totalStudents);
    if (percentile <= 0.1) add('rank', 'top10pct');

    // Per-criteria tiers.
    final crits = [ranking.k1, ranking.k2, ranking.k3, ranking.k4, ranking.k5];
    for (var i = 0; i < crits.length; i++) {
      final v = crits[i];
      if (v <= 0) continue;
      String? level;
      if (v >= 0.8) {
        level = 'gold';
      } else if (v >= 0.6) {
        level = 'silver';
      } else if (v >= 0.4) {
        level = 'bronze';
      }
      if (level != null) {
        add('crit_${i + 1}', level);
      }
    }

    return badges;
  }
}
