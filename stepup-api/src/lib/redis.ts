import Redis from 'ioredis';

let client: Redis | null = null;

export function getRedis(): Redis {
  if (!client) {
    const url = process.env.UPSTASH_REDIS_URL;
    if (!url || url.includes('your-upstash')) throw new Error('Redis not configured');
    client = new Redis(url, {
      tls: { rejectUnauthorized: false },
      maxRetriesPerRequest: null,
      enableOfflineQueue: false,
      lazyConnect: true,
    });
    client.on('error', () => { /* swallow ioredis connection errors */ });
  }
  return client;
}
