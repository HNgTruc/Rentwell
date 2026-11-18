import { Global, Inject, Module, OnApplicationShutdown } from '@nestjs/common';
import { Kysely, PostgresDialect } from 'kysely';
import { Pool } from 'pg';
import { APP_CONFIG, AppConfig } from '../config/env';

// Cửa duy nhất vào PostgreSQL. Truy vấn nghiệp vụ đi qua `withTenant` (tenant-context.ts, ADR 0012).
// Còn chờ: kiểu sinh từ kysely-codegen thay cho `any`.
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
