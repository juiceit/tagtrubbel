import admin from 'firebase-admin';

let initialized = false;

function ensureInitialized(): void {
  if (initialized) return;

  const serviceAccount = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (serviceAccount) {
    admin.initializeApp({
      credential: admin.credential.cert(JSON.parse(serviceAccount)),
    });
  } else if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    admin.initializeApp({
      credential: admin.credential.applicationDefault(),
    });
  } else {
    console.warn(
      'Firebase not configured — push notifications will be logged but not sent.',
    );
    return;
  }
  initialized = true;
}

export async function sendPushNotification(
  fcmToken: string,
  title: string,
  body: string,
): Promise<boolean> {
  ensureInitialized();

  if (!initialized) {
    console.log(`[DRY RUN] Notification to ${fcmToken.slice(0, 10)}...: ${title} — ${body}`);
    return true;
  }

  try {
    await admin.messaging().send({
      token: fcmToken,
      notification: { title, body },
      android: { priority: 'high' },
      apns: {
        payload: { aps: { sound: 'default', badge: 1 } },
      },
    });
    return true;
  } catch (err: unknown) {
    const error = err as { code?: string };
    if (
      error.code === 'messaging/registration-token-not-registered' ||
      error.code === 'messaging/invalid-registration-token'
    ) {
      console.warn(`Invalid FCM token: ${fcmToken.slice(0, 10)}...`);
      return false;
    }
    throw err;
  }
}
