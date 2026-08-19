import '../models/patient.dart';

/// Aggregates patients + reports into chart-ready data for the Analytics screen.
class AnalyticsService {
  /// Patient count per department.
  Map<String, int> byDepartment(List<Patient> patients) {
    final map = <String, int>{};
    for (final p in patients) {
      final key = p.department.isEmpty ? 'Unassigned' : p.department;
      map[key] = (map[key] ?? 0) + 1;
    }
    return map;
  }

  /// Patient count per age bucket.
  Map<String, int> byAgeGroup(List<Patient> patients) {
    final buckets = <String, int>{
      '0-17': 0,
      '18-39': 0,
      '40-59': 0,
      '60+': 0,
    };
    for (final p in patients) {
      if (p.age < 18) {
        buckets['0-17'] = buckets['0-17']! + 1;
      } else if (p.age < 40) {
        buckets['18-39'] = buckets['18-39']! + 1;
      } else if (p.age < 60) {
        buckets['40-59'] = buckets['40-59']! + 1;
      } else {
        buckets['60+'] = buckets['60+']! + 1;
      }
    }
    return buckets;
  }

  /// Patient count per gender.
  Map<String, int> byGender(List<Patient> patients) {
    final map = <String, int>{};
    for (final p in patients) {
      final key = p.gender.isEmpty ? 'Unknown' : p.gender;
      map[key] = (map[key] ?? 0) + 1;
    }
    return map;
  }

  /// Reports grouped by their AI risk level.
  Map<String, int> byRiskLevel(List<Map<String, dynamic>> reports) {
    final map = <String, int>{'Urgent': 0, 'High': 0, 'Medium': 0, 'Low': 0};
    for (final r in reports) {
      final analysis = r['aiAnalysis'];
      final level = analysis is Map ? analysis['riskLevel']?.toString() : null;
      final key = (level == null || !map.containsKey(level)) ? 'Low' : level;
      map[key] = (map[key] ?? 0) + 1;
    }
    return map;
  }

  /// Reports created per day over the last [days] days (oldest first).
  List<MapEntry<DateTime, int>> weeklyActivity(
    List<Map<String, dynamic>> reports, {
    int days = 7,
  }) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: days - 1));
    final counts = <DateTime, int>{
      for (var i = 0; i < days; i++) start.add(Duration(days: i)): 0,
    };

    for (final r in reports) {
      final created = _parseDate(r['createdAt']);
      if (created == null) continue;
      final day = DateTime(created.year, created.month, created.day);
      if (counts.containsKey(day)) counts[day] = counts[day]! + 1;
    }

    final entries = counts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    try {
      // Firestore Timestamp
      return (value as dynamic).toDate() as DateTime;
    } catch (_) {
      return null;
    }
  }
}
