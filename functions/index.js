/**
 * myhx- push notification Cloud Functions.
 *
 * Two triggers, matching the two features built on the Flutter side that
 * need a real push (not just an in-app banner that only works while the
 * app happens to be open):
 *
 *   1. onPatientFlaggedUrgent — patients/{patientId} updated so that
 *      isUrgent goes from false/absent to true (whether set manually by
 *      a doctor or automatically by ClinicalAIService after a report).
 *      Notifies the owning doctor.
 *
 *   2. onMentorReviewCreated — a doctor/developer leaves feedback on a
 *      student's submitted case (review_requests/{id}/reviews/{id}
 *      created). Notifies the student who submitted it.
 *
 * Both read the target user's FCM tokens from users/{uid}.fcmTokens
 * (an array — see lib/services/push_notification_service.dart on the
 * Flutter side, which keeps this field up to date) and clean up any
 * tokens FCM reports as dead so this list doesn't grow unbounded with
 * uninstalled-app tokens over time.
 */

const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { onDocumentUpdated, onDocumentCreated } =
  require("firebase-functions/v2/firestore");
const { logger } = require("firebase-functions");

initializeApp();
const db = getFirestore();

/**
 * Sends `notification` to every token on users/{uid}.fcmTokens, and
 * removes any token FCM reports as invalid/unregistered.
 */
async function sendToUser(uid, notification, data = {}) {
  const userDoc = await db.collection("users").doc(uid).get();
  const tokens = userDoc.data()?.fcmTokens;
  if (!Array.isArray(tokens) || tokens.length === 0) {
    logger.info(`No FCM tokens for user ${uid}, skipping push.`);
    return;
  }

  const response = await getMessaging().sendEachForMulticast({
    tokens,
    notification,
    data,
  });

  const deadTokens = [];
  response.responses.forEach((r, i) => {
    if (!r.success) {
      const code = r.error?.code;
      if (
        code === "messaging/invalid-registration-token" ||
        code === "messaging/registration-token-not-registered"
      ) {
        deadTokens.push(tokens[i]);
      } else {
        logger.warn(`FCM send failed for ${uid}:`, r.error);
      }
    }
  });

  if (deadTokens.length > 0) {
    await db
      .collection("users")
      .doc(uid)
      .update({ fcmTokens: FieldValue.arrayRemove(...deadTokens) });
    logger.info(`Removed ${deadTokens.length} dead token(s) for ${uid}.`);
  }
}

exports.onPatientFlaggedUrgent = onDocumentUpdated(
  "patients/{patientId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    const becameUrgent = !before?.isUrgent && after?.isUrgent === true;
    if (!becameUrgent) return;

    const doctorId = after.doctorId;
    if (!doctorId) return;

    const source = after.urgentSource === "system" ? "auto-flagged" : "marked";
    await sendToUser(
      doctorId,
      {
        title: "Urgent case",
        body: `${after.name || "A patient"} was ${source} as urgent.`,
      },
      {
        type: "urgent_patient",
        patientId: event.params.patientId,
      },
    );
  },
);

exports.onMentorReviewCreated = onDocumentCreated(
  "review_requests/{requestId}/reviews/{reviewId}",
  async (event) => {
    const review = event.data.data();
    const requestSnap = await db
      .collection("review_requests")
      .doc(event.params.requestId)
      .get();
    const request = requestSnap.data();
    if (!request?.studentId) return;

    await sendToUser(
      request.studentId,
      {
        title: "New feedback on your case",
        body: `${review.reviewerName || "A mentor"} reviewed ${
          request.patientName || "your case"
        }.`,
      },
      {
        type: "mentor_review",
        requestId: event.params.requestId,
      },
    );
  },
);
