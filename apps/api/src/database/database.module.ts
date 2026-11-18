import { Global, Inject, Module, OnApplicationShutdown } from '@nestjs/common';
import { Kysely, PostgresDialect } from 'kysely';
import { Pool } from 'pg';
import { APP_CONFIG, AppConfig } from '../config/env';

// Cửa duy nhất vào PostgreSQL. P0 tuần 2 (spike Kysely + RLS) sẽ thêm `withTenant`: mở giao dịch,
// SET LOCAL app.tenant_id, chạy truy vấn; và kiểu sinh từ kysely-codegen thay cho `unknown`.
export const DB = Symbol('DB');
// eslint-disable-next-line @typescript-eslint/no-explicit-any -- chờ kiểu sinh tự động (kysely-codegen)
export type Database = Kysely<any>;

@Global()
@Module({
  providers: [
    {
      provide: DB,
      inject: [APP_CONFIG],
      useFactory: (cfg: AppConfig): Database =>
        new Kysely({
          dialect: new PostgresDialect({
            pool: new Pool({ connectionString: cfg.DATABASE_URL, max: cfg.DATABASE_POOL_MAX }),
          }),
        }),
    },
  ],
  exports: [DB],
})
export class DatabaseModule implements OnApplicationShutdown {
  constructor(@Inject(DB) private readonly db: Database) {}

  async onApplicationShutdown(): Promise<void> {
    await this.db.destroy();
  }
}
