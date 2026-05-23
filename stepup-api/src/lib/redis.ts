import Redis from 'ioredis';

let client: Redis;

export function getRedis(): Redis {
  if (!client) {
    const url = process.env.UPSTASH_REDIS_URL;
    if (!url) throw new Error('UPSTASH_REDIS_URL is required');
    client = new Redis(url, {
      tls: { rejectUnauthorized: false },
      maxRetriesPerRequest: 3,
    });
  }
  return client;
}
