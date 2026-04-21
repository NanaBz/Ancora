import * as admin from "firebase-admin";
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {setGlobalOptions} from "firebase-functions/v2";

admin.initializeApp();
setGlobalOptions({maxInstances: 10});

export const onDoseLogCreate = onDocumentCreated(
  "users/{patientUid}/doseLogs/{logId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data();
    const isMissed = data.status === "missed";
    const isEarlyTake = data.status === "taken" && data.earlyTake === true;
    if (!isMissed && !isEarlyTake) return;

    const patientUid = event.params.patientUid;
    const db = admin.firestore();

    const [patientDoc, medDoc] = await Promise.all([
      db.collection("users").doc(patientUid).get(),
      db
        .collection("users")
        .doc(patientUid)
        .collection("medications")
        .doc(data.medId as string)
        .get(),
    ]);

    const patientName =
      (patientDoc.data()?.fullName as string | undefined) ?? "Your patient";
    const medName =
      (medDoc.data()?.name as string | undefined) ?? "medication";

    const caregiversSnap = await db
      .collection("users")
      .doc(patientUid)
      .collection("caregivers")
      .get();

    if (caregiversSnap.empty) return;

    const tokens: string[] = [];
    const tokenDocPaths: string[] = [];

    await Promise.all(
      caregiversSnap.docs.map(async (cgDoc) => {
        const caregiverUid = cgDoc.id;
        const tokensSnap = await db
          .collection("users")
          .doc(caregiverUid)
          .collection("fcmTokens")
          .get();
        for (const t of tokensSnap.docs) {
          tokens.push(t.id);
          tokenDocPaths.push(
            `users/${caregiverUid}/fcmTokens/${t.id}`
          );
        }
      })
    );

    if (tokens.length === 0) return;

    const scheduledAt = (
      data.scheduledAt as admin.firestore.Timestamp
    ).toDate();
    const timeStr = `${scheduledAt
      .getHours()
      .toString()
      .padStart(2, "0")}:${scheduledAt
      .getMinutes()
      .toString()
      .padStart(2, "0")}`;

    const notification = isMissed ?
      {
        title: "Missed dose",
        body: `${patientName} missed ${medName} at ${timeStr}`,
      } :
      {
        title: "Early dose taken",
        body: `${patientName} took ${medName} early (scheduled ${timeStr})`,
      };

    const response = await admin.messaging().sendEachForMulticast({
      tokens,
      notification,
      android: {priority: "high"},
    });

    const batch = db.batch();
    response.responses.forEach((resp, i) => {
      if (
        !resp.success &&
        (resp.error?.code ===
          "messaging/registration-token-not-registered" ||
          resp.error?.code ===
            "messaging/invalid-registration-token")
      ) {
        batch.delete(db.doc(tokenDocPaths[i]));
      }
    });
    await batch.commit();
  }
);
