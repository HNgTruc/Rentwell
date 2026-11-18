import { Injectable } from '@nestjs/common';
import { HealthRepository } from './health.repository';

export type HealthStatus = { status: 'ok' | 'degraded'; db: 'ok' | 'down' };

@Injectable()
export class HealthService {
  constructor(private readonly repo: HealthRepository) {}

  async check(): Promise<HealthStatus> {
    const dbOk = await this.repo.ping().catch(() => false);
    return { status: dbOk ? 'ok' : 'degraded', db: dbOk ? 'ok' : 'down' };
  }
}
