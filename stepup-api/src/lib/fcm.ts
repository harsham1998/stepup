import admin from 'firebase-admin';

let app: admin.app.App | null = null;

export function getFcmApp(): admin.app.App {
  if (!app) {
    const json = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
    if (!json) throw new Error('FIREBASE_SERVICE_ACCOUNT_JSON is required');
    const serviceAccount = JSON.parse(json);
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
    app = admin.app();
  }
  return app;
}

export async function sendPush(token: string, title: string, body: string): Promise<void> {
  await getFcmApp().messaging().send({ token, notification: { title, body } });
}
