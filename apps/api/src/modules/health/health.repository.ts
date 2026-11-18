import { Inject, Injectable } from '@nestjs/common';
import { sql } from 'kysely';
import { DB, Database } from '../../database/database.module';

@Injectable()
export class HealthRepository {
  constructor(@Inject(DB) private readonly db: Database) {}

  /** Kiểm tra kết nối CSDL; không đọc bảng nghiệp vụ nên không cần ngữ cảnh tenant. */
  async ping(): Promise<boolean> {
    const { rows } = await sql<{ ok: number }>`select 1 as ok`.execute(this.db);
    return rows[0]?.ok === 1;
  }
}
