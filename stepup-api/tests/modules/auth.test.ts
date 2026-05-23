import request from 'supertest';
import express from 'express';
import { authRouter } from '../../src/modules/auth/auth.router';

const app = express();
app.use(express.json());
app.use('/auth', authRouter);

jest.mock('../../src/modules/auth/auth.service', () => ({
  sendOtp: jest.fn().mockResolvedValue({ success: true }),
  verifyOtp: jest.fn().mockImplementation(({ phone, otp }: { phone: string; otp: string }) => {
    if (otp === '123456') return Promise.resolve({ session: { access_token: 'tok', refresh_token: 'ref' }, user: { id: 'u1' } });
    return Promise.reject(new Error('Invalid OTP'));
  }),
  upsertProfile: jest.fn().mockResolvedValue({ id: 'u1', name: 'Harsha' }),
}));

describe('POST /auth/otp/send', () => {
  it('returns 200 for valid phone', async () => {
    const res = await request(app).post('/auth/otp/send').send({ phone: '9876543210' });
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });

  it('returns 400 for missing phone', async () => {
    const res = await request(app).post('/auth/otp/send').send({});
    expect(res.status).toBe(400);
  });

  it('returns 400 for invalid phone (not 10 digits)', async () => {
    const res = await request(app).post('/auth/otp/send').send({ phone: '12345' });
    expect(res.status).toBe(400);
  });
});

describe('POST /auth/otp/verify', () => {
  it('returns session on valid OTP', async () => {
    const res = await request(app).post('/auth/otp/verify').send({ phone: '9876543210', otp: '123456' });
    expect(res.status).toBe(200);
    expect(res.body.session.access_token).toBe('tok');
  });

  it('returns 401 on invalid OTP', async () => {
    const res = await request(app).post('/auth/otp/verify').send({ phone: '9876543210', otp: '999999' });
    expect(res.status).toBe(401);
  });
});

describe('PUT /auth/profile', () => {
  it('returns updated profile', async () => {
    const app2 = express();
    app2.use(express.json());
    app2.use((req, _res, next) => { req.user = { id: 'u1' }; next(); });
    app2.use('/auth', authRouter);
    const res = await request(app2)
      .put('/auth/profile')
      .send({ name: 'Harsha', city: 'Hyderabad', language: 'telugu', goal_tier: 'active' });
    expect(res.status).toBe(200);
    expect(res.body.id).toBe('u1');
  });

  it('returns 400 for invalid language', async () => {
    const app2 = express();
    app2.use(express.json());
    app2.use((req, _res, next) => { req.user = { id: 'u1' }; next(); });
    app2.use('/auth', authRouter);
    const res = await request(app2)
      .put('/auth/profile')
      .send({ name: 'Harsha', city: 'Hyderabad', language: 'french', goal_tier: 'active' });
    expect(res.status).toBe(400);
  });
});
