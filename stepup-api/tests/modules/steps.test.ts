import request from 'supertest';
import express from 'express';
import { stepsRouter } from '../../src/modules/steps/steps.router';

const app = express();
app.use(express.json());
app.use((req, _res, next) => { req.user = { id: 'user-123' }; next(); });
app.use('/steps', stepsRouter);

jest.mock('../../src/modules/steps/steps.service', () => ({
  syncSteps: jest.fn().mockResolvedValue({ accepted: true, steps: 500 }),
}));

describe('POST /steps/sync', () => {
  const validPayload = {
    steps: 500,
    syncedAt: new Date().toISOString(),
    source: 'healthkit',
    deviceModel: 'iPhone 15',
    osVersion: '17.0',
  };

  it('accepts valid step payload', async () => {
    const res = await request(app).post('/steps/sync').send(validPayload);
    expect(res.status).toBe(200);
    expect(res.body.accepted).toBe(true);
  });

  it('rejects payload missing required fields', async () => {
    const res = await request(app).post('/steps/sync').send({ steps: 500 });
    expect(res.status).toBe(400);
  });

  it('rejects invalid source value', async () => {
    const res = await request(app).post('/steps/sync').send({ ...validPayload, source: 'garmin' });
    expect(res.status).toBe(400);
  });

  it('rejects negative steps', async () => {
    const res = await request(app).post('/steps/sync').send({ ...validPayload, steps: -1 });
    expect(res.status).toBe(400);
  });
});
