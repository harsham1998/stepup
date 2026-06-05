import { Queue, Worker, Job } from 'bullmq';
import { getRedis } from './redis';

export function createQueue(name: string): Queue {
  const q = new Queue(name, { connection: getRedis() });
  q.on('error', () => { /* suppress queue connection errors */ });
  return q;
}

export function createWorker(
  name: string,
  processor: (job: Job) => Promise<void>
): Worker {
  const w = new Worker(name, processor, { connection: getRedis(), concurrency: 4 });
  w.on('error', () => { /* suppress worker connection errors */ });
  return w;
}
