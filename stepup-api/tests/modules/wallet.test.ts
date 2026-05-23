import request from 'supertest';
import express from 'express';
import { walletRouter } from '../../src/modules/wallet/wallet.router';

const app = express();
app.use(express.json());
app.use((req, _res, next) => { (req as any).user = { id: 'user-123' }; next(); });
app.use('/wallet', walletRouter);

jest.mock('../../src/lib/redis', () => ({
  getRedis: () => ({
    set: jest.fn().mockResolvedValue('OK'),
    del: jest.fn().mockResolvedValue(1),
  }),
}));

jest.mock('../../src/modules/wallet/wallet.service', () => ({
  getBalance: jest.fn().mockResolvedValue({ balance_paise: 184000, balance_inr: '1840.00' }),
  getTransactions: jest.fn().mockResolvedValue([
    { id: 't1', type: 'credit', amount: 24000, description: 'Challenge Won' },
  ]),
  createDepositOrder: jest.fn().mockResolvedValue({ order_id: 'ord_xxx', amount: 5000, currency: 'INR' }),
  requestWithdrawal: jest.fn().mockResolvedValue({ success: true, reference: 'pay_xxx' }),
}));

describe('GET /wallet/balance', () => {
  it('returns balance in paise and INR', async () => {
    const res = await request(app).get('/wallet/balance');
    expect(res.status).toBe(200);
    expect(res.body.balance_inr).toBe('1840.00');
  });
});

describe('POST /wallet/deposit/order', () => {
  it('creates Razorpay order', async () => {
    const res = await request(app).post('/wallet/deposit/order').send({ amount_inr: 50 });
    expect(res.status).toBe(200);
    expect(res.body.order_id).toBe('ord_xxx');
  });

  it('rejects deposit below minimum', async () => {
    const res = await request(app).post('/wallet/deposit/order').send({ amount_inr: 5 });
    expect(res.status).toBe(400);
  });
});

describe('POST /wallet/withdraw', () => {
  it('initiates UPI withdrawal', async () => {
    const res = await request(app).post('/wallet/withdraw').send({ amount_inr: 100, upi_vpa: 'harsha@upi' });
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });
});
