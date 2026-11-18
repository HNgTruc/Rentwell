import { describe, expect, it } from 'vitest';
import { HealthRepository } from './health.repository';
import { HealthService } from './health.service';

const repoReturning = (ping: () => Promise<boolean>) => ({ ping }) as unknown as HealthRepository;

describe('HealthService', () => {
  it('báo ok khi CSDL phản hồi', async () => {
    const svc = new HealthService(repoReturning(async () => true));
    expect(await svc.check()).toEqual({ status: 'ok', db: 'ok' });
  });

  it('báo degraded khi CSDL lỗi, không ném lỗi ra ngoài', async () => {
    const svc = new HealthService(
      repoReturning(async () => {
        throw new Error('ECONNREFUSED');
      }),
    );
    expect(await svc.check()).toEqual({ status: 'degraded', db: 'down' });
  });
});
