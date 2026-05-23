import { StepSyncPayload } from '../../types';

type FlagReason = 'rate_exceeded' | 'single_sync_too_high' | 'manual_source_high_steps' | null;

const MAX_STEPS_PER_MIN = 200;
const MAX_SINGLE_SYNC_STEPS = 10000;
const MAX_MANUAL_STEPS = 100;

export function runAnticheatChecks(payload: StepSyncPayload, intervalMinutes: number): FlagReason {
  const stepsPerMin = payload.steps / intervalMinutes;
  if (stepsPerMin > MAX_STEPS_PER_MIN) return 'rate_exceeded';
  if (payload.steps > MAX_SINGLE_SYNC_STEPS) return 'single_sync_too_high';
  if (payload.source === 'manual' && payload.steps > MAX_MANUAL_STEPS) return 'manual_source_high_steps';
  return null;
}
