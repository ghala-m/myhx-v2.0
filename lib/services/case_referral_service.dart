import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/case_referral.dart';
import '../utils/app_logger.dart';

class CaseReferralService {
  final _col = FirebaseFirestore.instance.collection('case_referrals');

  Future<void> refer(CaseReferral referral) async {
    try {
      await _col.add(referral.toJson());
    } catch (e) {
      AppLogger.e('Error creating case referral', error: e);
      rethrow;
    }
  }

  /// Referrals this account sent out.
  Stream<List<CaseReferral>> sentBy(String doctorId) {
    return _col
        .where('fromDoctorId', isEqualTo: doctorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => CaseReferral.fromDoc(d.id, d.data())).toList());
  }

  /// Referrals waiting on this account to accept/decline.
  Stream<List<CaseReferral>> receivedBy(String doctorId) {
    return _col
        .where('toDoctorId', isEqualTo: doctorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => CaseReferral.fromDoc(d.id, d.data())).toList());
  }

  /// Just flips the status. The actual patient-data copy happens
  /// server-side in response to this change — see
  /// functions/index.js: onCaseReferralAccepted.
  Future<void> respond(String id, bool accept) async {
    try {
      await _col.doc(id).update({'status': accept ? 'accepted' : 'declined'});
    } catch (e) {
      AppLogger.e('Error responding to case referral', error: e);
      rethrow;
    }
  }
}
