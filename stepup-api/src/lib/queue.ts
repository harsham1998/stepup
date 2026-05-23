import { Queue, Worker, Job } from 'bullmq';
import { getRedis } from './redis';

export function createQueue(name: string): Queue {
  return new Queue(name, { connection: getRedis() });
}

export function createWorker(
  name: string,
  processor: (job: Job) => Promise<void>
): Worker {
  return new Worker(name, processor, { connection: getRedis(), concurrency: 4 });
}
