import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_role.dart';

/// Holds the signed-in user's role, their selected departments and (for
/// developers) the ability to preview the app as another role.
class RoleService with ChangeNotifier {
  static const _prefsRole = 'user_role';
  static const _prefsDepts = 'user_departments';
  static const _prefsPreview = 'role_preview';
  static const _prefsInstructor = 'user_is_instructor';

  // TODO: هذا معرّف مؤقّت للتحقق فقط، يمثّل مكان استدعاء واجهة برمجة
  // الجامعة الحقيقية لاحقًا (يرسل الجامعة القيمة الفعلية لكل أستاذ).
  // عند ربط الـ API الحقيقي، يُفضَّل نقل هذا التحقق لدالة سحابية
  // (Cloud Function) تكتب isInstructor بعد التحقق من الخادم، بدل ما
  // يكتبها التطبيق مباشرة من جهة العميل كما هو الآن.
  static const _validInstructorIds = {'1234'};

  AppRole _role = AppRole.student;
  AppRole? _previewRole;
  List<String> _departments = [];
  bool _isInstructor = false;
  bool _loaded = false;

  AppRole get realRole => _role;

  /// The role the UI should behave as (developers can preview other roles).
  AppRole get role => _previewRole ?? _role;
  AppRole? get previewRole => _previewRole;
  List<String> get departments => List.unmodifiable(_departments);

  /// Only meaningful when [realRole] is [AppRole.doctor]: a doctor who is
  /// also verified as a university instructor can review students'
  /// submitted cases. Developers always have review access regardless.
  bool get isInstructor => _isInstructor;
  bool get loaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _role = AppRoleX.fromId(prefs.getString(_prefsRole));
    _departments = prefs.getStringList(_prefsDepts) ?? [];
    _isInstructor = prefs.getBool(_prefsInstructor) ?? false;
    final preview = prefs.getString(_prefsPreview);
    _previewRole = preview == null ? null : AppRoleX.fromId(preview);
    _loaded = true;
    notifyListeners();
    await refreshFromServer();
  }

  Future<void> refreshFromServer() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data();
      if (data == null) return;
      _role = AppRoleX.fromId(data['role'] as String?);
      _isInstructor = data['isInstructor'] == true;
      final depts = data['departments'];
      if (depts is List) {
        _departments = depts.map((e) => e.toString()).toList();
      }
      if (_role != AppRole.developer) _previewRole = null;
      await _persist();
      notifyListeners();
    } catch (_) {
      // offline — keep cached values
    }
  }

  /// Self-service verification: a doctor enters their university
  /// instructor ID; if it matches, they gain instructor privileges
  /// (review queue access). Returns true if verification succeeded.
  Future<bool> verifyInstructor(String universityId) async {
    if (_role != AppRole.doctor) return false;
    if (!_validInstructorIds.contains(universityId.trim())) return false;

    _isInstructor = true;
    await _persist();
    notifyListeners();
    _writeServer({'isInstructor': true});
    return true;
  }

  /// Lets a doctor step back down from instructor status if they want to.
  Future<void> revokeInstructor() async {
    _isInstructor = false;
    await _persist();
    notifyListeners();
    _writeServer({'isInstructor': false});
  }

  Future<void> setDepartments(List<String> ids) async {
    _departments = ids;
    await _persist();
    notifyListeners();
    _writeServer({'departments': ids});
  }

  Future<void> setPreviewRole(AppRole? role) async {
    if (_role != AppRole.developer) return;
    _previewRole = role;
    await _persist();
    notifyListeners();
  }

  /// Developer-only: change the role of any user by uid.
  Future<void> assignRole(String uid, AppRole role) async {
    if (_role != AppRole.developer) {
      throw StateError('Only developers can change roles');
    }
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({'role': role.id}, SetOptions(merge: true));
    if (uid == FirebaseAuth.instance.currentUser?.uid) {
      _role = role;
      await _persist();
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> listUsers({int limit = 100}) async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => {...d.data(), 'uid': d.id})
        .toList();
  }

  void _writeServer(Map<String, dynamic> data) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(data, SetOptions(merge: true))
        .catchError((_) {});
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsRole, _role.id);
    await prefs.setStringList(_prefsDepts, _departments);
    await prefs.setBool(_prefsInstructor, _isInstructor);
    if (_previewRole == null) {
      await prefs.remove(_prefsPreview);
    } else {
      await prefs.setString(_prefsPreview, _previewRole!.id);
    }
  }
}
