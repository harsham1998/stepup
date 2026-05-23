import { runAnticheatChecks } from '../../src/modules/steps/anticheat.service';
import { StepSyncPayload } from '../../src/types';

const base: StepSyncPayload = {
  steps: 500,
  syncedAt: new Date().toISOString(),
  source: 'healthkit',
  deviceModel: 'iPhone 15',
  osVersion: '17.0',
};

describe('runAnticheatChecks', () => {
  it('returns null for valid payload', () => {
    expect(runAnticheatChecks(base, 15)).toBeNull();
  });

  it('flags when steps/min rate exceeds 200 (5000 steps in 15 min = 333/min)', () => {
    const result = runAnticheatChecks({ ...base, steps: 5000 }, 15);
    expect(result).toBe('rate_exceeded');
  });

  it('flags when steps exceed 10k in a single sync', () => {
    const result = runAnticheatChecks({ ...base, steps: 10001 }, 60);
    expect(result).toBe('single_sync_too_high');
  });

  it('flags manual source with steps > 100', () => {
    const result = runAnticheatChecks({ ...base, steps: 1000, source: 'manual' }, 15);
    expect(result).toBe('manual_source_high_steps');
  });

  it('does not flag manual source with steps <= 100', () => {
    const result = runAnticheatChecks({ ...base, steps: 50, source: 'manual' }, 15);
    expect(result).toBeNull();
  });
});
