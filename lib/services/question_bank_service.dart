import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/department_questions.dart';
import '../data/specialty_templates.dart';

/// Merges the built-in department question banks with developer-authored
/// questions stored in Firestore (`question_bank/{departmentId}`).
class QuestionBankService {
  QuestionBankService._();
  static final QuestionBankService instance = QuestionBankService._();

  final Map<String, List<TemplateQuestion>> _cache = {};

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('question_bank');

  List<TemplateQuestion> builtIn(String departmentId) =>
      DepartmentQuestions.forDepartment(departmentId);

  /// Built-in questions plus any custom ones, minus those hidden by a developer.
  Future<List<TemplateQuestion>> forDepartment(String departmentId) async {
    if (_cache.containsKey(departmentId)) return _cache[departmentId]!;
    final base = List<TemplateQuestion>.from(builtIn(departmentId));
    try {
      final doc = await _col.doc(departmentId).get();
      final data = doc.data();
      if (data != null) {
        final hidden = (data['hidden'] as List?)?.map((e) => e.toString()).toSet() ?? {};
        base.removeWhere((q) => hidden.contains(q.id));
        final custom = (data['questions'] as List?) ?? const [];
        for (final raw in custom) {
          if (raw is Map) base.add(_fromMap(Map<String, dynamic>.from(raw)));
        }
      }
    } catch (_) {
      // offline — built-in questions only
    }
    _cache[departmentId] = base;
    return base;
  }

  Future<List<TemplateQuestion>> customQuestions(String departmentId) async {
    final doc = await _col.doc(departmentId).get();
    final custom = (doc.data()?['questions'] as List?) ?? const [];
    return custom
        .whereType<Map>()
        .map((e) => _fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Set<String>> hiddenQuestions(String departmentId) async {
    final doc = await _col.doc(departmentId).get();
    return ((doc.data()?['hidden'] as List?) ?? const [])
        .map((e) => e.toString())
        .toSet();
  }

  Future<void> saveCustomQuestion(
    String departmentId,
    TemplateQuestion question,
  ) async {
    final existing = await customQuestions(departmentId);
    final list = existing.where((q) => q.id != question.id).toList()
      ..add(question);
    await _col.doc(departmentId).set({
      'questions': list.map(_toMap).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    _cache.remove(departmentId);
  }

  Future<void> deleteCustomQuestion(String departmentId, String id) async {
    final existing = await customQuestions(departmentId);
    await _col.doc(departmentId).set({
      'questions':
          existing.where((q) => q.id != id).map(_toMap).toList(),
    }, SetOptions(merge: true));
    _cache.remove(departmentId);
  }

  Future<void> setHidden(String departmentId, String id, bool hidden) async {
    final current = await hiddenQuestions(departmentId);
    hidden ? current.add(id) : current.remove(id);
    await _col.doc(departmentId).set(
      {'hidden': current.toList()},
      SetOptions(merge: true),
    );
    _cache.remove(departmentId);
  }

  void clearCache() => _cache.clear();

  TemplateQuestion _fromMap(Map<String, dynamic> m) => TemplateQuestion(
        id: (m['id'] ?? '').toString(),
        en: (m['en'] ?? '').toString(),
        ar: (m['ar'] ?? m['en'] ?? '').toString(),
        type: (m['type'] ?? 'text').toString(),
        options: ((m['options'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        critical: m['critical'] == true,
      );

  Map<String, dynamic> _toMap(TemplateQuestion q) => {
        'id': q.id,
        'en': q.en,
        'ar': q.ar,
        'type': q.type,
        'options': q.options,
        'critical': q.critical,
      };
}
