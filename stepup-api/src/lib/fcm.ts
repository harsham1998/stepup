import admin from 'firebase-admin';

let initialised = false;

export function getFcmApp(): admin.app.App {
  if (!initialised) {
    const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON ?? '{}');
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
    initialised = true;
  }
  return admin.app();
}

export async function sendPush(token: string, title: string, body: string): Promise<void> {
  await getFcmApp().messaging().send({ token, notification: { title, body } });
}
