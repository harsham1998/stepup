import Razorpay from 'razorpay';

let client: Razorpay;

export function getRazorpay(): Razorpay {
  if (!client) {
    const key_id = process.env.RAZORPAY_KEY_ID;
    const key_secret = process.env.RAZORPAY_KEY_SECRET;
    if (!key_id || !key_secret) throw new Error('RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET required');
    client = new Razorpay({ key_id, key_secret });
  }
  return client;
}
